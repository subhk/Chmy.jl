module KernelLaunch

export Launcher, Offset
export worksize, outer_width, inner_worksize, inner_offset, outer_worksize, outer_offset

using Chmy
using Chmy.Architectures
using Chmy.Grids
using Chmy.BoundaryConditions
using Chmy.Workers

using KernelAbstractions

struct Offset{O} end

Offset(o::Vararg{Integer}) = Offset{o}()
Offset() = Offset{0}()

Base.:+(::Offset{O1}, ::Offset{O2}) where {O1,O2} = Offset((O1 .+ O2)...)
Base.:+(::Offset{O}, tp::Tuple{Vararg{Integer}}) where {O} = O .+ tp
Base.:+(tp::Tuple{Vararg{Integer}}, off::Offset) = off + tp

struct Launcher{Worksize,OuterWidth,Workers}
    workers::Workers
end

# worksize for the last dimension N takes into account only last outer width W[N], N-1 uses W[N] and W[N-1], N-2 uses W[N], W[N-1], and W[N-2]

function Launcher(arch, grid; outer_width=nothing)
    worksize = size(grid, Center()) .+ 2

    if !isnothing(outer_width)
        setup() = activate!(arch; priority=:high)
        workers = ntuple(Val(ndims(grid))) do _
            Base.@_inline_meta
            ntuple(_ -> Worker(; setup), Val(2))
        end
    else
        workers = nothing
    end

    return Launcher{worksize,outer_width,typeof(workers)}(workers)
end

Base.@assume_effects :foldable Base.ndims(::Launcher{WorkSize}) where {WorkSize} = length(WorkSize)
Base.@assume_effects :foldable worksize(::Launcher{WorkSize}) where {WorkSize} = WorkSize
Base.@assume_effects :foldable outer_width(::Launcher{WorkSize,OuterWidth}) where {WorkSize,OuterWidth} = OuterWidth

Base.@assume_effects :foldable inner_worksize(launcher::Launcher) = worksize(launcher) .- 2 .* outer_width(launcher)
Base.@assume_effects :foldable inner_offset(launcher::Launcher) = outer_width(launcher)

Base.@assume_effects :foldable function outer_worksize(launcher::Launcher, ::Dim{D}) where {D}
    ntuple(Val(ndims(launcher))) do I
        Base.@_inline_meta
        if I < D
            worksize(launcher)[I]
        elseif I == D
            outer_width(launcher)[I]
        else
            worksize(launcher)[I] - 2outer_width(launcher)[I]
        end
    end
end

Base.@assume_effects :foldable function outer_offset(launcher::Launcher, ::Dim{D}, ::Side{S}) where {D,S}
    ntuple(Val(ndims(launcher))) do I
        Base.@_inline_meta
        if I < D
            0
        elseif I == D
            S == 1 ? 0 : worksize(launcher)[I] - outer_width(launcher)[I]
        else
            outer_width(launcher)[I]
        end
    end
end

function (launcher::Launcher)(arch::Architecture, grid, kernel::F, args...; bc=nothing, async=false) where {F}
    backend = Architectures.get_backend(arch)
    offset  = Offset(-1)

    if isnothing(bc)
        launch_without_bc(backend, launcher, offset, kernel, args...)
    else
        launch_with_bc(arch, grid, launcher, offset, kernel, bc, args...)
    end

    async || KernelAbstractions.synchronize(backend)
    return
end

@inline function launch_without_bc(backend, launcher, offset, kernel, args...)
    groupsize = heuristic_groupsize(backend, Val(ndims(launcher)))
    fun = kernel(backend, groupsize, worksize(launcher))
    fun(args..., offset)
    return
end

@inline function launch_with_bc(arch, grid, launcher, offset, kernel, bc, args...)
    backend   = Architectures.get_backend(arch)
    groupsize = heuristic_groupsize(backend, Val(ndims(launcher)))
    inner_fun = kernel(backend, groupsize, inner_worksize(launcher))
    inner_fun(args..., offset + Offset(inner_offset(launcher)...))

    if isnothing(outer_width(launcher))
        bc!(arch, grid, bc)
    else
        N = ndims(grid)
        ntuple(Val(N)) do J
            Base.@_inline_meta
            D = N - J + 1
            outer_fun = kernel(backend, groupsize, outer_worksize(launcher, Dim(D)))
            ntuple(Val(2)) do S
                put!(launcher.workers[D][S]) do
                    outer_fun(args..., offset + Offset(outer_offset(launcher, Dim(D), Side(S))...))
                    bc!(Side(S), Dim(D), arch, grid, bc[D][S])
                end
            end
            wait(launcher.workers[D][1])
            wait(launcher.workers[D][2])
        end
    end
end

end
