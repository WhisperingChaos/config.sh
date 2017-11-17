#!/bin/bash
config_VENDOR_MARK_DETECTOR='^[[:space:]]*#<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+>$'
config_VENDOR_LINENO_DETECTOR='^([[:digit:]])+[ ]'
config_VENDOR_SECTION_DETECTOR='\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\](.*)$'
config_VENDOR_FILE_SCOPE_MARK='||||FILE_SCOPE||||'
config_VENDOR_BASH_SNIPPETS_MARK='[BASH_SNIPPETS]'

config_tree_depth_first(){
	local -r rootDir="$1"

	config_vendor_file_search "$rootDir" \
	| config_vendor_read \
   	| config_vendor_whitespace_exclude \
 	| config_vendor_entry_iterate
}
config_vendor_file_search(){
	local -r rootDir="$1"

	local configPath
	local subDir
	while read -r configPath; do

		if head -n 1 $configPath | config_vendor_banner_detected; then 
			echo "$configPath"			
		fi

		for subDir in $(ls -d "$vendorDir/"*/ 2>/dev/null); do
			config_vendor_file_search "$subDir"
		done
	done < <( ls "$rootDir/vendor.config" 2>/dev/null )
}
config_vendor_banner_detected(){

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
config_vendor_read(){

	local vendorFilePath
	while read -r vendorFilePath; do
		if ! [ -s "$vendorFilePath" ]; then
			continue
		fi
		echo "$config_VENDOR_FILE_SCOPE_MARK"'unset vendorDir; local -r vendorDir='"'$(dirname "$vendorFilePath")'"';'
		cat $vendorFilePath
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
	config_section_default_bash_component 'sectionDefs'

	local -r markLen=${#config_VENDOR_FILE_SCOPE_MARK}
	local pasStrip
	local pasWildcards
	local stripCurr
	local wildcardsCurr
	local lineNum
	local entry
	while read -r entry; do
		if [ "${entry:1:$markLen}" == "$config_VENDOR_FILE_SCOPE_MARK" ]; then
			# extract file scope variables
			entry=${entry:$markLen}
			# declare file level variables and extablish their values
			eval $entry
			continue
		fi
		if [[ "$entry" =~ ${config_VENDOR_LINENO_DETECTOR}(.+) ]]; then
			config_msg_error "'internal line number missing - error in program' vendorDir='$vendorDir' lineNum='$lineNum' entry='$entry'"
			exit 1
		fi
		lineNum="${BASH_REMATCH[1]}"
		entry="${BASH_REMATCH[2]}"
		if [[ "$entry" =~ ^($config_VENDOR_BASH_SNIPPETS_MARK)(.*) ]]; then
			# extract bash snippets - hopefully only environment variable declarations
			entry=${BASH_REMATCH[2]}
			# execute bash snippets - variable declarations and extablish their values
			# since arbitary bash code executing here, it can cause all types of issues
			# but flexibility to define variables and values that can be reused when
			# defining a column's values is too inticing
			eval $entry
			if [ "$?" -ne 0 ]; then
				config_msg_error "'error(s) while processing [BASH_SNIPPETS]'" \
				" vendorDir='$vendorDir' lineNum='$lineNum' entry='$entry'"
				exit 1
			fi
			continue
		fi
		if [[ "$entry" =~ ^$config_VENDOR_SECTION_DETECTOR ]]; then
			if ! config_section_definition "$entry" 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'; then
				config_msg_error "'error(s) while processing section definition' vendorDir='$vendorDir' lineNum='$lineNum'"
				exit 1
			fi
			stripCurr="$pasStripVal"
			wildcardsCurr="$pasWildcardsVal"
			continue
		fi
		eval set -- $entry
		if [ "$#" -ne "3" ]; then 
			cofig_msg_error "'expecting exactly three columns:" \
			" Relative Path, Github Repro Download URL, Version'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' actualColms='$#' entry='$entry'"
			continue
		fi	
		if ! config_install "$1" "$2" "$3" "$vendorDir" "$stripCurr" "$wildcardsCurr"; then
			config_msg_error "'component install failed'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' relPath='$1' repo='$2'"   \
		   	" version='$3' vendorDir='$vendorDir' strip='$stripCurr' wildcards='$wildcardsCurr'"
		fi
	done
}
config_section_default_bash_component(){
	local rtnSectionDefs="$1"

	local stripVal
	local wildcardsVal

	local sectionDefault="[whsiperingchaos.bash.component] --strip-component 2 --wildcard '*/component'"
	if ! eval config_section_settings_extract \"\$sectionDefault\" \'$rtnSectionDefs\' \'stripVal\' \'wildcardsVal\'; then
		config_msg_error "Failed to parse default section settings='$sectionDefault'"
		exit 1
	fi
}
config_section_settings_extract(){
	local -r sectionDefMaybe="$1"
	local -r rtnSectionDefs="$2"
	local -r rtnStripVal="$3"
	local -r rtnWildcardsVal="$4"

	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal
	if ! eval config_section_parse "$sectionDefMaybe" 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'; then
		false
		return
	fi
	local sectionDef
	if  [ "$pasStripIs" == 'true' ]; then
		if ! [[ "$pasStripVal" =~ ^0|^[1-9]+[[:isdigit:]]* ]]; then
			config_msg_error "'invalid tar --strip-component value - should be positive integer' value='$pasStripVal'"
			false
			return
		fi
		sectionDef='local -ri stripDefVal='"$pasStripVal\;"
	fi
	if [ "$rtnWildcardIs" == 'true' ]; then
		sectionDef="$sectionDef"'local -r wildcardsDef='"'$pasWildcardsVal';"
	fi
	if [ -z "$sectionDef" ]; then
		# nothing defined by section :: check for prior definition
		eval sectionDef=\"\$\{$rtnSectionDefs\[\$sectionNm\]\"
	else
		# define new or replace existing section
		# a section without variable values isn't stored
		eval \$\{$rntSectionDefs\[\$sectionNm\]\"\=\"\$sectionDef\"
	fi
	# either no prior definition or a definition that has variables
	# no prior definition assume no strip or wildcards
	# locally expose strip and wildcards variables, if they exist 
	eval $sectionDef
	
	unset pasStripVal
	eval $rtnStripVal=\"\$stripDefVal\"
	unset pasWildcardsVal
	eval $rtnWildcardVal=\"\$wildcardsDefVal\"
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
	eval set -- $opts
	while [[ $# -gt 0 ]]; do
		shiftCnt=2
		optVal="$2"
		if [ "${2:1:2}" == '--' ]; then
			# only options start with --
			shiftCnt=1
			optVal=""
		fi	   
		case $1 in
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
	eval $rntWildcardsVal=\"\wildcardsVal\"
	true
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
		tarOpts=' --strip-component='"$stripVal"
	fi
	if [ -n "$wildcardsVal" ]; then
		tarOpts=$tarOpts' --wildcards '"'$wildcardsVal'"
	fi

	local -r repoPath="$vendorDir/$relPath"
	mkdir -p  "$repoPath"

	wget -O - "$repo/tarball/$ver" | eval tar \-xz \-C \"\$repoPath\" $tarOpts
}
config_msg_error() {
	# due to bootstrap nature of config, better to replicate code than include it
	echo "error: msg='$1' func_name='${FUNCNAME[1]}' line_no=${BASH_LINENO[1]} source_file='${BASH_SOURCE[1]}' time='$(date --iso-8601=ns)'" >&2
}
