import HDF5
import Images
import JSON
using DataStructures

export ef_hypersquare

const DEFAULT_SEGMENTATION_FILENAME = "segmentation.lzma"
const DEFAULT_IMAGE_QUALITY = 25
const DEFAULT_IMAGE_FOLDER = "jpg"
const DEFAULT_BOUNDING_BOX_FILENAME = "segmentation.bbox"
const DEFAULT_SEGMENT_SIZE_FILENAME = "segmentation.size"
const DEFAULT_GRAPH_FILENAME = "segmentation.graph"
const DEFAULT_METADATA_FILENAME = "metadata.json"

const WRITE_BUFFER_BYTES = 50 * 1024 * 1024
#=
 =type DictChannel end
 =type Chunk end
 =#

function ef_hypersquare(c::DictChannel,
        params::OrderedDict{Symbol, Any},
        inputs::OrderedDict{Symbol, Any},
        outputs::OrderedDict{Symbol, Any})
    println("Running Hypersquare")
    # fetch all data we need from the DictChannel c
    chunk_segmentation = fetch(c, inputs[:sgm])
    # we are only operating on the truncated UInt16 datatype for efficiency
    segmentation = convert(Array{UInt16, 3},
        chunk_segmentation.data.segmentation)

    chunk_image = fetch(c, inputs[:img])
    # we are only operating on the truncated UInt8 datatype for efficiency
    images = convert(Array{UInt8, 3}, chunk_image.data)

    # get/create the chunk_folder
    base_folder = outputs[:fprj]
    chunk_folder = to_chunk_folder(base_folder, chunk_image)
    println("Saving hypersqure to $chunk_folder")

    # write all data to disk
    println("Writing Segmentation ...")
    write_segmentation(segmentation, chunk_folder;
        filename = getkey(params,
            :segmentation_filename, DEFAULT_SEGMENTATION_FILENAME))

    println("Writing Supplementary ...")
    write_supplementary(segmentation, chunk_folder;
        bounding_box_filename = getkey(params,
            :bounding_box_filename, DEFAULT_BOUNDING_BOX_FILENAME),
        segment_size_filename = getkey(params,
            :segment_size_filename, DEFAULT_SEGMENT_SIZE_FILENAME))

    println("Writing Graph ...")
    write_graph(chunk_segmentation.data.segmentPairs,
        chunk_segmentation.data.segmentPairAffinities, chunk_folder;
        graph_filename = getkey(params, :graph_filename, DEFAULT_GRAPH_FILENAME))

    println("Writing Images ...")
    write_images(images, chunk_folder;
        quality = getkey(params, :image_quality, DEFAULT_IMAGE_QUALITY),
        image_folder = getkey(params, :image_folder, DEFAULT_IMAGE_FOLDER))

    println("Writing Metadata ...")
    write_metadata(chunk_segmentation, chunk_folder,
        filename = getkey(params,
            :metadata_filename, DEFAULT_METADATA_FILENAME))
end

"""
    to_chunk_folder(base_folder::AbstractString, chunk::Chunk)
Get or create a chunk folder that corresponds to chunk data.
"""
function to_chunk_folder(base_folder::AbstractString, chunk::Chunk)
    origin = convert(Array{Int64, 1}, chunk.origin)
    volume_end = origin + [size(chunk.data)...] - 1

    # if the base folder exists, create a new chunk folder in it
    if isdir(base_folder)
        chunk_folder = joinpath(base_folder, "chunk_")
    else
    # the base folder doesn't exist, we assume that the base
    # is a folder prefix used as template for the chunk folder
        chunk_folder = base_folder
    end

    chunk_folder = chunk_folder *
        "$(origin[1])-$(volume_end[1])_" *
        "$(origin[2])-$(volume_end[2])_" *
        "$(origin[3])-$(volume_end[3])"

    if !isdir(chunk_folder)
        mkdir(chunk_folder)
    end

    return chunk_folder
end

