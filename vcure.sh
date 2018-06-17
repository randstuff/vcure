#!/bin/bash 

RootDir="$HOME/data"
ArchivedDir="archived"
Trash="trash" 

declare -a arr=("btceur" "xrpeur" "ltceur" "etheur")
#declare -a arr=("btceur" "xrpeur") 

shopt -s dotglob

###############################################################################

Collect ()
{
	n=0 
	while [ 42 ]; do 
		for i in "${arr[@]}" ; do 
			GetData $i
			sleep 1
			if ! (( n % 2048)); then 
				Archive
			fi 
			((n++)) 
		done
		sleep 1
	done
}

GetData () 
{
	cDate=`date '+%y%m%d-%H%M%S'`
	mkdir -p $RootDir/$1/
	echo "Current call : https://www.bitstamp.net/api/v2/ticker/$1/"
	echo "Dumped to    : "  $RootDir/$1/$cDate.json
	curl -XGET https://www.bitstamp.net/api/v2/ticker/$1/ >> $RootDir/$1/$cDate.json
	echo "\r" >> $RootDir/$1/$cDate.json 
}

###############################################################################

Archive ()
{
	mkdir ${ArchivedDir} 
	
	for cVirtMoney in "${arr[@]}" ; do 
		
		cDir=$RootDir"/"$cVirtMoney"/"
		echo "Processing "$cVirtMoney " at " $cDir 

		for d in $(ls -f $cVirtMoney | cut -d "-" -f1 | grep -v -E "(\.)|(\..)" | sort -u) ; do 
			cDay=`echo $d | cut -d "/" -f1` 

			cInputPath="./"$cVirtMoney"/"$d
			cOutputPath="./"${ArchivedDir}"/"${cVirtMoney}"/"${cDay}"/"

			mkdir -p $cOutputPath
			mv -vf $cInputPath* $cOutputPath

			echo "  [" $cInputPath"*] files archived at " ${cOutputPath}
		done 
	done
}

###############################################################################

CleanUp ()
{
	for i in "${tmp[@]}" ; do 
		mv $i $Trash
	done 
} 

ReIndex ()
{
	mkdir -p "./"$Trash
	for cVirtMoney in "${arr[@]}" ; do
		mkdir -p "./"$cVirtMoney
	done

	for cVirtMoney in "${arr[@]}" ; do 
		n=0 
		for f in $(find ./$ArchivedDir -name "*.json" ); do 
			echo $f 
			mv $f $RootDir/$cVirtMoney/ 

			tmp[$n]=$f
			if ! (( n % 420)); then 
				CleanUp $tmp
				sleep 180 
			fi 

			((n++)) 
		done 
	done
}

###############################################################################

die()
{
	local _ret=$2
	test -n "$_ret" || _ret=1
	test "$_PRINT_HELP" = yes && print_help >&2
	echo "$1" >&2
	exit ${_ret}
}

begins_with_short_option()
{
	local first_option all_short_options
	all_short_options='th'
	first_option="${1:0:1}"
	test "$all_short_options" = "${all_short_options/$first_option/}" && return 1 || return 0
}

###############################################################################

print_help ()
{
	printf "%s\n" "vcure v0.1 help :   "
	printf 'Usage: %s [option] or [-h|--help]\n' "$0"
	printf "\n" 
	printf "\t%s\n" "-a,--archive: Archive collected data" 
	printf "\t%s\n" "-c,--collect: Collected the data" 
	printf "\t%s\n" "-r,--reindex: Force reindex archived data" 
	printf "\t%s\n" "-h,--help: Prints help"
	printf "\n" 
}

parse_commandline ()
{
	while test $# -gt 0
	do
		_key="$1"
		case "$_key" in
			-a|--archive)
				Archive
				exit 0
				;;
			-c|--collect)
				Collect 
				exit 0
				;;
			-r|--reindex)
				ReIndex
				exit 0
				;;
			-h|--help)
				print_help
				exit 0
				;;
			*)
				_PRINT_HELP=yes die "FATAL ERROR: Got an unexpected argument '$1'" 1
				;;
		esac
		shift
	done
}

parse_commandline "$@"



