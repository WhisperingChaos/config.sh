#!/bin/bash
config_VENDOR_MARK_DETECTOR='^[[:space:]]*#\<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+\>$ ]]'
config_VENDOR_LINENO_DETECTOR='^([[:digit:]])+[ ]'
config_VENDOR_SECTION_DETECTOR='\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\](.*)$'
config_vendor_file_search(){
	local -r parentPath="$1"

	local configPath
	local subDir
	while read -r configPath; do
		local vendorDir="$(dirname $configPath)"

		if head -n 1 $configPath | config_vendor_detected; then 
			cat $configPath | config_vendor_whitespace_exclude | config_vendor_path_append "$vendorDir"
		fi

		for subDir in $(ls -d "$vendorDir/"*/ 2>/dev/null); do
			config_vendor_file_search "$subDir"
		done
	done < <( ls "$parentPath/vendor.config" 2>/dev/null )
}

config_vendor_detected(){

	local config
	if read -r config; then
		if [[ $config =~ $config_VENDOR_MARK_DETECTOR ]]; then
			true
			return
   		fi
	fi
	false
	return
}

config_vendor_whitespace_exclude(){

	local -r config_VENDOR_COMMENT_DETECTOR='^[[:space:]]*# ]]'
	local -r config_VENDOR_BLANK_LINE_DETECTOR='^[[:space:]]*$ ]]'
	local -i lineNum=0
	local config
	while read -r config; do
		(( lineNum++ ))
		if [[ $config =~ $config_VENDOR_COMMENT_DETECTOR|$config_VENDOR_BLANK_LINE_DETECTOR|$config_VENDOR_MARK_DETECTOR ]]; then
		  continue
		fi
		# prefix each remaining config line to provide error location
		echo "$lineNum $config"
	done
}

config_vendor_path_append(){
	local -r vendorDir="$1"

	local config
	while read -r config; do
		if ! [[ config =~ ${config_VENDOR_LINENO_DETECTOR}$config_VENDOR_SECTION_DETECTOR ]]; then
			config="$config '$vendorDir'"
		fi
		echo "$config"
	done
}

config_myself(){
	local -r parentPath="$1"
	config_vendor_file_search "$parentPath" |
   	| config_vendor_whitespace_exclude | config_vendor_path_append "$vendorDir"
 config_setting_iterate
}

config

config_setting_iterate(){
	local -A sectionStripWc
	local sectionDefault="[whsiperingchaos.bash.component] --strip-component 2 --wildcard '*/component'"
	if ! config_section_found "$sectionDefault" 'rtnSectionNm' 'rtnStrip' 'rtnWildcards'; then
		config_msg_error "Failed to parse default section settings='$sectionDefault'"
		exit 1
	fi

	local rtnStrip
	local rtnWildcards
	local stripCurr=
	local wildcardsCurr
	local lineNum
	local entry
	while read -r entry; do
		if [[ $entry =~ ${config_VENDOR_LINENO_DETECTOR}(.+) ]]; then
			config_msg_error "'internal line number missing - error in program' lineNum='$lineNum' entry='$entry'"
			exit 1
		fi
		lineNum="${BASH_REMATCH[1]}"
		entry="${BASH_REMATCH[2]}"
		if [[ $entry =~ ^$config_VENDOR_SECTION_DETECTOR ]]; then
			if ! config_section_definition "$entry" 'rtnSectionNm' 'rtnStripVal' 'rtnWildcardsVal'; then
				config_msg_error "'error(s) while processing section definition' lineNum='$lineNum'"
				exit 1
			fi	
			stripCurr="$rtnStripVal"
			wildcardsCurr="$rtnWildcardsVal"
			continue;
		fi
		eval set -- $entry
		config_setting_validate "$1" "$2" "$3" "$4" 
		if ! config_install "$1" "$2" "$3" "$4" "$stripCurr" "$wildcardsCurr"; then
			config_msg_error "'component install failed' lineNum='$lineNum' relPath='$1' repo='$2' version='$3' vendorDir='$4' strip='$stripCurr' wildcards='$wildcardsCurr'"
		fi
	done
}
config_section_Detect(){
	local -r entry="$1"
	[[ $entry =~ ^\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\](.*)$ ]] && return
}
config_section_settings_get(){

	if ! config_section_extract "$entry" 'rtnSectionNm' 'rtnStripIs' 'rtnStripVal' 'rtnWildcardsIs' 'rtnWildcards'; then
		false
		return
	fi
	local entryDef

	while [ "$rtnStripIs" == 'true' ]; do
	
		if ! [[ "$rntStripVal" =~ ^0|^[1-9]+[[:isdigit:]]* ]]; then
			config_msg_error "'invalid tar --strip-component value - should be positive integer' value='$rntStripVal'"
			break
		fi
		entryDef='local -r stripDef='"$rtnStripVal\;"
		break
	done
	if [ "$rtnWildcardIs" == 'true' ]; then
		entryDef="$entryDef"'local -r wildcardsDef='"$rtnWildcardVal;"
	fi

	if [ -z "$entryDef" ]; then
		# nothing defined by section :: check for prior definition
		eval entryDef=\"\$\{$sectionDefs\[\$sectionNm\]\"
	else
		# define new or replace existing section
		eval \$\{$sectionDefs\[\$sectionNm\]\"\=\"\$entryDef\"
	fi
	eval $entryDef
	





	

		local tarstripvalue='

		config_section_validate  "$rtnStrip" "$rtnWildcards" 'sectionStripWc' \
				&& config_section_

config_section_extract(){
	local -r entry="$1"
	local -r sectionNm="$2"
	local -r Strip="$3"
	local -r Wildcards="$4"

	[[ $entry =~ $config_VENDOR_SECTION_DETECTOR ]] || return
	eval $sectionNm\=\"\$\{BASH_REMATCH\[1\]\}\"
	local -r opts=${BASH_REMATCH[3]}
	
	eval set -- $opts
	while [[ $# -gt 0 ]]; do
		case $1 in
			--strip-component)
			eval $Strip\=\"\$2\"
			;;
			--wildcards)
			eval $Wildcards\=\"\$2\"
			;;
			*)
			config_msg_error "Unknown section option='$1'"
			false
	   		return	   
		esac
		shift 2
	done
	true
}

config_section_define(){
	local entry="$1"
	local Strip="$2"
	local Wildcards="$3"
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

# due to bootstrap nature of config, better to replicate code than include it
config_msg_error() {
	echo "error: msg='$1' func_name='${FUNCNAME[1]}' line_no=${BASH_LINENO[1]} source_file='${BASH_SOURCE[1]}' time='$(date --iso-8601=ns)'" >&2
}
