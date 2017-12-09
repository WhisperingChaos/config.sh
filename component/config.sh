#!/bin/bash
# separate functions so they can be tested but due
# to bootstrap constraint, include must be in same
# physical directory as this command (component).
source "$(dirname "${BASH_SOURCE[0]}")"/base/config.include.sh

main(){
	local -r rootDir="$1"

	if [ -z "$rootDir" ]; then
		# minimally configure myself
		config_vendor_tree_walk "$(dirname "${BASH_SOURCE[0]}")"
		return
	fi
	# now fully compose myself because others are using me to
	# compose themselves
	for mod in $( "$myRoot"/composer.sh/composer.sh "$myRoot"); do
		source "$mod"
	done
	# config all components rooted in this tree
	config_vendor_tree_walk "$rootDir"
}

main  "${@}"

