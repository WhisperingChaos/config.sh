#!/bin/bash
main(){
	local -r projRoot="$1"

	set -e
	local -r repo='https://github.com/WhisperingChaos/config.sh' 
	local -r ver='master' 
	local -r repoVerUrl="$repo"'/tarball/'"$ver"
	local -r configDir='./config' 
	if ! [ -d "$configDir" ]; then 
		mkdir $configDir
	fi
	wget --dns-timeout=5 --connect-timeout=10 --read-timeout=60 -O -  "$repoVerUrl" \
	| tar -xz -C $configDir --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component/'
	$configDir/config.sh "$projRoot" 
}
main "$( dirname "${BASH_SOURCE[0]}" )"
