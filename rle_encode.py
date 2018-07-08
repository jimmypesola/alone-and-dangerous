#!/usr/bin/env python

# Python version of the map data compressor
# On MSYS (Windows) it seems to be much faster than the Perl version.

import sys
import struct

C_INFILE_NAME = "aad_map_big.bin"
C_OUTFILE_NAME = "aad_map_big.rle"
MAP_WIDTH = 16
MAP_HEIGHT = 12
MAP_SIZE = MAP_WIDTH * MAP_HEIGHT

ROOM_WIDTH = 20
ROOM_HEIGHT = 12
ROOM_SIZE = ROOM_WIDTH * ROOM_HEIGHT

MAP_STRIDE = MAP_WIDTH * ROOM_SIZE

STATE_NEW_BYTE = 0
STATE_LOOKAHEAD = 1

DEBUG = True


# Array comparison function
def are_equal(arr1, arr2):
    if len(arr1) != len(arr2):
        return False
    else:
        for i in range(len(arr1)):
            if arr1[i] != arr2[i]:
                return False
    return True


# Read the binary uncompressed map file
def read_binary_file(filename):
    # Read binary file and store it as numeric value array
    infile = open(filename, "rb")
    data = infile.read()

    byte_array = []
    for i in range(len(data)):
        byte_array.append(ord(data[i]))

    infile.close()
    return byte_array


# Print byte array as hexadecimal values in 20 byte rows
def print_byte_array(byte_array):
    column_index = 0
    bytes = []
    for byte in byte_array:
        if column_index == 20:
            for i in range(20):
                sys.stdout.write("%.2x " % bytes[i])
            sys.stdout.write("\n")
            column_index = 0
            bytes = []
        bytes.append(byte)
        column_index += 1


# Remap map lines (320x144 tiles) into 192x chunks of tiles per room of sizes 20x12 tiles.
# This helps searching and compression.
# Returns: byte array of tiles organized by room chunks
def remap_to_room_chunks(byte_array):

    room_chunk_array = []
    for y in range(MAP_HEIGHT):
        for x in range(MAP_WIDTH):

            current_room_tiles = []

            for j in range(ROOM_HEIGHT):
                for i in range(ROOM_WIDTH):
                    idx = y*MAP_STRIDE + x*ROOM_WIDTH + j*MAP_WIDTH * ROOM_WIDTH + i
                    if DEBUG:
                        print "Setting data [%d,%d] for room at index %d..." % (i, j, idx)
                    current_room_tiles.append(byte_array[idx])

            if DEBUG:
                print "Added room [%d,%d] at index %d" % (x, y, y*MAP_STRIDE + x*ROOM_WIDTH)

            room_chunk_array.extend(current_room_tiles)

    return room_chunk_array



# Compress room chunks
# - Compresses the tile chunks belonging to each room individually
# - Generates an index to each room's position in the resulting list of compressed rooms
# Returns: A two-tuple of the indices list and the compressed rooms array
def compress_room_chunks(room_chunk_array):

    identical_count = 0
    last_byte = 0
    curr_byte = 0
    state = STATE_NEW_BYTE
    indices = []
    compressed_chunks = []

    for j in range(MAP_SIZE):   # For each room in the map
        compressed_chunk = []

        for i in range(ROOM_SIZE):  # For each tile in the room (in this case it should be 240 tiles)

            # Get the index 'i' of the room data for the room indexed by 'j'
            curr_byte = room_chunk_array[j*ROOM_SIZE+i]

            if state == STATE_NEW_BYTE:
                identical_count = 1
                last_byte = curr_byte

                # We have read the first byte, now look for the same value in subsequent bytes
                state = STATE_LOOKAHEAD

            elif state == STATE_LOOKAHEAD:
                if last_byte == curr_byte:
                    # Found next byte to be same value as previous, increment the count for this byte value
                    identical_count += 1
                else:
                    # Next byte value is different, write the RLE encoded length/value byte pair now.
                    compressed_chunk.append(identical_count)
                    compressed_chunk.append(last_byte)
                    identical_count = 1
                    last_byte = curr_byte   # Reset the condition; start checking from the current byte

        # The current room pointed to by index j is finished, add the remaining data to the compressed chunk(room).
        state = STATE_NEW_BYTE
        compressed_chunk.append(identical_count)
        compressed_chunk.append(last_byte)

        # Add the starting position for the new compressed room data into an indices list.
        # It is used to find the starting position of each compressed room/chunk in the compressed rooms array.
        indices.append(len(compressed_chunks))

        # Compressing rooms is only good if it occupies less than original room size:
        if len(compressed_chunk) < ROOM_SIZE:
            compressed_chunks.append(len(compressed_chunk))  # First byte tells length of compressed room bytes
            compressed_chunks.extend(compressed_chunk)   # Add the compressed chunk/room to 

        else:
            # Ooops... Compressed room resulted in being bigger than original size!
            compressed_chunks.append(0)  # First byte is 0 -> means room is uncompressed.
            idx1 = j*ROOM_SIZE
            idx2 = j*ROOM_SIZE+ROOM_SIZE
            compressed_chunks.extend(room_chunk_array[idx1:idx2])  # Just copy the original uncompressed room slice.

    return (indices, compressed_chunks) 



