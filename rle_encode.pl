#!/usr/bin/perl

use strict;
use warnings;


use constant {
    INFILE_NAME => "aad_map_big.bin",
    OUTFILE_NAME => "aad_map_big.rle",
    MAP_WIDTH => 16,
    MAP_HEIGHT => 12,
    STATE_NEW_BYTE => 0,
    STATE_LOOKAHEAD => 1
};

my $infile_name = INFILE_NAME;
my $outfile_name = OUTFILE_NAME;
my $byte = "";

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

open (IFH, "<$infile_name") or die ("Failed to open $infile_name for reading!");
binmode (IFH);

my @byte_array = ();

while (sysread (IFH, $byte, 1)) {
    my $ord = unpack 'C1', $byte;
    #print "Read: $ord\n";
    push @byte_array, $ord;
}

close (IFH);

my @compressed_array = ();

my $c = 0;
my @bytes = ();
for my $byte (@byte_array) {

    if ($c == 20) {
    for (my $i=0; $i<20; $i++) {
        $bytes[$i] = "0".$bytes[$i] if ($bytes[$i] < 10);
        print $bytes[$i]." ";
    }
    print "\n";
        $c = 0;
        @bytes = ();
    }

    push @bytes, $byte;
    $c++;
}

my $state = STATE_NEW_BYTE;

my $count = 0;
my $last_byte = 0;
my $curr_byte = 0;
my @rooms = ();

printf "Reorganizing data of %d indices...\n", scalar 0+@byte_array;

# Reorganize data by rooms first
my @uncomp_rooms = ();

for(my $y=0; $y<MAP_HEIGHT; $y++) {

    for(my $x=0; $x<MAP_WIDTH; $x++) {

        my @current_room = ();

        for (my $j=0; $j<12; $j++) {

            for (my $i=0; $i<20; $i++) {

                my $idx = 240*$y*MAP_WIDTH+$x*20+$j*MAP_WIDTH*20+$i;
                printf "Setting data [%d,%d] for room at index %d...\n", $i, $j, $idx;
                push @current_room, $byte_array[$idx];
            }
        }

        printf "Added room [%d,%d] at index %d\n", $x, $y, 240*$y*MAP_WIDTH+$x*20;

        push @uncomp_rooms, @current_room;
    }
}

print "Compressing data...\n";

my @indices = ();

# Compress each room, each chunk of compressed rooms will have first byte the length, the rest is (count,value) byte pairs until length is complete.
for (my $j=0; $j<MAP_HEIGHT*MAP_WIDTH; $j++) {
    my @compressed_chunk = ();
    for (my $i=0; $i<240; $i++) { # One room must fit

        $curr_byte = $uncomp_rooms[$j*240+$i];

        if ($state == STATE_NEW_BYTE) {
            $count = 1;
            $last_byte = $curr_byte;
            $state = STATE_LOOKAHEAD;
        } elsif ($state == STATE_LOOKAHEAD) {

            if ($last_byte == $curr_byte) {
                $count++;
            } else {
                push @compressed_chunk, $count, $last_byte;
                $count = 1;
                $last_byte = $curr_byte;
            }
        }
    }
    if ($last_byte == $curr_byte) {
        $state = STATE_NEW_BYTE;
        push @compressed_chunk, $count, $last_byte;
        push @indices, 0+@compressed_array;

        # Compress only if occupies less than original size!
        if (0+@compressed_chunk < 240) {
            push @compressed_array, 0+@compressed_chunk, @compressed_chunk;
        } else {
            push @compressed_array, 0, @uncomp_rooms[$j*240 .. $j*240+239];
        }
    }
}

# Print data on screen
$c = 0;
my $i = 0;
my $j = 0;
my $r = 0;
@bytes = ();
while ($i < @compressed_array) {
    if ($c == 0) {
        $c = $compressed_array[$i];
        if ($c == 0) {
            $i+=240;
        }
        print "\n\nRoom [".int($r % 16).", ".int($r/16)."]\nLength: $c\n";
        $r++;
    } else {
        my $outprint = "";
        $outprint = "0" if ($compressed_array[$i] < 100);
        $outprint = "00" if ($compressed_array[$i] < 10);
        $outprint .= $compressed_array[$i];
        print $outprint . " ";
        $j++;
        if ($j == 20) {
            print "\n";
            $j = 0;
        }
        $c--;
    }
    $i++;
}

