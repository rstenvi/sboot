#!/bin/bash
# Copy a file onto a disk

FS="none"
disk="floppy.img"
dir="/boot"
mount="mnt"
offset=0
files=()


function usage()	{
	echo "Usage: $0 [noe]"
}


while [ "$1" != "" ]; do
	case $1 in
		-d | --disk )   shift
		                disk=$1
							 ;;
		-r | --dir )    shift
		                dir=$1
							 ;;
		-f | --fs )     shift
		                FS=$1
							 ;;
		-h | --help )   usage
		                exit 0
							 ;;
		* )             files+=("$1")
		                
	esac
	shift
done


case $FS in
	"ext2" )   mkdir -p $mount
	           sudo mount -o loop,offset=$offset $disk $mount
	           mkdir -p $mount$dir
				  for file in ${files[*]}; do
                 cp -f $file $mount$dir/
				  done
				  sudo umount $mount
	           ;;
	"none" )   for file in ${files[*]}; do
					  dd conv=notrunc bs=1 seek=$offset if=$file of=$disk
					  fsz=$(stat -c%s "$file")
					  offset=$((offset + fsz))
				  done
	           ;;
	* )        usage
	           exit 1
esac


exit 0
