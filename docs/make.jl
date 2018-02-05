using Documenter, EggAnalysis2

makedocs()

deploydocs(
    deps   = Deps.pip("mkdocs", "python-markdown-math", "mkdocs-material"),    
    repo = "https://github.com/mirestrepo/EggAnalysis2.git",
    julia  = "0.6",
    osname = "linux"
)