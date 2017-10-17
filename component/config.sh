#!/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")"/config.include.sh

config_compose(){
	# minimally compose myself
	local -r myRoot="$(dirname ${BASH_SOURCE[0]})"
	config_myself "$myRoot"
	# now fully compose myself
	for mod in $( "$myRoot/composer/include.composer.sh" "$myRoot"); do
		source "$mod"
	done

# path_Set "${myRoot}" 
}

main_call(){
	echo "path $1"
}
set -ex
# compose myself
config_compose
# compose others
# main_call