# print_compressed_rooms
# Prints the data on screen.
def print_compressed_rooms(compressed_chunks):
    compressed_bytes_left = 0   # Stores current number of identical bytes left to print
    pos = 0                     # Iterating index over the compressed chunks array
    column_index = 0            # Just for pretty printing
    room_coord = 0              # Keeps track of the room coordinate within the compressed chunk array
    while pos<len(compressed_chunks):
        if compressed_bytes_left == 0:
            compressed_bytes_left = compressed_chunks[pos]
            print "\n\nRoom [%d, %d]\n   Length: %d" % (room_coord%16, int(room_coord/16), compressed_bytes_left)
            if compressed_bytes_left == 0:
                pos += ROOM_SIZE    # Skips the room entirely in case room was not compressed
                print "Uncompressed data won't be printed."
            room_coord += 1 # Increment only when the data for one room has been processed
            column_index = 0
        else:
            sys.stdout.write("%03d " % compressed_chunks[pos])
            column_index += 1

            if column_index == 20:  # Pretty print output of only 20 columns of bytes
                sys.stdout.write("\n")
                column_index = 0

            compressed_bytes_left -= 1
        pos += 1


# encode_with_dictionary
# Make a dictionary of all duplicated rooms -> applies a second pass of compression.
# (reusing one single data chunk for all identical rooms.)
# Parameters:
#   indices                 - List of indices where each compressed room data starts in compressed_room_array
#   compressed_room_array   - Compressed chunks of tiles belonging to rooms indexed by indices parameter.
# Returns: Two-tuple of the dictionary (192 entries) and the optimized and compressed array of chunks.
def encode_with_dictionary(indices, compressed_room_array):

    dictionary = []
    optimized_room_array = []
    x = 0
    output = ""     # Only for debug printing

    for idx in range(len(indices)):

        #print "Reading old dictionary at index: %d" % idx

        pos = indices[idx]
        pos_len = compressed_room_array[pos]

        # If the room is uncompressed, use full size:
        if pos_len == 0:
            pos_len = ROOM_SIZE
        pos += 1

        #print "   Found data at index [%d] with length [%d]." % (idx, pos_len)

        match = False
        pos_end = pos + pos_len
        data_slice = compressed_room_array[pos:pos_end]

        #output = ""
        #for item in data_slice:
        #    output += "%03d " % item

        #print "Data Slice: %s" % output

        for idx_lookup in range(len(dictionary)):

            #print "Checking new dictionary for equal slices at index: %d" % dictionary[idx_lookup]

            pos_lookup = dictionary[idx_lookup]
            lookup_len = optimized_room_array[pos_lookup]
            pos_lookup += 1

            #print "   Found data at index [%d] with length[%d]" % (dictionary[idx_lookup], lookup_len)

            pos_lookup_end = pos_lookup + lookup_len
            dict_slice = optimized_room_array[pos_lookup:pos_lookup_end]

            #output = ""
            #for item in dict_slice:
            #    output += "%03d " % item

            #print "Dictionary slice: %s" % output

            if are_equal(data_slice, dict_slice):

                if DEBUG:
                    # Inform of adding reference to dictionary
                    print "\nSuccessful match of %d bytes at position %d!" % (lookup_len, pos_lookup)
                    print " >>>>> Set dictionary pos [%d, %d] to refer to repeated position [%d]" % (x % MAP_WIDTH, int(x/MAP_WIDTH), dictionary[idx_lookup])

                # Push to dictionary
                dictionary.append(dictionary[idx_lookup])

                match = True
                break

        # Push new data to destination compressed array.
        if not match:
            if DEBUG:
                print "\nAdding %d items to compressed array..." % len(data_slice)
            new_pos = len(optimized_room_array)
            optimized_room_array.append(pos_len)
            optimized_room_array.extend(data_slice)

            if DEBUG:
                print " ----- Set dictionary pos [%d, %d] to refer to new position [%d]" % (x % MAP_WIDTH, int(x/MAP_WIDTH), new_pos)

            # Push to dictionary
            dictionary.append(new_pos)

        x += 1

    return (dictionary, optimized_room_array)



