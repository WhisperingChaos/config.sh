
#config_vendor(){
#cat <<ConfigSettingsMyself
#'component/pathset'  'git@github.com:WhisperingChaos/BuildConfig.git' 'master'  "$(dirname ${BASH_SOURCE[0]})"
#ConfigSettingsMyself
#}

config_recur(){
	local -r parentPath="$1"
	local configPath
	local subDir
	while read -r configPath; do
		local vendorDir="$(dirname $configPath)"
		cat  "$configPath" | config_recur_vendor_path_append "$vendorDir"
		for subDir in $(ls -d "$vendorDir/*/" 2>/dev/null); do
			config_recur "$subDir"
		done
	done < <( ls "$parentPath/vendor.config" )
}

config_recur_vendor_path_append(){
	local -r vendorDir=$1
	while read -r config; do
		echo "$config $vendorDir"
	done
}
config_myself(){
	local -r parentPath="$1"
#	config_myself_vendor "$parentPath"
#	config_setting_iterate 'config_myself_vendor_closure'
	config_recur_start "$parentPath"
	config_setting_iterate 'config_recur_start_closure'
}
config_myself_vendor(){
	eval config_myself_vendor_closure\(\)\{ local \-r start\=\'$1\'  \; config_recur \"\$start\" \; \}

}

config_setting_iterate(){
	local -r sourceFn="$1"

	while read -r entry; do
		eval set -- $entry
		config_install "$1" "$2" "$3" "$4"
	done < <( $sourceFn )
}

config_recur_start(){
	eval config_recur_start_closure\(\)\{ local \-r start\=\'$1\'  \; config_recur \"\$start\" \; \}
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

	local -r myRoot="$(dirname ${BASH_SOURCE[0]})"
	config_myself "$myRoot"

	for mod in $( "$myRoot/composer/include.composer.sh" "$myRoot"); do
		source "$mod"
	done

	path_Set "${myRoot}" 
}

main_call(){
	echo "path $1"
}
set -ex
# config must first compose a minimal self then continue composing others.
config_compose
main_call
