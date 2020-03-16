#!/bin/bash
###############################################################################
#
#	Purpose
#		Bootstrap mechanism to download and run config.sh.
#
#	In
#		BASH_SOURCE[0] - (Required) Directory containing or symbolic link to this script. 
#		$1 - (Optional) Version of config.sh to use. Defaults to 'master'
#		$2 - (Optional) Install directory path for config.sh. Defaults to a 
#		     subdirectory called 'config_sh' whose parent is the directory
#		     containing the script or directory from a symbolic link.  If the
#		     install doesn't exist, its created.
#		$3 - (Optional) Directory path to vendor fiile.  Defaults to
#		     "$2/vendor".
#
###############################################################################
main(){
	local -r bootRoot="$(dirname "${BASH_SOURCE[0]}")"
	local -r configVer="${1:-master}"
	local    installPath="$2"
	local 	 vendorPath="$3"

	if [[ -z "$installPath" ]]; then 
		installPath="$bootRoot/config_sh"
	fi

	if ! [[ -d "$installPath" ]]; then 
		mkdir -p "$installPath"
	fi

	if [[ -z "$vendorPath" ]]; then
		vendorPath="$installPath/vendor"
	fi

	local -r repoVerUrl='https://github.com/WhisperingChaos/config.sh/tarball/'"$configVer"
	wget --dns-timeout=5 --connect-timeout=10 --read-timeout=60 -O -  "$repoVerUrl" 2>/dev/null \
	| tar -xz -C $installPath --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component/'

	"$installPath/config.sh" "$vendorPath" 
}

set -e
main "$@"

