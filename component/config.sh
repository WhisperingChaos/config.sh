#!/bin/bash
# separate functions so they can be tested but due
# to bootstrap constraint, include must be in same
# physical directory as this command (component).
source "$(dirname "${BASH_SOURCE[0]}")"/config.include.sh

main(){
	local -r myRootDir="$1"
	local -r rootDir="$2"
	local -r configMyself="$3"

	# minimally configure myself
	if [ "$configMyself" == 'true' ]; then
		config_myself "$myRootDir"
		return
	fi
	# now fully compose myself because others are using me to
	# compose themselves
	for mod in $( "$myRoot/composer/composer.sh" "$myRoot"); do
		source "$mod"
	done
	# config all components
	config_tree_depth_first "$rootDir"
}

main "$(dirname ${BASH_SOURCE[0]})" "${@}"

