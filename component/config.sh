#!/bin/bash
# due to bootstrap constraint, config can't execute compose
# on itself yet. therefore, it expects its core functions 
# are located in the 'base' subdirectory containing config.sh.
# Note - may implement similar workaround used by includer
# that refers to override directory that references 
# base/config.include.sh so its contents can be overwirtten
# using a simpler solution than the one provided by the includer
source "$(dirname "${BASH_SOURCE[0]}")"/base/config.include.sh

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
	# now fully compose myself because others are using me to
	# compose themselves
	for mod in $( "$rootDirForConfig"/includer/includer.sh "$myRoot"); do
		source "$mod"
	done
	# config all component(s) specified by any vendor.config file
	# defined within this tree.
	config_vendor_tree_walk "$rootDir"
}
main  "${@}"

