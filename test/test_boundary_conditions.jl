include("common.jl")

for backend in TEST_BACKENDS, T in TEST_TYPES
    if !compatible(backend, T)
        continue
    end

    @testset "$(basename(@__FILE__)) (backend: $backend, type: $T)" begin
        arch = Arch(backend)

        @testset "1D Cartesian Center()" begin
            nx = 8
            grid = UniformGrid(arch; origin=(T(-π),), extent=(T(2π),), dims=(nx,))
            field = Field(arch, grid, Center())

            @testset "default Dirichlet" begin
                set!(field, 1)
                bc!(arch, grid, field => Dirichlet())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1] .≈ .-field_i[2])
                @test all(field_i[end] .≈ .-field_i[end-1])
            end

            @testset "default Neumann" begin
                set!(field, 1)
                bc!(arch, grid, field => Neumann())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1] .≈ field_i[2])
                @test all(field_i[end] .≈ field_i[end-1])
            end

            @testset "non-homogeneous Dirichlet" begin
                set!(field, 1)
                v = T(2.0)
                bc!(arch, grid, field => Dirichlet(v))
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1] .≈ .-field_i[2] .+ 2v)
                @test all(field_i[end] .≈ .-field_i[end-1] .+ 2v)
            end

            @testset "non-homogeneous Neumann" begin
                set!(field, 1)
                q = T(2.0)
                bc!(arch, grid, field => Neumann(q))
                field_i = interior(field; with_halo=true) |> Array
                @test all((field_i[2] .- field_i[1]) ./ Δx(grid, Vertex(), 1) .≈ q)
                @test all((field_i[end] .- field_i[end-1]) ./ Δx(grid, Vertex(), nx + 1) .≈ q)
            end
        end

        @testset "1D Cartesian Vertex()" begin
            nx = 8
            grid = UniformGrid(arch; origin=(T(-π),), extent=(T(2π),), dims=(nx,))
            field = Field(arch, grid, Vertex())

            @testset "default Dirichlet" begin
                set!(field, 1)
                bc!(arch, grid, field => Dirichlet())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[2] .≈ 0.0)
                @test all(field_i[end-1] .≈ 0.0)
            end

            @testset "default Neumann" begin
                set!(field, 1)
                bc!(arch, grid, field => Neumann())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1] .≈ field_i[2])
                @test all(field_i[end] .≈ field_i[end-1])
            end

            @testset "non-homogeneous Dirichlet" begin
                set!(field, 1)
                v = T(2.0)
                bc!(arch, grid, field => Dirichlet(v))
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[2] .≈ v)
                @test all(field_i[end-1] .≈ v)
            end

            @testset "non-homogeneous Neumann" begin
                set!(field, 1)
                q = T(2.0)
                bc!(arch, grid, field => Neumann(q))
                field_i = interior(field; with_halo=true) |> Array
                @test all((field_i[2] .- field_i[1]) ./ Δx(grid, Center(), 0) .≈ q)
                @test all((field_i[end] .- field_i[end-1]) ./ Δx(grid, Center(), nx + 1) .≈ q)
            end
        end

        @testset "2D Cartesian" begin
            nx, ny = 8, 8
            grid = UniformGrid(arch; origin=(T(-π), T(-π)), extent=(T(2π), T(2π)), dims=(nx, ny))
            field = Field(arch, grid, (Center(), Vertex()))

            @testset "default Dirichlet" begin
                set!(field, 1)
                bc!(arch, grid, field => Dirichlet())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1, 2:end-1] .≈ .-field_i[2, 2:end-1])
                @test all(field_i[end, 2:end-1] .≈ .-field_i[end-1, 2:end-1])

                @test all(field_i[2:end-1, 2] .≈ 0.0)
                @test all(field_i[2:end-1, end-1] .≈ 0.0)
            end

            @testset "default Neumann" begin
                set!(field, 1)
                bc!(arch, grid, field => Neumann())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1, 2:end-1] .≈ field_i[2, 2:end-1])
                @test all(field_i[end, 2:end-1] .≈ field_i[end-1, 2:end-1])

                @test all(field_i[2:end-1, 1] .≈ field_i[2:end-1, 2])
                @test all(field_i[2:end-1, end] .≈ field_i[2:end-1, end-1])
            end

            @testset "non-homogeneous Dirichlet" begin
                set!(field, 1)
                v = T(2.0)
                bc!(arch, grid, field => Dirichlet(v))
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1, 2:end-1] .≈ .-field_i[2, 2:end-1] .+ 2v)
                @test all(field_i[end, 2:end-1] .≈ .-field_i[end-1, 2:end-1] .+ 2v)

                @test all(field_i[2:end-1, 2] .≈ v)
                @test all(field_i[2:end-1, end-1] .≈ v)
            end

            @testset "non-homogeneous Neumann" begin
                set!(field, 1)
                q = T(2.0)
                bc!(arch, grid, field => Neumann(q))
                field_i = interior(field; with_halo=true) |> Array
                @test all((field_i[2, 2:end-1] .- field_i[1, 2:end-1]) ./ Δx(grid, Vertex(), 1, 1) .≈ q)
                @test all((field_i[end, 2:end-1] .- field_i[end-1, 2:end-1]) ./ Δx(grid, Vertex(), nx + 1, 1) .≈ q)

                @test all((field_i[2:end-1, 2] .- field_i[2:end-1, 1]) ./ Δy(grid, Center(), 1, 0) .≈ q)
                @test all((field_i[2:end-1, end] .- field_i[2:end-1, end-1]) ./ Δy(grid, Center(), 1, ny + 1) .≈ q)
            end
        end

        @testset "3D Cartesian" begin
            nx, ny, nz = 8, 8, 6
            grid = UniformGrid(arch; origin=(T(-π), T(-π), T(-π)), extent=(T(2π), T(2π), T(2π)), dims=(nx, ny, nz))
            field = Field(arch, grid, (Center(), Vertex(), Center()))

            @testset "default Dirichlet" begin
                set!(field, 1)
                bc!(arch, grid, field => Dirichlet())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1, 2:end-1, 2:end-1] .≈ .-field_i[2, 2:end-1, 2:end-1])
                @test all(field_i[end, 2:end-1, 2:end-1] .≈ .-field_i[end-1, 2:end-1, 2:end-1])

                @test all(field_i[2:end-1, 2, 2:end-1] .≈ 0.0)
                @test all(field_i[2:end-1, end-1, 2:end-1] .≈ 0.0)

                @test all(field_i[2:end-1, 2:end-1, 1] .≈ .-field_i[2:end-1, 2:end-1, 2])
                @test all(field_i[2:end-1, 2:end-1, end] .≈ .-field_i[2:end-1, 2:end-1, end-1])
            end

            @testset "default Neumann" begin
                set!(field, 1)
                bc!(arch, grid, field => Neumann())
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1, 2:end-1, 2:end-1] .≈ field_i[2, 2:end-1, 2:end-1])
                @test all(field_i[end, 2:end-1, 2:end-1] .≈ field_i[end-1, 2:end-1, 2:end-1])

                @test all(field_i[2:end-1, 1, 2:end-1] .≈ field_i[2:end-1, 2, 2:end-1])
                @test all(field_i[2:end-1, end, 2:end-1] .≈ field_i[2:end-1, end-1, 2:end-1])

                @test all(field_i[2:end-1, 2:end-1, 1] .≈ field_i[2:end-1, 2:end-1, 2])
                @test all(field_i[2:end-1, 2:end-1, end] .≈ field_i[2:end-1, 2:end-1, end-1])
            end

            @testset "non-homogeneous Dirichlet" begin
                set!(field, 1)
                v = T(2.0)
                bc!(arch, grid, field => Dirichlet(v))
                field_i = interior(field; with_halo=true) |> Array
                @test all(field_i[1, 2:end-1, 2:end-1] .≈ .-field_i[2, 2:end-1, 2:end-1] .+ 2v)
                @test all(field_i[end, 2:end-1, 2:end-1] .≈ .-field_i[end-1, 2:end-1, 2:end-1] .+ 2v)

                @test all(field_i[2:end-1, 2, 2:end-1] .≈ v)
                @test all(field_i[2:end-1, end-1, 2:end-1] .≈ v)

                @test all(field_i[2:end-1, 2:end-1, 1] .≈ .-field_i[2:end-1, 2:end-1, 2] .+ 2v)
                @test all(field_i[2:end-1, 2:end-1, end] .≈ .-field_i[2:end-1, 2:end-1, end-1] .+ 2v)
            end

            @testset "non-homogeneous Neumann" begin
                set!(field, 1)
                q = T(2.0)
                bc!(arch, grid, field => Neumann(q))
                field_i = interior(field; with_halo=true) |> Array
                @test all((field_i[2, 2:end-1, 2:end-1] .- field_i[1, 2:end-1, 2:end-1]) ./ Δx(grid, Vertex(), 1, 1, 1) .≈ q)
                @test all((field_i[end, 2:end-1, 2:end-1] .- field_i[end-1, 2:end-1, 2:end-1]) ./ Δx(grid, Vertex(), nx + 1, 1, 1) .≈ q)

                @test all((field_i[2:end-1, 2, 2:end-1] .- field_i[2:end-1, 1, 2:end-1]) ./ Δy(grid, Center(), 1, 0, 1) .≈ q)
                @test all((field_i[2:end-1, end, 2:end-1] .- field_i[2:end-1, end-1, 2:end-1]) ./ Δy(grid, Center(), 1, ny + 1, 1) .≈ q)

                @test all((field_i[2:end-1, 2:end-1, 2] .- field_i[2:end-1, 2:end-1, 1]) ./ Δz(grid, Vertex(), 1, 1, 1) .≈ q)
                @test all((field_i[2:end-1, 2:end-1, end] .- field_i[2:end-1, 2:end-1, end-1]) ./ Δz(grid, Vertex(), 1, 1, nz + 1) .≈ q)
            end
        end
    end
end
