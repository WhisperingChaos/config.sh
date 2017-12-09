#!/bin/bash
main(){
	local -r projRoot="$1"
	set -e
	local -r repo='https://github.com/WhisperingChaos/config.sh' 
	local -r ver='master' 
	local -r repoVerUrl="$repo"'/tarball/'"$ver"
	if ! [ -d "./config.sh" ]; then 
		mkdir ./config.sh
	fi
	wget --dns-timeout=5 --connect-timeout=10 --read-timeout=60 -O -  "$repoVerUrl" \
	| tar -xz -C ./config.sh --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component/'
	./config.sh/config.sh 
}
main "`pwd`"
