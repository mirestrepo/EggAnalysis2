using Documenter, EggAnalysis2

makedocs()

deploydocs(
    repo = "https://github.com/mirestrepo/EggAnalysis2.git",
    julia  = "0.6",
    osname = "linux"
)