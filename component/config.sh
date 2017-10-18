#!/bin/bash
# separate functions so they can be tested but due
# to bootstrap constraint, include must be in same
# physical directory as this command (component).
source "$(dirname "${BASH_SOURCE[0]}")"/config.include.sh

main(){
	local -r myRoot="$1"
	# minimally compose myself
	config_myself "$myRoot"
	if ! [ -d "$myRoot/composer" ]; then
		# stop when executing myself to compose myself
	   	return
   	fi
	# now fully compose myself because others are using me to
	# compose themselves
	for mod in $( "$myRoot/composer/composer.sh" "$myRoot"); do
		source "$mod"
	done
}

main "$(dirname ${BASH_SOURCE[0]})"

