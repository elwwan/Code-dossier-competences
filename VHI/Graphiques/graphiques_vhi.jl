using CSV, DataFrames, CairoMakie, ColorSchemes

# VHI Aout MDL 1984-2024.
begin
    df = DataFrame(CSV.File("data/data_mdl.csv"))
    m = reshape(df[:, :shares], 9, :)
    data = cumsum( vcat( fill(0, (1, 41)) , m[:, 8:12:end] ), dims=1)
    classes = [
        "< 0.15",
        "0.15 - 0.25",
        "0.25 - 0.35",
        "0.35 - 0.45",
        "0.45 - 0.55",
        "0.55 - 0.65",
        "0.65 - 0.75",
        "0.75 - 0.85",
        ">= 0.85"
    ]
    f = Figure(size=(2000/2, 500/1.5), 
        fonts = (; regular = "Courier New"),
        fontsize = 14
    )
    ax = Axis(f[1,1], 
        limits =(1, 41, 0, 1),


        xlabel = "Années",
        xticks = (1:10:41, ["$i" for i in 1984:10:2024]),
        xminorticks = 1:1:41,
        xminorticksvisible = true,
        xminorgridvisible = true,
        xtickalign = 1, 
        xminortickalign = 1,
        xticksmirrored = true,
        xticklabelpad = 10,

        ylabel = "Part (%)",
        yticks = (0:0.2:1, ["$i" for i in 0:20:100]),
        yminorticks = 0:0.05:1,
        yminorticksvisible = true,
        yminorgridvisible = true,
        ytickalign = 1, 
        yminortickalign = 1,
        yticksmirrored = true,
    )

    bands = []
    for i in 2:size(data)[1]
        b = band!(1:41, data[i-1, :], data[i, :], color = (ColorSchemes.RdYlGn_9.colors[i-1], 0.7), label = classes[i-1])
        push!(bands, b)
    end

    
    Legend(f[1, 2], bands, classes, "Valeur du VHI", orientation = :vertical, framevisible = :false)
    f
end

# VHI de la commune de Givors en 2024.
begin
    df = DataFrame(CSV.File("data/data_by_municipality.csv"))
    df = sort(df, [:name, :year, :month,:categorie])
    df = df[df.name .== "Givors", :]
    m = reshape(df[:, :shares], 9, :)
    data = cumsum( vcat( fill(0, (1, 12)) , m[:, 1+(12*5):12*6] ), dims=1)
    classes = [
        "< 0.15",
        "0.15 - 0.25",
        "0.25 - 0.35",
        "0.35 - 0.45",
        "0.45 - 0.55",
        "0.55 - 0.65",
        "0.65 - 0.75",
        "0.75 - 0.85",
        ">= 0.85"
    ]
    f = Figure(size=(2000/2, 500/1.5), 
        fonts = (; regular = "Courier New"),
        fontsize = 14
    )
    ax = Axis(f[1,1], 
        limits =(1, 12, 0, 1),


        xlabel = "Mois",
        xticks = (1:12, ["$i" for i in 1:12]),
        xtickalign = 1, 
        xticksmirrored = true,
        xticklabelpad = 10,

        ylabel = "Part (%)",
        yticks = (0:0.2:1, ["$i" for i in 0:20:100]),
        yminorticks = 0:0.05:1,
        yminorticksvisible = true,
        yminorgridvisible = true,
        ytickalign = 1, 
        yminortickalign = 1,
        yticksmirrored = true,
    )

    bands = []
    for i in 2:size(data)[1]
        b = band!(1:12, data[i-1, :], data[i, :], color = (ColorSchemes.RdYlGn_9.colors[i-1], 0.7), label = classes[i-1])
        push!(bands, b)
    end
    Legend(f[1, 2], bands, classes, "Valeur du VHI", orientation = :vertical, framevisible = :false)
    f
end
