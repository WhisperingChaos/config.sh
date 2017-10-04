config_vendor_file_search(){
	local -r parentPath="$1"

	local configPath
	local subDir
	while read -r configPath; do
		local vendorDir="$(dirname $configPath)"

		config_vendor_file_echo "$configPath"
		if cat $configPath | config_vendor_file; then 
			cat $configPath | config_vendor_file_entries | config_vendor_path_append "$vendorDir"
		fi

		for subDir in $(ls -d "$vendorDir/*/" 2>/dev/null); do
			config_vendor_file_search "$subDir"
		done
	done < <( $ls "$parentPath/vendor.config" 2>/dev/null )
}

config_vendor_file(){

	local config
	while read -r config; do
		if [[ $config ~= ^[:space:]*#<vendor\.config:(alnum][.-])+>$ ]]; then return true; fi
	done
	return false
}

config_vendor_file_entries(){

	local config
	while read -r config; do
		if [[ $config ~= ^[:space:]*# ]]; then continue; fi
		if [[ $config ~= ^[:space:]*$ ]]; then continue; fi
		echo "$config"
	done
}

config_vendor_path_append(){
	local -r vendorDir=$1

	local config
	while read -r config; do
		echo "$config $vendorDir"
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
		config_install "$1" "$2" "$3" "$4"
	done
}

config_install(){
	local -r relPath="$1"
	local -r repro="$2"
	local -r ver="$3"
	local -r parentPath="$4"
	local -r reproPath="$parentPath/$relPath"

	mkdir -p  "$reproPath"
	wget -O - "$repro/tarball/$ver" | tar -xz --strip 1 -C "$reproPath"
}

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
