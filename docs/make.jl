using Documenter
using Chmy

push!(LOAD_PATH,"../src/")

makedocs(
    sitename = "Chmy.jl",
    authors="Ivan Utkin, Ludovic Räss and contributors",
    format = Documenter.HTML(
        prettyurls=get(ENV, "CI", nothing) == "true", # easier local build
        ansicolor=true,
        assets = ["assets/favicon.ico"],
        ),
    modules = [Chmy],
    warnonly = [:missing_docs],
    pages = Any[
        "Home" => "index.md",
        "Getting Started with Chmy.jl" => "getting_started.md",
        "Using Chmy.jl with MPI" => "using_chmy_with_mpi.md",
        "Concepts" => Any["concepts/architectures.md",
                        "concepts/grids.md",
                        "concepts/fields.md",
                        "concepts/bc.md",
                        "concepts/grid_operators.md",
                        "concepts/kernels.md",
                        "concepts/distributed.md"
        ],
        "Examples" => Any["examples/overview.md"
        ],
        "Library" => Any["lib/modules.md"],
        "Developer documentation" => Any["developer_documentation/running_tests.md",
                                         "developer_documentation/workers.md"],
    ]
)

deploydocs(
    repo = "github.com/PTsolvers/Chmy.jl.git",
    devbranch = "main",
    push_preview = true
)
