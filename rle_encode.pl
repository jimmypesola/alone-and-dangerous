#!/usr/bin/perl

use strict;
use warnings;


use constant {
    INFILE_NAME => "aad_map_big.bin",
    OUTFILE_NAME => "aad_map_big.rle",

    MAP_WIDTH => 16,
    MAP_HEIGHT => 12,
    MAP_SIZE => 192,

    ROOM_WIDTH => 20,
    ROOM_HEIGHT => 12,
    ROOM_SIZE => 240,

    MAP_STRIDE => 3840,

    STATE_NEW_BYTE => 0,
    STATE_LOOKAHEAD => 1,

    DEBUG => 1
};

my $DEBUG = DEBUG;

sub are_equal
{
    my ($arr1, $arr2) = @_;
    if (0+@$arr1 != 0+@$arr2) {
        return 0;
    } else {
        for (my $i=0; $i<0+@$arr1; $i++) {
            if ($arr1->[$i] != $arr2->[$i]) {
                return 0;
            }
        }
    }
    return 1;
}


# read_binary_file
# Reads the specified file as binary data and returns a byte array
sub read_binary_file {
    my $infile_name = shift;
    open (IFH, "<$infile_name") or die ("Failed to open $infile_name for reading!");
    binmode (IFH);

    my $byte = "";
    my $byte_array = [];

    while (sysread (IFH, $byte, 1)) {
        my $ord = unpack 'C1', $byte;
        #print "Read: $ord\n";
        push @$byte_array, $ord;
    }

    close (IFH);
    return $byte_array;
}



# print_byte_array
# Parameters:
#   byte_array  - array of bytes (values presented as integers)
sub print_byte_array {
    my ($byte_array) = @_;
    my $c = 0;
    my @bytes = ();
    for my $byte (@$byte_array) {

        if ($c == 20) {
        for (my $i=0; $i<20; $i++) {
            printf "%.2x ", $bytes[$i];
        }
        print "\n";
            $c = 0;
            @bytes = ();
        }

        push @bytes, $byte;
        $c++;
    }
}


# Remap map lines (320x144 tiles) into 192x chunks of tiles per room of sizes 20x12 tiles.
# This helps searching and compression.
# Returns: byte array of tiles organized by room chunks
sub remap_to_room_chunks {

    my ($byte_array) = @_;
    my $room_chunk_array = [];

    for(my $y=0; $y<MAP_HEIGHT; $y++) {
        for(my $x=0; $x<MAP_WIDTH; $x++) {

            my $current_room_tiles = [];

            for (my $j=0; $j<ROOM_HEIGHT; $j++) {
                for (my $i=0; $i<ROOM_WIDTH; $i++) {

                    my $idx = $y*MAP_STRIDE+$x*ROOM_WIDTH+$j*MAP_WIDTH*ROOM_WIDTH+$i;
                    printf "Setting data [%d,%d] for room at index %d...\n", $i, $j, $idx if $DEBUG;
                    push @$current_room_tiles, $byte_array->[$idx];
                }
            }

            printf "Added room [%d,%d] at index %d\n", $x, $y, 240*$y*MAP_WIDTH+$x*20 if $DEBUG;

            push @$room_chunk_array, @$current_room_tiles;
        }
    }
    return $room_chunk_array;
}