# Reencode the dictionary 16-bit integers to a byte array
def reencode_dictionary(dictionary):
    dictionary_bytes = []
    for entry in dictionary:
        dictionary_bytes.extend(struct.pack("<H", entry))
    return dictionary_bytes



# Write the dictionary and the compressed data
def write_compressed_file(filename, dictionary_bytes, compressed_bytes):
    outfile = open(filename, "wb")
    output_data = bytearray(dictionary_bytes)
    outfile.write(output_data)
    output_data = bytearray(compressed_bytes)
    outfile.write(output_data)
    outfile.close()



def main():

    # By default use the file name 'aad_map_big.bin'
    filename = C_INFILE_NAME
    if len(sys.argv) == 2:
        filename = sys.argv[1]  # It can also be passed as one argument to the script

    # Read the input file
    print "Read input binary data..."
    byte_array = read_binary_file(filename)

    if DEBUG:
        print_byte_array(byte_array)

    print "Reorganizing data of %d bytes..." % len(byte_array)
    room_chunk_array = remap_to_room_chunks(byte_array)

    print "Compressing data..."
    indices, compressed_chunks = compress_room_chunks(room_chunk_array)

    print_compressed_rooms(compressed_chunks)

    print "\n Initial compressed array is %d bytes, with %d indices." % (len(compressed_chunks), len(indices))
    print "\nCompressing all duplicated rooms..."
    dictionary, optimized_and_compressed_array = encode_with_dictionary(indices, compressed_chunks)

    # Do a sanity check of the generation of the dictionary
    if len(dictionary) != MAP_SIZE:
        print "Dictionary size differs from complete size %d: %d" % (MAP_SIZE, len(dictionary))
    else:
        print "Dictionary is complete with %d entries" % len(dictionary)

    print "Original binary size is %d bytes." % len(byte_array)
    print "Fully compressed binary is %d bytes, intermediate compressed binary was %d bytes" % (len(optimized_and_compressed_array), len(compressed_chunks))

    # Add offset of the dictionary's length into the dictionary entries
    offset = len(dictionary)*2
    for idx in range(len(dictionary)):
        dictionary[idx] += offset

    # Check all entries in the compressed data for sanity
    x = 0
    for item in optimized_and_compressed_array:
        x += 1
        if DEBUG:
            sys.stdout.write("%03d " % item)
            if x % 20 == 0:
                sys.stdout.write("\n")
        if item > 255:
            sys.stdout.write("Compressed data byte value %d is too big at %d\n" % (item, x))
    print ""

    dictionary_bytes = reencode_dictionary(dictionary)

    # Finally write the file
    write_compressed_file(C_OUTFILE_NAME, dictionary_bytes, optimized_and_compressed_array)



# Start the script
main()
