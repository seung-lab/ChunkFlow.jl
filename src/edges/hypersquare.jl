import HDF5
import Images
import JSON
import EMIRT
using DataStructures
# import GoogleCloud.Utils.Storage

# These default constants are configurable parameters
const DEFAULT_SEGMENT_ID_TYPE = UInt16
const DEFAULT_AFFINITY_TYPE = Float32
const DEFAULT_SEGMENTATION_FILENAME = "segmentation.lzma"
const DEFAULT_IMAGE_QUALITY = 25
const DEFAULT_IMAGE_FOLDER = "jpg"
const DEFAULT_BOUNDING_BOX_FILENAME = "segmentation.bbox"
const DEFAULT_SEGMENT_SIZE_FILENAME = "segmentation.size"
const DEFAULT_GRAPH_FILENAME = "segmentation.graph"
const DEFAULT_METADATA_FILENAME = "metadata.json"
const DEFAULT_RESOLUTION_UNITS = "nanometers"

# These values are not configurable as parameters
const SEGMENT_BOUNDING_BOX_TYPE = UInt16
const SEGMENT_SIZE_TYPE = UInt32

# Helper constants and macros
const BITS_PER_BYTE = 8

# default return flag for asyncronized writting
const DEFAULT_RETURN_FLAG = true

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
    @assert length(chunk_segmentation.origin) == ndims(chunk_segmentation) == 3
    # extract the segmentation data from the chunk
    println("Extracting and converting segmentation... ")
    (segmentation, segment_pairs, segment_affinities) =
        extract(chunk_segmentation.data;
            segment_id_type = as_type(get(params,
                :segment_id_type, string(DEFAULT_SEGMENT_ID_TYPE))),
            affinity_type = as_type(get(params,
                :affinity_type, string(DEFAULT_AFFINITY_TYPE))))

    chunk_image = fetch(c, inputs[:img])
    @assert length(chunk_image.origin) == ndims(chunk_image) == 3
    # we are only operating on the truncated UInt8 datatype for efficiency
    println("Extracting and converting images... ")
    images = convert(Array{UInt8, 3}, chunk_image.data)

    # get/create the chunk_folder
    base_folder = tempname()
    mkdir(base_folder)
    chunk_folder = to_chunk_folder(base_folder, chunk_image)
    println("Saving hypersquare to $chunk_folder")

    # write all data to disk
    println("Writing Segmentation ...")
    writeSegmentationFutureFlag = @spawn write_segmentation(segmentation,
        chunk_folder;   filename = get(params,
        :segmentation_filename, DEFAULT_SEGMENTATION_FILENAME))

    println("Writing Supplementary ...")
    writeSupplementataryFutureFlag = @spawn write_supplementary(segmentation, chunk_folder;
        bounding_box_filename = get(params,
            :bounding_box_filename, DEFAULT_BOUNDING_BOX_FILENAME),
        segment_size_filename = get(params,
            :segment_size_filename, DEFAULT_SEGMENT_SIZE_FILENAME))

    println("Writing Graph ...")
    writeGraphFutureFlag = @spawn write_graph(segment_pairs, segment_affinities,
        chunk_folder;
        graph_filename = get(params, :graph_filename, DEFAULT_GRAPH_FILENAME))

    println("Writing Images ...")
    writeImagesFutureFlag = @spawn write_images(images, chunk_folder;
        quality = get(params, :image_quality, DEFAULT_IMAGE_QUALITY),
        image_folder = get(params, :image_folder, DEFAULT_IMAGE_FOLDER))

    println("Writing Metadata ...")
    writeMetadataFutureFlag = @spawn write_metadata(params, chunk_segmentation, chunk_image, chunk_folder;
        filename = get(params, :metadata_filename, DEFAULT_METADATA_FILENAME))

    # fetch all the flags
    fetch(writeSegmentationFutureFlag)
    fetch(writeSupplementataryFutureFlag)
    fetch(writeGraphFutureFlag)
    fetch(writeImagesFutureFlag)
    fetch(writeMetadataFutureFlag)

    # move hypersquare folder to destination
    dstDir = replace(outputs[:projectsDirectory],"~",homedir())
    dstDir = joinpath(dstDir, basename(chunk_folder))
    if iss3(dstDir) || isGoogleStorage(dstDir)
        upload( chunk_folder, dstDir )
    # elseif isGoogleStorage(dstDir)
    #     GoogleCloud.Utils.Storage.upload(chunk_folder, dstDir)
    else
        mv(chunk_folder, dstDir; remove_destination=true)
    end
