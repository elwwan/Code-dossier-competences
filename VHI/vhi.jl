using ArchGDAL, CairoMakie, CSV, DataFrames, HTTP, FileIO, Statistics, BenchmarkTools, ProgressMeter

function vhi_url(year, month, bounding_box)
    x_min, x_max, y_min, y_max = bounding_box
    base = "https://io.apps.fao.org/geoserver/wms/ASIS/VHI_M/v1?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&"
    bounding_box = "BBOX=$y_min%2C$x_min%2C$y_max%2C$x_max&"
    crs = "CRS=EPSG%3A4326&" # EPSG:4326
    width = "WIDTH=1051&" # WIDTH=1051&HEIGHT=845&
    height = "HEIGHT=845&"
    layer = "LAYERS=VHI_M_$year-$month%3AASIS%3Aasis_vhi_m&"
    format_str = "STYLES=&FORMAT=image%2Fgeotiff&DPI=120&"
    resolution_dpi = "MAP_RESOLUTION=120&FORMAT_OPTIONS=dpi%3A120&TRANSPARENT=TRUE"
    return base * bounding_box * crs * width * height * layer * format_str * resolution_dpi
end
function get_bounding_box(x::String)
    ds = ArchGDAL.read(x)
    layer = ArchGDAL.getlayer(ds, 0)
    bbox = ArchGDAL.envelope(layer)
    ArchGDAL.destroy(ds)
    [bbox.MinX, bbox.MaxX, bbox.MinY, bbox.MaxY]
end
function download_images(years, months, path, bounding_box_gpkg)
    rm(path; force=true, recursive=true)
    mkpath(path)
    tasks = collect(Iterators.product(years, months))
    @showprogress dt = 1 desc = "Downloading Images..." for (j, i) in tasks
        i = lpad(i, 2, '0')
        url = vhi_url(j, i, get_bounding_box(bounding_box_gpkg))
        resp = HTTP.get(url)
        if resp.status == 200
            open("Data/GeoTiff_MDL/$j-$i.tiff", "w") do f
                write(f, resp.body)
            end
        else
            println(resp.status)
        end
    end
end
function calc_share(v)
    total = sum(v)
    return v / total
end
function clip_raster_with_fid(years, months, path, dest, clipping_vector, fids; resolution=(0.00001, 0.00001))
    rm(dest; force=true, recursive=true)
    mkpath(dest)
    for year in years, month in months
        month_srt = lpad(month, 2, '0')
        ArchGDAL.read("$path/$year-$month_srt.tiff") do raster_ds
            for fid in fids
                warp_options = [
                    "-of", "GTiff",
                    "-crop_to_cutline",
                    "-dstnodata", "252",
                    "-srcnodata", "252",
                    "-cl", "mdl",
                    "-cutline", "$clipping_vector",
                    "-cwhere", "fid = $fid",
                    "-tr", "$(resolution[1])", "$(resolution[2])" #"0.00001", "0.00001", # Around 1 by 1 meter
                ]
                warped = ArchGDAL.unsafe_gdalwarp([raster_ds],
                    warp_options
                )
                ArchGDAL.write(warped, "$dest/$fid-$year-$month_srt.tiff")
            end
        end
    end
end
function count_values_with_fid(raster, values, fid, year, month)
    vals = zeros(Float64, length(values))
    ArchGDAL.read(raster) do dataset
        band = ArchGDAL.getband(dataset, 1)
        data_array = ArchGDAL.read(band)
        for i in 1:length(values)
            vals[i] = count(==(values[i]), data_array,)
        end
    end
    data = DataFrame(
        fid=fill(fid, length(values)),
        year=fill(year, length(values)),
        month=fill(month, length(values)),
        categorie=values,
        value=vals,
        shares=calc_share(vals)
    )
    return data
end
function create_vhi_data_per_fid(years, months, fids, clip_path; resolution=(0.0001, 0.0001))
    download_images(years, months, "Data/GeoTiff_MDL/", clip_path)
    clip_raster_with_fid(years, months, "Data/GeoTiff_MDL", "Data/GeoTiff_MDL_Clipped", clip_path, fids; resolution=(0.0001, 0.0001)
    )
    data = DataFrame()
    for fid in fids, year in years, month in months
        month_srt = lpad(month, 2, '0')
        df_temp = count_values_with_fid("Data/GeoTiff_MDL_Clipped/$fid-$year-$month_srt.tiff", [0, 1, 2, 3, 4, 5, 6, 7, 8], fid, year, month)
        append!(data, df_temp)
    end
    return data
end
data = sort(create_vhi_data_per_fid(2023:2024, 1:12, 1:58, "D:/julia/VHI/Data/mdl.gpkg"; resolution=(0.0001, 0.0001)), [:fid, :year, :month, :categorie])