"""
    write_segmentation{U <: Unsigned}(segmentation::Array{U, 3},
        chunk_folder::AbstractString; filename = DEFAULT_SEGMENTATION_FILENAME)
Compress and write the segmentation to disk
"""
function write_segmentation{U <: Unsigned}(segmentation::Array{U, 3},
        chunk_folder::AbstractString; filename = DEFAULT_SEGMENTATION_FILENAME)
    segmentation_file = open(joinpath(chunk_folder, filename), "w")

    lzma(segmentation, segmentation_file)

    close(segmentation_file)
end

"""
    lzma(writable::Any, output::IO)

Writes lzma compressed object into the given output stream.
"""
function lzma(writable::Any, output::IO)
    input = Pipe()

    lzma_command = `lzma --compress --extreme -9 -f -k --stdout`
    process = spawn(pipeline(lzma_command, stdout = output, stdin = input))

    write(input, writable)
    close(input.in)
end

"""
    write_supplementary{U <: Unsigned}(segmentation::Array{U, 3},
        chunk_folder::AbstractString;
        bounding_box_filename = DEFAULT_BOUNDING_BOX_FILENAME,
        segment_size_filename = DEFAULT_SEGMENTATION_FILENAME)
Write write supplementary data we calculate from the segmentation i.e.
segment bounding boxes and segment sizes.
"""
function write_supplementary{U <: Unsigned}(segmentation::Array{U, 3},
        chunk_folder::AbstractString;
        bounding_box_filename = DEFAULT_BOUNDING_BOX_FILENAME,
        segment_size_filename = DEFAULT_SEGMENTATION_FILENAME)
    (bounding_boxes, sizes) = get_bounding_boxes_and_sizes(segmentation)

    bounding_box_file = open(joinpath(chunk_folder, bounding_box_filename), "w")
    write(bounding_box_file, bounding_boxes)
    close(bounding_box_file)

    segment_size_file = open(joinpath(chunk_folder, segment_size_filename), "w")
    write(segment_size_file, sizes)
    close(segment_size_file)
end

"""
    write_graph(segment_pairs::Array{UInt32, 2},
        segment_pair_affinities::Array{Float32, 1},
        chunk_folder::AbstractString;
        graph_filename = DEFAULT_GRAPH_FILENAME)

writes the graph (MST) into a file in the format of: 
    [ edge_1_vertex_id_1::UInt32, edge_1_vertex_id_2::UInt32,
      edge_1_affinity::Float64
      ...
      edge_N_vertex_id_1::UInt32, edge_N_vertex_id_2::UInt32,
      edge_N_affinity::Float64]
"""
function write_graph(segment_pairs::Array{UInt32, 2},
        segment_pair_affinities::Array{Float32, 1},
        chunk_folder::AbstractString;
        graph_filename = DEFAULT_GRAPH_FILENAME)
    graph_file = open(joinpath(chunk_folder, graph_filename), "w")

    for edge_index in 1:length(segment_pair_affinities)
        write(graph_file, segment_pairs[edge_index, 1])
        write(graph_file, segment_pairs[edge_index, 2])
        write(graph_file, segment_pair_affinities[edge_index])
    end
    close(graph_file)
end

"""
    write_images{U <: Unsigned}(images::Array{U, 3}, chunk_folder::AbstractString;
        quality = DEFAULT_IMAGE_QUALITY)

Write this image into the chunk_folder. Convert images to UInt8 and write each
slice as a separate jpg with naming convention of 0.jpg ... X.jpg
"""
function write_images{U <: Unsigned}(images::Array{U, 3},
        chunk_folder::AbstractString;
        quality = DEFAULT_IMAGE_QUALITY, image_folder = DEFAULT_IMAGE_FOLDER)

    mkdir(joinpath(chunk_folder, image_folder))
    for i in 1:size(images)[3]
        image = Images.grayim(images[:, :, i])
        Images.save(joinpath(chunk_folder, image_folder, "$(i-1).jpg"),
            image; quality = quality)
    end
end