end

"""
    as_type(string::AbstractString)

Evaluates the string as a type.
"""
function as_type(string::AbstractString)
    parsed_type = eval(Symbol(string))
    if !isa(parsed_type, Type)
        error("$string is not a type")
    end
    return parsed_type
end

"""
    extract(chunk_segmentation;
        segment_id_type::Type = DEFAULT_SEGMENT_ID_TYPE,
        affinity_type::Type = DEFAULT_AFFINITY_TYPE)

Extract the tuple of (segmentation, segmentPair, and segmentPairAffinities)
from SegMST and also convert the values to the input types
"""
function extract(seg_mst::EMIRT.SegMST;
        segment_id_type::Type = DEFAULT_SEGMENT_ID_TYPE,
        affinity_type::Type = DEFAULT_AFFINITY_TYPE)
    return (smart_cast(seg_mst.segmentation, seg_mst.segmentPairs,
            segment_id_type) ...,
        convert(Array{affinity_type, 1},
            seg_mst.segmentPairAffinities))
end

"""
    smart_cast{U <: Unsigned}(segmentation::Array{U, 3},
        segment_pairs::Array{U, 2}, cast_type::Type)

Cast the segment ids to the input cast_type. Returns a tuple of the new
segmentation and new segment_pairs using the new cast_type.
This checks to make sure that the new segment ids can be represented with the
new cast_type. Throw an error if it is simply not possible to represent
all the segment ids inside the input type. If it is possible, but we have some
ids that do not fit, relabel all the ids so they fit inside input cast_type
"""
function smart_cast{U <: Unsigned}(segmentation::Array{U, 3},
        segment_pairs::Array{U, 2}, cast_type::Type)
    # Attempt to do conversion first, if we fail due to InexactError, we will
    # try to handle it in the catch
    try
        segmentation = convert(Array{cast_type, 3}, segmentation)
        segment_pairs = convert(Array{cast_type, 2}, segment_pairs)
    catch caught_error
        if !isa(caught_error, InexactError)
            rethrow(caught_error)
        else
            println("Downcasting will lose segments, trying to remap ids...")

            unique_values = unique(segmentation)
            num_segments = length(unique_values)
            supported_num_segments = 2 ^ (sizeof(cast_type) * BITS_PER_BYTE)

            if num_segments > supported_num_segments
                error("TOO MANY SEGMENTS ($num_segments)! " *
                    "HYPERSQUARE only supports $supported_num_segments with " *
                    "input typee :$cast_type :(")
            end

            segmentation = redistribute_ids(unique_values,
                segmentation, cast_type)

            segment_pairs = redistribute_ids(unique_values,
                segment_pairs, cast_type)
        end
    end
    return (segmentation, segment_pairs)
end

"""
    redistribute_ids{U <: Unsigned}(old_ids::Array{U, 1},
        old_array::Array{U}, new_id_type::Type)

Linearly redistribute all the old_ids into the new_id_type. Then remap all the old
ids in the old_array into a new array
"""

function redistribute_ids{U <: Unsigned}(old_ids::Array{U, 1},
        old_array::Array{U}, new_id_type::Type)
    new_array = zeros(new_id_type, size(old_array))

    label_map = Dict{U, new_id_type}(
        zip(old_ids, UnitRange{new_id_type}(0, length(old_ids) - 1)))
    for index in 1:length(old_array)
        new_array[index] = label_map[old_array[index]]
    end

    return new_array
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
    return DEFAULT_RETURN_FLAG
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
    return DEFAULT_RETURN_FLAG
end