# Compress room chunks
# - Compresses the tile chunks belonging to each room individually
# - Generates an index to each room's position in the resulting list of compressed rooms
# Returns: A two-tuple of the indices list and the compressed rooms array
sub compress_room_chunks {
    my ($room_chunk_array) = @_;
    my $identical_count = 0;
    my $last_byte = 0;
    my $curr_byte = 0;
    my $state = STATE_NEW_BYTE;
    my $indices = [];
    my $compressed_chunks = [];

    # Compress each room, each chunk of compressed rooms will have first byte the length,
    # the rest is (identical_count,value) byte pairs until length is complete.
    for (my $j=0; $j<MAP_SIZE; $j++) {
        my $compressed_chunk = [];

        for (my $i=0; $i<ROOM_SIZE; $i++) { # For each tile in the room (in this case it should be 240 tiles)

            # Get the index 'i' of the room data for the room indexed by 'j'
            $curr_byte = $room_chunk_array->[$j*ROOM_SIZE+$i];

            if ($state == STATE_NEW_BYTE) {
                $identical_count = 1;
                $last_byte = $curr_byte;

                $state = STATE_LOOKAHEAD;

            } elsif ($state == STATE_LOOKAHEAD) {
                if ($last_byte == $curr_byte) {
                    $identical_count++;
                } else {
                    push @$compressed_chunk, $identical_count;
                    push @$compressed_chunk, $last_byte;
                    $identical_count = 1;
                    $last_byte = $curr_byte;
                }
            }
        }
        $state = STATE_NEW_BYTE;
        push @$compressed_chunk, $identical_count;
        push @$compressed_chunk, $last_byte;

        # Add the starting position for the new compressed room data into an indices list.
        # It is used to find the starting position of each compressed room/chunk in the compressed rooms array.
        push @$indices, 0+@$compressed_chunks;

        # Compress only if occupies less than original size!
        if (@$compressed_chunk < ROOM_SIZE) {
            push @$compressed_chunks, 0+@$compressed_chunk, @$compressed_chunk;
        } else {
            my $idx1 = $j*ROOM_SIZE;
            my $idx2 = $j*ROOM_SIZE+ROOM_SIZE-1;
            push @$compressed_chunks, 0;
            push @$compressed_chunks, @{$room_chunk_array}[$idx1 .. $idx2];
        }
    }
    return ($indices, $compressed_chunks);
}

# print_compressed_rooms
# Prints the data on screen.
sub print_compressed_rooms {
    my ($compressed_chunks) = @_;
    my $compressed_bytes_left = 0;
    my $pos = 0;
    my $column_index = 0;
    my $room_coord = 0;
    while ($pos < 0+@$compressed_chunks) {
        if ($compressed_bytes_left == 0) {
            $compressed_bytes_left = $compressed_chunks->[$pos];
            printf "\n\nRoom [%d, %d]\n  Length: %d\n", int($room_coord % 16), int($room_coord/16), $compressed_bytes_left;
            if ($compressed_bytes_left == 0) {
                $pos+=ROOM_SIZE;
                print "Uncompressed data won't be printed.\n";
            }
            $room_coord++;
            $column_index = 0;
        } else {
            printf "%03d ", $compressed_chunks->[$pos];
            $column_index++;
            if ($column_index == 20) {
                print "\n";
                $column_index = 0;
            }
            $compressed_bytes_left--;
        }
        $pos++;
    }
}

# encode_with_dictionary
# Make a dictionary of all duplicated rooms -> applies a second pass of compression.
# (reusing one single data chunk for all identical rooms.)
# Parameters:
#   indices                 - List of indices where each compressed room data starts in compressed_room_array
#   compressed_room_array   - Compressed chunks of tiles belonging to rooms indexed by indices parameter.
# Returns: Two-tuple of the dictionary (192 entries) and the optimized and compressed array of chunks.
sub encode_with_dictionary {

    my ($indices, $compressed_room_array) = @_;
    my $dictionary = [];
    my $optimized_room_array = [];
    my $x = 0;
    #my $str = "";   # Only for debug printing

    for my $idx (@$indices) {

        #printf "Reading old dictionary at index: %d\n", $idx;

        my $pos = $idx;
        my $pos_len = $compressed_room_array->[$pos];

        # If uncompressed:
        if ($pos_len == 0) {
            $pos_len = ROOM_SIZE;
        }
        $pos++;

        #printf "   Found data at index [%d] with length [%d].\n", $idx, $pos_len;

        my $match = 0;
        my $pos_end = $pos + $pos_len - 1;
        my @data_slice = @{$compressed_room_array}[$pos .. $pos_end];

        #$str = "";
        #for my $item (@data_slice) {
        #    $str .= sprintf("%03d ", $item);
        #}
        #print "Data slice: $str\n";

        for my $idx_lookup (@$dictionary) {

            #printf "Checking new dictionary for equal chunks at index: %d\n", $idx_lookup;

            my $pos_lookup = $idx_lookup;
            my $lookup_len = $optimized_room_array->[$pos_lookup];
            $pos_lookup++;

            #printf "   Found data at index [%d] with length [%d].\n", $idx_lookup, $lookup_len;

            my $pos_lookup_end = $pos_lookup + $lookup_len - 1;
            my @dict_slice = @{$optimized_room_array}[$pos_lookup .. $pos_lookup_end];

            #$str = "";
            #for my $item (@dict_slice) {
            #    $str .= sprintf("%03d ", $item);
            #}
            #print "Dictionary slice: $str\n";

            if (&are_equal(\@data_slice,\@dict_slice)) {

                # Add reference to dictionary
                printf "\nSuccessful match of %d bytes at position %d!\n", $lookup_len, $pos_lookup if $DEBUG;
                printf " >>>>> Set dictionary pos [%d, %d] to refer to repeated position [%d]\n", $x % MAP_WIDTH, int($x/MAP_WIDTH), $idx_lookup if $DEBUG;

                # Push to dictionary
                push @$dictionary, $idx_lookup;

                $match = 1;
                last;
            }
        }
        if (!$match) {

            # New data? Then push to destination compressed array.
            printf "\nAdding %d items to compressed array\n", 0+@data_slice if $DEBUG;
            my $new_pos = 0+@$optimized_room_array;
            push @$optimized_room_array, $pos_len, @data_slice;

            printf " ----- Set dictionary pos [%d, %d] to refer to new position [%d]\n", $x % MAP_WIDTH, int($x/MAP_WIDTH), $new_pos if $DEBUG;

            # Push to dictionary
            push @$dictionary, $new_pos;
        }

        $x++;
    }
    return ($dictionary, $optimized_room_array);
}



