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
		configSh__version
		;;
		(--sample)
		config_vendor_format_example
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
  -h,--help    Display help & exit.
  -v,--version Display version information & exit.

ARGUMENT:

  <FilePath>  A file path that identifies the root directory to begin
              searching for a 'vendor.config'.  If unspecified, the
              process begins in the directory containing the config.sh
              script.  Promotes installing config.sh to <FilePath>.
              Moreover, encourages using symbolic links to a single 
              copy of config.sh in projects containing many
              configurable components as a means of specifying the
              <FilePath> without having to provide it as a parameter.
              For this invocation the <FilePath> would
              be: '$(dirname "$0")'.

Visit: https://github.com/WhisperingChaos/config.sh#configsh for further
information and to report bugs.
CONFIGSH__HELP_DOC
}
	

configSh__version(){
	local -r configSh__vendor_version='v1.3'
	echo "version: $configSh__vendor_version"
}


configSh__root_dir_exist_error(){
	local -r rootBad="$1"

	configSh__msg_error 'Cannot access directory: "' "$rootBad" '" either it does not exist or privilege violation occurred.'
}


configSh__msg_error() {
	local msg
	while [[ $# -gt 0 ]]; do
		msg=$msg$1
		shift
	done
	echo "error: msg='$msg' func_name='${FUNCNAME[1]}' line_no=${BASH_LINENO[1]} source_file='${BASH_SOURCE[1]}' time='$(date --iso-8601=ns)'" >&2
}


# main function should be last function so any overridding behavior can be
# applied to the functions defined in this component as the code in main
# reads and incorporates functions from other packages.
main(){
	local -r rootDir="${1:-$(dirname "$0")}"

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
	for mod in $( configSh__visit_filepath_echo "$execDir/config_sh/base" ); do
		if ! source $mod; then 
			return 1
		fi
	done
	if [ -e "$execDir/override" ]; then
		for mod in $( configSh__visit_filepath_echo "$execDir/config_sh/override" ); do
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