"""
    write_graph{U <: Unsigned, F <:AbstractFloat}(segment_pairs::Array{U, 2},
        segment_pair_affinities::Array{F, 1},
        chunk_folder::AbstractString;
        graph_filename = DEFAULT_GRAPH_FILENAME)

writes the graph (MST) into a file in the format of:
    [ edge_1_vertex_id_1::U, edge_1_vertex_id_2::U,
      edge_1_affinity::F
      ...
      edge_N_vertex_id_1::U, edge_N_vertex_id_2::U,
      edge_N_affinity::F]
"""
function write_graph{U <: Unsigned, F <: AbstractFloat}(
        segment_pairs::Array{U, 2},
        segment_pair_affinities::Array{F, 1},
        chunk_folder::AbstractString;
        graph_filename = DEFAULT_GRAPH_FILENAME)
    graph_file = open(joinpath(chunk_folder, graph_filename), "w")

    for edge_index in 1:length(segment_pair_affinities)
        write(graph_file, segment_pairs[edge_index, 1])
        write(graph_file, segment_pairs[edge_index, 2])
        write(graph_file, segment_pair_affinities[edge_index])
    end
    close(graph_file)
    return DEFAULT_RETURN_FLAG
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

    if !isdir(joinpath(chunk_folder, image_folder))
      mkdir(joinpath(chunk_folder, image_folder))
    end

    @sync @parallel for i in 1:size(images)[3]
        # image = Images.grayim(images[:, :, i])
        Images.save(joinpath(chunk_folder, image_folder, "$(i-1).jpg"),
            permutedims(images[:,:,i],[2,1]);
            quality = quality)
    end
    return DEFAULT_RETURN_FLAG
end

"""
    get_bounding_boxes_and_sizes(segmentation)

Find the bounding boxes (min and max coordinates) for each segment ID.
Also count the number of voxels of each segment id is present in the volume
Returns:
* Tuple{Array{SEGMENT_BOUNDING_BOX_TYPE, 1}, Array{SEGMENT_SIZE_TYPE, 1}}
** First element is an array containing the bounding boxes.
    [seg_1_min_x, seg_1_min_y, seg_1_min_z, seg_1_max_x, seg_1_max_y, seg_1_max_z ...
     seg_N_min_x, seg_N_min_y, seg_N_min_z, seg_N_max_x, seg_N_max_y, seg_N_max_z]
** Second element is an array of segment sizes
    [seg_1_size, seg_2_size ... seg_N_size]
"""
function get_bounding_boxes_and_sizes{U <: Unsigned}(segmentation::Array{U, 3})

    dimensions = size(segmentation)
    num_segments = maximum(segmentation) + 1 # + 1 to accommodate segment id 0
    bounding_boxes_array = zeros(SEGMENT_BOUNDING_BOX_TYPE, num_segments * 6)
    sizes = zeros(SEGMENT_SIZE_TYPE, num_segments)

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
    segment_id_type::Type
    affinity_type::Type
    bounding_box_type::Type
    size_type::Type
    image_type::Type
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
function write_metadata(
        params::OrderedDict{Symbol, Any},
        chunk_segmentation::Chunk,
        chunk_image::Chunk,
        chunk_folder::AbstractString;
        filename::AbstractString = DEFAULT_METADATA_FILENAME)
    segment_id_type = as_type(get(params,
                :segment_id_type, string(DEFAULT_SEGMENT_ID_TYPE)))
    affinity_type = as_type(get(params,
                :affinity_type, string(DEFAULT_AFFINITY_TYPE)))
    bounding_box_type = SEGMENT_BOUNDING_BOX_TYPE
    size_type = SEGMENT_SIZE_TYPE
    image_type = eltype(chunk_image.data)
    # max value + 1 to accommodate segment id 0
    num_segments = length(unique(chunk_segmentation.data.segmentation))
    num_edges = length(chunk_segmentation.data.segmentPairAffinities)
    chunk_voxel_dimensions = [size(chunk_segmentation.data.segmentation) ...]
    voxel_resolution = chunk_segmentation.voxelSize
    resolution_units = get(params,
                :resolution_units, DEFAULT_RESOLUTION_UNITS)
    physical_offset_min = physical_offset(chunk_segmentation)
    physical_offset_max = physical_offset_min +
        chunk_voxel_dimensions .* voxel_resolution

    metadata = HyperSquareMetadata(
        segment_id_type,
        affinity_type,
        bounding_box_type,
        size_type,
        image_type,
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
    return DEFAULT_RETURN_FLAG
end
