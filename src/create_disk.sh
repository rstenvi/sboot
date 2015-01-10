#!/bin/bash
# Script to create a supported disk type with a supported file system.

# Default is a floppy without file system
dtype="floppy"
KB=1440
FS="none"
output="floppy.img"


function usage()	{
	echo "Usage: $0 [-d floppy|ata] [-s KB] [-f none|ext2] [-o output]"
}


while [ "$1" != "" ]; do
	case $1 in
		-d | --disk )   shift
		                dtype=$1
							 ;;
		-s | --size )   shift
		                KB=$1
							 ;;
		-f | --fs )     shift
		                FS=$1
							 ;;
		-o | --output ) shift
		                output=$1
							 ;;
		-h | --help )   usage
		                exit 0
							 ;;
		* )             usage
		                exit 1
	esac
	shift
done


dd if=/dev/zero of=$output bs=1024 count=$KB
case $FS in
	"ext2" )   mke2fs -F $output
	           ;;
	"none" )   ;;
	* )        usage
	           exit 1
esac


exit 0
