using Pkg
Pkg.add("DataFrames")
Pkg.add("CSV")
Pkg.add("Distances")
Pkg.add("Statistics")

using DataFrames, CSV, Distances, Statistics

wt_path = ARGS[1]
gene_group_path = ARGS[2]
mapping_seqs_path = ARGS[3]
out_path = ARGS[4]


# Set path
dir = @__DIR__
home_dir = joinpath(split(dir, "/")[1:end-3])

df_wt = CSV.read(wt_path, DataFrame)
df_groups = CSV.read(gene_group_path, DataFrame, select=[2, 3])
gene_group_dict = Dict(df_groups.genename .=> df_groups.pnum)

for file in readdir(mapping_seqs_path; join=true)
    if ~occursin("mapping_counted.csv", file)
        continue
    end

    df_in = CSV.read(
        file, 
        DataFrame, 
        ignorerepeated=true,
        delim="\t",
        header=["counts", "promoter", "barcode"]
        )
    group = split(split(file, '/')[end], '_')[1]
    names = String[]
    nmuts = Int[]
    promoters = String[]
    barcodes = String[]
    counts = Int[]
    gdf = groupby(df_in, :barcode)
    for _df in gdf
        #x = LongDNA{4}(_df.promoter[1])
        x = string(_df.promoter[1])
        distances = [hamming(x, y) for y in string.(df_wt.geneseq)]
        closest_seq =  argmin(distances)
        if string(gene_group_dict[split(df_wt.name[closest_seq], '_')[1]]) == group
            push!(names, df_wt.name[closest_seq])
            push!(nmuts, minimum(distances))
            push!(promoters, _df.promoter[1])
            push!(barcodes, _df.barcode[1])
            push!(counts, _df.counts[1])
        end
    end


    df_out = DataFrame(barcode=barcodes, promoter=promoters, count=counts, name=names, nmut=nmuts)
    CSV.write(out_path * "/$(group)_mapping_identified.csv", df_out, delim=" ")
end
