#!/bin/bash
config_VENDOR_MARK_DETECTOR='^#<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+>$'
config_VENDOR_LINENO_DETECTOR='^([0-9]+)[\ ]'
config_VENDOR_SECTION_DETECTOR='^\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\][[:space:]]*(.*)$'
config_VENDOR_FILE_SCOPE_MARK='||||FILE_SCOPE||||'

config_vendor_tree_walk(){
	local -r rootDir="$1"

	config_vendor_file_search_depth_first "$rootDir" \
	| config_vendor_read \
   	| config_vendor_whitespace_exclude \
	| config_entry_iterate
}
config_vendor_file_search_depth_first(){
	local -r rootDir="$1"

	local configPath
	local subDir
	while read -r configPath; do

		if head -n 1 $configPath | config_vendor_banner_detected; then 
			echo "cat $configPath"			
		fi
		if head -n 2 $configPath | config_vendor_shebang_detected; then 
			echo "subshell $configPath"			
		fi

		for subDir in $(ls -d "$rootDir/"*/ 2>/dev/null); do
			config_vendor_file_search_depth_first "$subDir"
		done
	done < <( ls "$rootDir/vendor.config" 2>/dev/null )
}
config_vendor_banner_detected(){

	local config
	if ! read -r config; then
		false
		return
	fi
	if ! [[ $config =~ $config_VENDOR_MARK_DETECTOR ]]; then
		false
		return
   	fi
	true
	return
}
config_vendor_shebang_detected(){
	local -r config_VENDOR_SHEBANG_MARK='#!/'
	local -ri shebangLen=${#config_VENDOR_SHEBANG_MARK}
	local config
	if ! read -r config; then
		false
		return
	fi
	if [ ${#config} -lt $shebangLen ] || [ "${config:0:$shebangLen}" != "$config_VENDOR_SHEBANG_MARK" ]; then
		false
		return
	fi
	config_vendor_banner_detected 
}
config_vendor_read(){

	local command
	while read -r command; do
		if ! [[ "$command" =~ ^(cat|subshell)[\ ](.+)$ ]]; then
			config_msg_error "'logic error - malformed command' command='$vendorFilePath'"
			exit 1
		fi
		local commandOp="${BASH_REMATCH[1]}"
		local vendorFilePath="${BASH_REMATCH[2]}"
		echo "$config_VENDOR_FILE_SCOPE_MARK"'local vendorDir='"'$(dirname "$vendorFilePath")'"';'
		if [ "$commandOp" = 'subshell' ]; then
			( "$vendorFilePath" )
		else	
			$command
		fi
	done
}
config_vendor_whitespace_exclude(){

	local -r config_VENDOR_COMMENT_DETECTOR='^[[:space:]]*#.*$'
	local -r config_VENDOR_BLANK_LINE_DETECTOR='^[[:space:]]*$'
	local -ri markLen=${#config_VENDOR_FILE_SCOPE_MARK}
	local -i lineNum=0
	local config
	while read -r config; do
		if [ ${#config} -ge $markLen ] && [ "${config:0:$markLen}" = "$config_VENDOR_FILE_SCOPE_MARK" ]; then
			# forward file scope variables
			echo "$config"
			continue
		fi
		(( lineNum++ ))
		if [[ "$config" =~ $config_VENDOR_COMMENT_DETECTOR|$config_VENDOR_BLANK_LINE_DETECTOR|$config_VENDOR_MARK_DETECTOR ]]; then
		  continue
		fi
		# prefix each remaining config line to provide error location
		echo "$lineNum $config"
	done
}
config_entry_iterate(){

	local -A pasSectionDefs
	config_section_default_bash_component 'pasSectionDefs'

	local -r markLen=${#config_VENDOR_FILE_SCOPE_MARK}
	local pasTarOpts
	local tarOptsCurr
	local lineNum
	local entry
	while read -r entry; do
		if [ ${#entry} -ge $markLen ] && [ "${entry:0:$markLen}" = "$config_VENDOR_FILE_SCOPE_MARK" ]; then
			# extract file scope variables
			entry=${entry:$markLen}
			# declare file level variables and extablish their values
			eval $entry
			continue
		fi
		if ! [[ "$entry" =~ ${config_VENDOR_LINENO_DETECTOR}(.+) ]]; then
			config_msg_error "'internal line number missing - error in program'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' entry='$entry'"
			exit 1
		fi
		lineNum="${BASH_REMATCH[1]}"
		entry="${BASH_REMATCH[2]}"
		if [[ "$entry" =~ $config_VENDOR_SECTION_DETECTOR ]]; then

			if ! config_section_settings_extract "$entry" 'pasSectionDefs' 'pasTarOpts'; then
				config_msg_error "'error(s) while processing section definition'" \
				" vendorDir='$vendorDir' lineNum='$lineNum'"
				exit 1
			fi
			tarOptsCurr="$pasTarOpts"
			continue
		fi
		set -- $entry
		if [ "$#" -ne "3" ]; then 
			config_msg_error "'expecting exactly three columns:" \
			" Relative Path, Github Repro Download URL, Version'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' actualColms='$#' entry='$entry'"
			continue
		fi
		config_install_report "$1" "$2" "$3" "$vendorDir"
		if ! config_install "$1" "$2" "$3" "$vendorDir" "$tarOptsCurr"; then
			config_msg_error "'component install failed'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' relPath='$1' repo='$2'" \
			" version='$3' vendorDir='$vendorDir' tarOpts='$tarOptsCurr"
		fi
	done
}
config_section_default_bash_component(){
	local rtnSectionDefs="$1"

	local pasOptsVal
	local sectionDefault="[whisperingchaos.bash.component] --strip-component=1 --wildcards '*/component'"
	if ! config_section_settings_extract "$sectionDefault" "$rtnSectionDefs" \
	   	'pasOptsVal'; then
		config_msg_error "Failed to parse default section settings='$sectionDefault'"
		exit 1
	fi
}
config_section_settings_extract(){
	local -r sectionDefMaybe="$1"
	local -r rtnSectionDefs="$2"
	local -r rtnTarOpts="$3"

	[[ "$sectionDefMaybe" =~ $config_VENDOR_SECTION_DETECTOR ]] || return
	local -r sectionNm="${BASH_REMATCH[1]}"
	local opts=${BASH_REMATCH[3]}

	if [ -z "$opts" ]; then
		# nothing defined by section :: check for prior definition
		eval opts=\"\$\{$rtnSectionDefs\[\$sectionNm\]\}\"
	else
		# define new or replace existing section
		# a section without variable values isn't stored
		eval $rtnSectionDefs\[\$sectionNm\]\=\"\$opts\"
	fi
	# either no prior definition or a definition that has opts
	# no prior definition assume no opts
	eval $rtnTarOpts\=\"\$opts\"
	true
}
config_install(){
	local -r relPath="$1"
	local -r repo="$2"
	local -r ver="$3"
	local -r vendorDir="$4"
	local -r tarOpts="$5"

	local -r repoPath="$vendorDir/$relPath"
	config_component_download "$repo/tarball/$ver" "$repoPath" "$tarOpts"
}
config_install_report(){
	local -r relPath="$1"
	local -r repo="$2"
	local -r ver="$3"
	local -r vendorDir="$4"

   config_msg_info "Downloading & installing repo='$repo'"  \
	  " ver='$3' to directory='$vendorDir/$relPath'"
} 
config_component_download(){
	local -r repoVerUrl="$1"
	local -r componentLocalPath="$2"
	local -r tarOpts="$3"

	if ! mkdir -p  "$componentLocalPath"; then
		config_msg_error "'failed to create local path'" \
		" componentLocalPath='$componentLocalPath'"
		return 1
	fi
	wget --dns-timeout=5 --connect-timeout=10 --read-timeout=60 -O -  "$repoVerUrl" 2>/dev/null | eval tar \-xz \-C \"\$componentLocalPath\" $tarOpts \2\>\/dev\/null
	[[ "${PIPESTATUS[0]}" && "${PIPESTATUS[1]}" ]]
}
config_msg_error() {
	# due to bootstrap nature of config, better to replicate code than include it
	# therefore, it doesn't include the 'msg_' package
	local msg
	while [[ $# -gt 0 ]]; do
		msg=$msg$1
		shift
	done
	echo "error: msg='$msg' func_name='${FUNCNAME[1]}' line_no=${BASH_LINENO[1]} source_file='${BASH_SOURCE[1]}' time='$(date --iso-8601=ns)'" >&2
}
config_msg_info(){
	
	local msg
	while [[ $# -gt 0 ]]; do
		msg=$msg$1
		shift
	done

	echo "info: msg='$msg'" 
}
