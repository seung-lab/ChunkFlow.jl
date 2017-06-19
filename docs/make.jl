using Documenter, ChunkFlow

makedocs(
    modules = [ChunkFlow],
#    format  = Documenter.Formats.HTML,
#    sitename= "ChunkFlow.jl",
    doctest = false
)

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-material"),
    repo   = "github.com/seung-lab/ChunkFlow.jl.git",
    target = "build",
    branch = "gh-pages",
    julia  = "0.5",
    osname = "linux"
)
