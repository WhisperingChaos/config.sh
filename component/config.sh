#!/bin/bash
# due to bootstrap constraint, config can't execute source
# on itself yet. therefore, it expects its core functions 
# are located in the 'base' subdirectory containing config.sh.
# Note - may implement similar workaround used by sourcer
# that refers to override directory that references 
# base/config.source.sh so its contents can be overwirtten
# using a simpler solution than the one provided by the sourcer
source "$(dirname "${BASH_SOURCE[0]}")"/base/config.source.sh

main(){
	# identifies the root directory of the component(s) needing configuration
	local -r rootDir="$1" 
	if ! [ -d "$rootDir" ]; then
		false
		return
	fi
	# before building the component(s) configure myself
	local -r rootDirForConfig="$(dirname "${BASH_SOURCE[0]}")"
	config_vendor_tree_walk "$rootDirForConfig"
	# now fully source myself because others are using me to
	# source themselves
	for mod in $( "$rootDirForConfig"/sourcer/sourcer.sh "$myRoot"); do
		source "$mod"
	done
	# config all component(s) specified by any vendor.config file
	# defined within this tree.
	config_vendor_tree_walk "$rootDir"
}
main  "${@}"