# Write the dictionary and the compressed data
sub write_compressed_file {
    my ($dictionary_bytes, $compressed_bytes) = @_;
    my $outfile_name = OUTFILE_NAME;
    open (OFH, ">$outfile_name") or die ("Failed to open file $outfile_name for writing!");
    binmode (OFH);

    my $len = @$dictionary_bytes;
    my $out_buffer = pack "S<$len", @$dictionary_bytes;
    print OFH $out_buffer;

    $len = @$compressed_bytes;
    $out_buffer = pack "C$len", @$compressed_bytes;
    print OFH $out_buffer;

    close (OFH);
}



sub main {

    my $filename = INFILE_NAME;
    if (0+@ARGV == 1) {
        $filename = $ARGV[1];
    }

    # Read the input file
    print "Read input binary data...\n";
    my $byte_array = read_binary_file($filename);

    if ($DEBUG) {
        print_byte_array($byte_array);
    }

    printf "Reorganizing data of %d bytes...\n", 0+@$byte_array;
    my $room_chunk_array = remap_to_room_chunks($byte_array);

    print "Compressing data...\n";
    my ($indices, $compressed_chunks) = compress_room_chunks($room_chunk_array);

    for (my $index=0; $index<@$indices; $index++) {
        printf "#%d: Index: %d\n", $index, $indices->[$index];
    }

    if ($DEBUG) {
        print_compressed_rooms($compressed_chunks);
    }

    printf "\n Initial compressed array is %d long, with %d indices.\n", 0+@$compressed_chunks, 0+@$indices;
    print "\nCompressing all duplicated rooms...\n";
    my ($dictionary, $optimized_and_compressed_array) = encode_with_dictionary($indices, $compressed_chunks);


    # Do a sanity check of the generation of the dictionary
    if (0+@$dictionary != MAP_HEIGHT*MAP_WIDTH) {
        printf "Dictionary doesn't have %d entries: %d\n", MAP_HEIGHT*MAP_WIDTH, 0+@$dictionary;
    } else {
        printf "Dictionary has %d entries. OK!\n", MAP_HEIGHT*MAP_WIDTH;
    }



    printf "Original size was %d bytes.\n", 0+@$byte_array;
    printf "New compressed array has %d entries, while old array has %d entries.\n", 0+@$optimized_and_compressed_array, 0+@$compressed_chunks;

    # Add offset of the dictionary's length into the dictionary entries
    my $offset = (0+@$dictionary)*2;
    for my $dict_el (@$dictionary) {
        $dict_el += $offset;
    }

    # Check all entries in the compressed data for sanity
    my $x = 0;
    for my $item (@$optimized_and_compressed_array) {
        $x++;
        printf "%03d ", $item if DEBUG;
        print "\n" if ($x % 20 == 0) && DEBUG;
        if ($item > 255) { print "$item is too big at $x!\n"; }
    }
    print "\n";


    # Finally write the file
    write_compressed_file($dictionary, $optimized_and_compressed_array);
}


# Start the script
main();