printf "\n Initial compressed array is %d long, with %d indices.\n", 0+@compressed_array, 0+@indices;

# Make dictionary of all duplicated rooms 
my @dict = ();
my @compressed_array2 = ();
my $x = 0;
my $str = "";
for my $idx (@indices) {

    #printf "Reading old dictionary at index: %d\n", $idx;

    my $pos = $idx;
    my $pos_len = $compressed_array[$pos];

    # If uncompressed:
    if ($pos_len == 0) {
        $pos_len = 240;
    }
    $pos++;

    #printf "   Found data at index [%d] with length [%d].\n", $idx, $pos_len;

    my $match = 0;
    my @slice1 = @compressed_array[$pos .. ($pos + $pos_len - 1)];

    $str = "";
    for my $item (@slice1) {
        $str .= sprintf("%03d ", $item);
    }
    #print "Slice 1: $str\n";

    for my $idx_look (@dict) {

        #printf "Checking new dictionary for equal chunks at index: %d\n", $idx_look;

        my $pos_look = $idx_look;
        my $look_len = $compressed_array2[$pos_look];
        $pos_look++;

        #printf "   Found data at index [%d] with length [%d].\n", $idx_look, $look_len;

        my @slice2 = @compressed_array2[$pos_look .. ($pos_look + $look_len - 1)];

        $str = "";
        for my $item (@slice2) {
            $str .= sprintf("%03d ", $item);
        }
        #print "Slice 2: $str\n";

        if (&are_equal(\@slice1,\@slice2)) {

            # Add reference to dictionary
            printf "\nSuccessful match of %d bytes at position %d!\n", $look_len, $pos_look;
            printf " >>>>>>>>>>>>>>>>> Set dictionary pos [%d, %d] to refer to repeated position [%d]\n", $x % MAP_WIDTH, int($x/MAP_WIDTH), $idx_look;

            # Push to dictionary
            push @dict, $idx_look;

            $match = 1;
            last;
        }
    }
    if (!$match) {

        # New data? Then push to destination compressed array.
        printf "\nAdding %d items to compressed array\n", 0+@slice1;
        my $new_pos = 0+@compressed_array2;
        push @compressed_array2, $pos_len, @slice1;

        printf " ----- Set dictionary pos [%d, %d] to refer to new position [%d]\n", $x % MAP_WIDTH, int($x/MAP_WIDTH), $new_pos;

        # Push to dictionary
        push @dict, $new_pos;
    }

    $x++;
}

if (0+@dict != MAP_HEIGHT*MAP_WIDTH) {
    printf "Dictionary doesn't have %d entries: %d\n", MAP_HEIGHT*MAP_WIDTH, 0+@dict;
} else {
    printf "Dictionary has %d entries. OK!\n", MAP_HEIGHT*MAP_WIDTH;
}

printf "Original size was %d bytes.\n", 0+@byte_array;
printf "New compressed array has %d entries, while old array has %d entries.\n", 0+@compressed_array2, 0+@compressed_array;

$x = 0;
for my $item (@compressed_array2) {

    $x++;
    #printf "%03d ", $item;
    #print "\n" if ($x % 20 == 0);
    if ($item > 255) { print "$item is too big at $x!\n"; }
}
print "\n";

# Add offset for dictionary
my $offset = (0+@dict)*2;
for my $dict_el (@dict) {
    $dict_el += $offset;
}

open (OFH, ">$outfile_name") or die ("Failed to open file $outfile_name for writing!");
binmode (OFH);

print "Storing dictionary:\n";
my $len = @dict;
print "> Packing $len unsigned words in little endian order...\n";
my $out_buffer = pack "S<$len", @dict;
print OFH $out_buffer;

print "Storing compressed data:\n";
$len = @compressed_array2;
print "> Packing $len characters...\n";
$out_buffer = pack "C$len", @compressed_array2;
print OFH $out_buffer;

close (OFH);
