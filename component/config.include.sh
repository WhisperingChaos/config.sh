#!/bin/bash
config_VENDOR_MARK_DETECTOR='^[[:space:]]*#<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+>$'
config_VENDOR_LINENO_DETECTOR='^([0-9]+)[\ ]'
config_VENDOR_SECTION_DETECTOR='^\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\](.*)$'
config_VENDOR_FILE_SCOPE_MARK='||||FILE_SCOPE||||'

config_vendor_tree_walk(){
	local -r rootDir="$1"

	config_vendor_file_search_depth_first "$rootDir" \
	| config_vendor_read \
   	| config_vendor_whitespace_exclude \
 	| config_vendor_entry_iterate
}
config_vendor_file_search_depth_first(){
	local -r rootDir="$1"

	local configPath
	local subDir
	while read -r configPath; do

		if head -n 1 $configPath | config_vendor_banner_detected; then 
			echo "cat $configPath"			
		fi
		if head -n 2 $configPath | config_vendor_shell_detected; then 
			echo "subshell $configPath"			
		fi

		for subDir in $(ls -d "$vendorDir/"*/ 2>/dev/null); do
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
config_vendor_shell_detected(){
	local -r config_VENDOR_BASH_DETECTOR='^\#\!/bin/bash([[:space:]]+.*$|$)'
	local -r config_VENDOR_SH_DETECTOR='^\#\!/bin/sh([[:space:]]+.*$|$)'
	local config
	if ! read -r config; then
		false
		return
	fi
	if ! [[ "$config" =~ $config_VENDOR_BASH_DETECTOR|$config_VENDOR_SH_DETECTOR ]]; then
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
		echo "$config_VENDOR_FILE_SCOPE_MARK"'unset vendorDir; local -r vendorDir='"'$(dirname "$vendorFilePath")'"';'
		if [ "$commandOp" == 'subshell' ]; then
			( "$vendorFilePath" )
		else	
			$command
		fi
	done
}
config_vendor_whitespace_exclude(){

	local -r config_VENDOR_COMMENT_DETECTOR='^[[:space:]]*#.*$'
	local -r config_VENDOR_BLANK_LINE_DETECTOR='^[[:space:]]*$'
	local -r markLen=${#config_VENDOR_FILE_SCOPE_MARK}
	local -i lineNum=0
	local config
	while read -r config; do
		if [ "${config:1:$markLen}" == "$config_VENDOR_FILE_SCOPE_MARK" ]; then
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
	local pasStrip
	local pasWildcards
	local stripCurr
	local wildcardsCurr
	local lineNum
	local entry
	while read -r entry; do
		if [ "${entry:0:$markLen}" == "$config_VENDOR_FILE_SCOPE_MARK" ]; then
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
			if ! config_section_settings_extract "$entry" 'pasSectionDefs' \
			   	'pasStripVal' 'pasWildcardsVal'; then
				config_msg_error "'error(s) while processing section definition'" \
				" vendorDir='$vendorDir' lineNum='$lineNum'"
				exit 1
			fi
			stripCurr="$pasStripVal"
			wildcardsCurr="$pasWildcardsVal"
			continue
		fi
		set -- $entry
		if [ "$#" -ne "3" ]; then 
			config_msg_error "'expecting exactly three columns:" \
			" Relative Path, Github Repro Download URL, Version'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' actualColms='$#' entry='$entry'"
			continue
		fi	
		if ! config_install "$1" "$2" "$3" "$vendorDir" "$stripCurr" "$wildcardsCurr"; then
			config_msg_error "'component install failed'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' relPath='$1' repo='$2'" \
			" version='$3' vendorDir='$vendorDir' strip='$stripCurr' wildcards='$wildcardsCurr'"
		fi
	done
}
config_section_default_bash_component(){
	local rtnSectionDefs="$1"

	local pasStripVal
	local pasWildcardsVal
	local sectionDefault="[whisperingchaos.bash.component] --strip-component 2 --wildcards '*/component'"
	if ! config_section_settings_extract "$sectionDefault" "$rtnSectionDefs" \
	   	'pasStripVal' 'pasWildcardsVal'; then
		config_msg_error "Failed to parse default section settings='$sectionDefault'"
		exit 1
	fi
}
config_section_settings_extract(){
	local -r sectionDefMaybe="$1"
	local -r rtnSectionDefs="$2"
	local -r rtnStripVal="$3"
	local -r rtnWildcardsVal="$4"

	local paspasStripVal
   	local paspasWildcardsVal
	if ! config__section_settings_extract "$sectionDefMaybe" "$rtnSectionDefs" \
	   	'paspasStripVal' 'paspasWildcardsVal'; then
		return 1
	fi
	eval $rtnStripVal\=\"\$paspasStripVal\"
	eval $rtnWildcardsVal\=\"\$paspasWildcardsVal\"
}
config__section_settings_extract(){
	local -r sectionDefMaybe="$1"
	local -r rtnSectionDefs="$2"
	local -r rtnStripVal="$3"
	local -r rtnWildcardsVal="$4"

	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal
	if ! config_section_parse "$sectionDefMaybe" 'pasSectionNm' 'pasStripIs' \
	   	'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'; then
		false
		return
	fi
	local sectionDef
	if  [ "$pasStripIs" == 'true' ]; then
		if ! [[ "$pasStripVal" =~ ^0$|^[1-9]+[0-9]* ]]; then
			config_msg_error "'invalid tar --strip-component value" \
			" - should be positive integer' value='$pasStripVal'"
			false
			return
		fi
		sectionDef='local -ri stripDefVal='"$pasStripVal"';'
	fi
	if [ "$pasWildcardsIs" == 'true' ]; then
		local wildcardsVal="$pasWildcardsVal"
		config_single_quote_encapsulate 'wildcardsVal'
		sectionDef="$sectionDef"'local -r wildcardsDefVal='"$wildcardsVal"';'
	fi
	if [ -z "$sectionDef" ]; then
		# nothing defined by section :: check for prior definition
		eval sectionDef=\"\$\{$rtnSectionDefs\[\$pasSectionNm\]\}\"
	else
		# define new or replace existing section
		# a section without variable values isn't stored
		eval $rtnSectionDefs\[\$pasSectionNm\]\=\"\$sectionDef\"
	fi
	# either no prior definition or a definition that has variables
	# no prior definition assume no strip or wildcards
	# locally expose strip and wildcards variables, if they exist
	eval $sectionDef

	eval $rtnStripVal\=\"\$stripDefVal\"
	eval $rtnWildcardsVal\=\"\$wildcardsDefVal\"
	true
}
config_section_parse(){
	local -r sectionDef="$1"
	local -r rtnSectionNm="$2"
	local -r rntStripIs="$3"
	local -r rntStripVal="$4"
	local -r rntWildcardsIs="$5"
	local -r rntWildcardsVal="$6"

	local sectionNm
	[[ "$sectionDef" =~ $config_VENDOR_SECTION_DETECTOR ]] || return
	sectionNm="${BASH_REMATCH[1]}"
	local -r opts=${BASH_REMATCH[3]}
	local stripIs='false'
	local stripVal
	local wildcardsIs='false'
	local wildcardsVal
	local shiftCnt
	local optVal
	set -- $opts
	while [[ $# -gt 0 ]]; do
		shiftCnt=1
		optVal="$2"
		if [ "${2:0:2}" == '--' ]; then
			# only options start with --
			optVal=""
		elif [[ $# -gt 1 ]]; then
			# prevent wrap around to start
			shiftCnt=2
		fi	   
		case "$1" in
			--strip-component)
			stripIs='true'
			stripVal="$optVal"
			;;
			--wildcards)
			wildcardsIs='true'
			wildcardsVal="$optVal"
			;;
			*)
			config_msg_error "Unknown section option='$1'"
			false
	   		return	   
		esac
		shift $shiftCnt 
	done

	eval $rtnSectionNm=\"\$sectionNm\"
	eval $rntStripIs=\"\$stripIs\"
	eval $rntStripVal=\"\$stripVal\"
	eval $rntWildcardsIs=\"\$wildcardsIs\"
	eval $rntWildcardsVal=\"\$wildcardsVal\"
	true
}
config_single_quote_encapsulate(){
	eval local value=\"\$$1\"
	value=${value//\'/\'\"\'\"\'}
	eval $1=\"\'\$value\'\"
}
config_install(){
	local -r relPath="$1"
	local -r repo="$2"
	local -r ver="$3"
	local -r vendorDir="$4"
	local -r stripVal="$5"
	local -r wildcardsVal="$6"

	local tarOpts
	if [ -n "$stripVal" ]; then
		tarOpts='--strip-component='"$stripVal"
	fi
	if [ -n "$wildcardsVal" ]; then
		tarOpts=$tarOpts' --wildcards '"$wildcardsVal"
	fi

	local -r reproPath="$vendorDir/$relPath"

	config_component_download "$repo/tarball/$ver" "$reproPath" "$tarOpts"
}
config_component_download(){
	local -r repoVerUrl="$1"
	local -r componentLocalPath="$2"
	local -r tarOpts="$3"

	if mkdir -p  "$componentLocalPath"; then
		config_msg_error "'failed to create local path'" \
		" componentLocalPath='$componentLocalPath'"
		return 1
	fi
	wget -O - "$repoVerUrl" | eval tar \-xz \-C \"\$componentLocalPath\" $tarOpts
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