"""
    get_bounding_boxes_and_sizes(segmentation)

Find the bounding boxes (min and max coordinates) for each segment ID.
Also count the number of voxels of each segment id is present in the volume
Returns:
* Tuple{Array{UInt16, 1}, Array{UInt32, 1}}
** First element is an array containing the bounding boxes. 
    [seg_1_min_x, seg_1_min_y, seg_1_min_z, seg_1_max_x, seg_1_max_y, seg_1_max_z ...
     seg_N_min_x, seg_N_min_y, seg_N_min_z, seg_N_max_x, seg_N_max_y, seg_N_max_z]
** Second element is an array of segment sizes
    [seg_1_size, seg_2_size ... seg_N_size]
"""
function get_bounding_boxes_and_sizes(segmentation)
    dimensions = size(segmentation)
    num_segments = maximum(segmentation) + 1 # + 1 to accommodate segment id 0
    bounding_boxes_array = zeros(UInt16, num_segments * 6)
    sizes = zeros(UInt32, num_segments)

    # set the mins to the end of the volume
    for index in 1:6:(num_segments*6)
        bounding_boxes_array[index] = dimensions[1] - 1
        bounding_boxes_array[index + 1] = dimensions[2] - 1
        bounding_boxes_array[index + 2] = dimensions[3] - 1
    end

    # go through every voxel and for each segment update the min and max locations
    for z in 1:dimensions[3]
        for y in 1:dimensions[2]
            for x in 1:dimensions[1]
                segment_id = segmentation[x, y, z]
                index = (segment_id) * 6 + 1

                @inbounds bounding_boxes_array[index + 0] =
                      min(bounding_boxes_array[index + 0], x - 1)
                @inbounds bounding_boxes_array[index + 1] =
                      min(bounding_boxes_array[index + 1], y - 1)
                @inbounds bounding_boxes_array[index + 2] =
                      min(bounding_boxes_array[index + 2], z - 1)
                @inbounds bounding_boxes_array[index + 3] =
                      max(bounding_boxes_array[index + 3], x - 1)
                @inbounds bounding_boxes_array[index + 4] =
                      max(bounding_boxes_array[index + 4], y - 1)
                @inbounds bounding_boxes_array[index + 5] =
                      max(bounding_boxes_array[index + 5], z - 1)

                size_index = segment_id + 1
                @inbounds sizes[size_index] = sizes[size_index] + 1
            end
        end
    end

    return (bounding_boxes_array, sizes)
end

"""
HyperSquareMetadata is all the metadata that is required for eyewire to
    function properly
"""
type HyperSquareMetadata
    segmentation_type::Type
    bounding_box_type::Type
    image_type::Type
    size_type::Type
    num_segments::Unsigned
    num_edges::Unsigned
    chunk_voxel_dimensions::Array{Unsigned, 1}
    voxel_resolution::Array{Unsigned, 1}
    resolution_units::AbstractString
    physical_offset_min::Array{Unsigned, 1}
    physical_offset_max::Array{Unsigned, 1}
end

"""
     write_metadata(chunk_folder::AbstractString, chunk::Chunk,
        filename::AbstractString = DEFAULT_METADATA_FILENAME)
Write the metadata file based off of the chunk. Metadata fields are specified
in HyperSquareMetadata.
"""
function write_metadata(chunk_segmentation::Chunk, chunk_folder::AbstractString;
        filename::AbstractString = DEFAULT_METADATA_FILENAME)
    segmentation_type = UInt16
    bounding_box_type = UInt16
    image_type = UInt8
    size_type = UInt32
    # max value + 1 to accommodate segment id 0
    num_segments = maximum(chunk_segmentation.data.segmentation) + 1
    num_edges = length(chunk_segmentation.data.segmentPairAffinities)
    chunk_voxel_dimensions = [size(chunk_segmentation.data.segmentation)...]
    voxel_resolution = chunk_segmentation.voxelsize
    resolution_units = "nanometers"
    physical_offset_min = physical_offset(chunk_segmentation)
    physical_offset_max = physical_offset_min +
        chunk_voxel_dimensions .* voxel_resolution

    metadata = HyperSquareMetadata(
        segmentation_type,
        bounding_box_type,
        image_type,
        size_type,
        num_segments,
        num_edges,
        chunk_voxel_dimensions,
        voxel_resolution,
        resolution_units,
        physical_offset_min,
        physical_offset_max)

    # There is no YAML writer in Julia :(
    metadata_file = open(joinpath(chunk_folder, filename), "w")
    write(metadata_file, JSON.json(metadata, 4))
    close(metadata_file)
end
