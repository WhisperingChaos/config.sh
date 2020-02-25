#!/bin/bash
###############################################################################
#
#	Purpose:
#		- An executable interface for the function'config_vendor_tree_walk' located
#		  in this executable's 'base' directory in the package 'config.source.sh'.
#		  Please read its documentation.
#
###############################################################################


configSh__visit_filepath_echo(){
	local -r sourcePath="$1"

	local incDir
	# intentionally using the collating sequence guaranteed by ls
	# as it enforces a loading precedence.  This precedence confers
	# a deterministic outcome for overridden elements, like functions.
	for incDir in $( ls -1 "$sourcePath/"*.source.sh ); do
		echo "$incDir"
	done
}


configSh__option_process(){
	local opt="$1"

	case $opt in
		(-h|--help)
		configSh__help_doc
		;;
		(-v|--version)
		configSh__vendor_version
		;;
		(--sample)
		config_vendor_format_example
		;;
		(--hformat)
		config_vendor_format_help
		;;
		*)
		return 1
	esac
	return 0
}


configSh__help_doc(){
	cat <<CONFIGSH__HELP_DOC
usage: config.sh [OPTION] [ARGUMENT]

Search for and download components defined in a 'vendor.config' file.
Save each downloaded file to its specified directory.  Perform this process
for the provided directory and recursively dive deeply into each of
its subdirectories. 

OPTION:

  --sample     Display sample 'vendor.config' file & exit.
  --hformat    Display explaination of 'vendor.config' format & exit.
  -h,--help    Display help & exit.
  -v,--version Display version information & exit.

ARGUMENT:

  <FilePath>  A file path that identifies the root directory to begin
              searching for a 'vendor.config'.  If unspecified, the
              process begins with the current working directory
              path (\$PWD):$PWD.
CONFIGSH__HELP_DOC
}
	

configSh__version(){
	local opt="$1"

	if ! [[ "$opt" =~ ^(-v|--version)$ ]]; then
		return 1
	fi

	configSh__vendor_version
	return 0
}


configSh__vendor_version(){
	echo version: v1.0
}


configSh__root_dir_exist_error(){
	local -r rootBad="$1"

	config_msg_error 'Cannot access directory: "' "$rootBad" '" either it does not exist or privilege violation occurred.'
}

# main function should be last function so any overridding behavior can be
# applied to the functions defined in this component as the code in main
# reads and incorporates functions from other packages.
main(){
	local -r rootDir="${1:-$PWD}"

	# identify the actual directory location of this executable's components,
	# as symbolic links may be used to invoke this script
	local -r execDir="$(dirname "$(readlink -f "$0")")"

	# due to bootstrap constraint, config can't execute 'sourcer.source.sh'
	# on itself. therefore, it expects its core packages to exist in its 
	# 'base' subdirectory, subordinate to the actual one containing this
	# script.  These functions and variables defined in these core
	# packages can be overriden by specifying their overridding
	# implementation in packages located in an 'override' directory
	# located in the same directory containing 'base'.  Finally one
	# config.source.sh by creating a subdirectory named 'override'.
	# can use a package to load another package (chained packages)
	# from directory locations outside these directories.
	local mod
	for mod in $( configSh__visit_filepath_echo "$execDir/base" ); do
		if ! source $mod; then 
			return 1
		fi
	done
	if [ -e "$execDir/override" ]; then
		for mod in $( configSh__visit_filepath_echo "$execDir/override" ); do
			if ! source $mod; then 
				return 1
			fi
		done
	fi
	# this executable is now fully configured, begin searching subdirectories
	# for a 'vendor.config' to download and install the components of other scripts
	# defined within this tree.
	if configSh__option_process "$1"; then
		return
	fi

	if ! [ -e "$rootDir" ]; then 
		configSh__root_dir_exist_error "$rootDir"
		return 1
	fi

	config_vendor_tree_walk "$rootDir"
}

main "${@}"
