#!/bin/bash
config_vendor_file_search(){
	local -r parentPath="$1"

	local configPath
	local subDir
	while read -r configPath; do
		local vendorDir="$(dirname $configPath)"

		if cat $configPath | config_vendor_file; then 
			cat $configPath | config_vendor_file_entries | config_vendor_path_append "$vendorDir"
		fi

		for subDir in $(ls -d "$vendorDir/"*/ 2>/dev/null); do
			config_vendor_file_search "$subDir"
		done
	done < <( ls "$parentPath/vendor.config" 2>/dev/null )
}

config_vendor_file(){

	local config
	while read -r config; do
		if [[ $config =~ ^[[:space:]]*#\<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+\>$ ]]; then
			true
			return
   		fi
	done
	false
}

config_vendor_file_entries(){

	local config
	while read -r config; do
	if [[ $config =~ ^[[:space:]]*# ]]; then continue; fi
		if [[ $config =~ ^[[:space:]]*$ ]]; then continue; fi
		echo "$config"
	done
}

config_vendor_path_append(){
	local -r vendorDir="$1"

	local config
	while read -r config; do
		echo "$config '$vendorDir'"
	done
}

config_myself(){
	local -r parentPath="$1"
	config_vendor_file_search "$parentPath" | config_setting_iterate
}

config_setting_iterate(){

	local entry
	while read -r entry; do
		eval set -- $entry
		if ! config_install "$1" "$2" "$3" "$4"; then
			echo "type='error' msg='component install failed' relPath='$1' repo='$2' version='$3' vendorDir='$4'" >&2
		fi
	done
}

config_install(){
	local -r relPath="$1"
	local -r repo="$2"
	local -r ver="$3"
	local -r parentPath="$4"
	local -r repoPath="$parentPath/$relPath"

	local -r compWildcard="$(config_component_part "$repo")"'*/component'
	mkdir -p  "$repoPath"
	wget -O - "$repo/tarball/$ver" | tar -xz --strip-component=2 -C "$repoPath" --wildcards $compWildcard
}

config_component_part(){
	local -r repo="$1"

	local -r repoName="$(basename "$repo")"
	local gitUser="$(dirname "$repo")"
	gitUser="$(basename "$gitUser")"
	echo "${gitUser}-${repoName}"
}
