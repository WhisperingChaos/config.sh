#!/bin/bash
###############################################################################
#
#	Purpose:
#		- Dive deep then travel wide to locate 'vendor.config' files within the
#		  provided tree root.
#		- Once found, use the entries in a 'vendor.config' file to download and
#		  save each specified package to its defined directory.  Relative 
#		  directory paths are anchored (relative to) the directory containing
#		  the 'vendor.config'.
#
#	Note:
#		- Before diving deep, check the (first/current) directory for a
#		  'vendor.config' file.  This is intentional, as one could use this
#		  initial instance as a 'boot' file, that downloads and installs
#		  other 'vendor.config' files into the provided tree root.
#		- The directory walk is intentionally ordered by the collating sequence
#		  of directory names.  This sequencing can be leveraged, as already
#		  mention to define a 'boot' 'vendor.config'. It may also order the
#		  overrwiting of files to achieve a specific outcome.
#		- Hidden directories are intentionally ignored.
#		- Currently, the download doesn't maintain a cache, therefore, it simply
#		  transfers another copy from the server offering the component.
#
#	In:
#		- $1  Contains the name of the first directory whose content is searched
#		      for 'vendor.config'.
#		- config__VENDOR_VISIT_LEVEL_MAX defines how deeply to dive before
#		      backtracking to visit other directories.
#		- config__VENDOR_COMPONENTS_PER_LEVEL_MAX	limits the number of 
#		      subdirectories within a given directory that are visited.  
#		      A subdirectory is mapped to the notion of a component :: each
#		      level can define this many components.
#
#	Out:
#		STDOUT - An informational message providing status of each download.
#
###############################################################################
config_vendor_tree_walk(){
	local -r rootDir="$1"

	config__vendor_file_search_depth_first "$rootDir" '0' \
	| config__vendor_read                                 \
	| config__vendor_whitespace_exclude                   \
	| config__entry_iterate
	config__pipe_status_ok "${PIPESTATUS[@]}"
}


config_vendor_format_example(){

	cat <<CONFIG_VENDOR_FORMAT_EXAMPLE
#<vendor.config:${config__VENDOR_CONFIG_SEMANTIC_VERSION}>
# banner above ^
# this is a comment
# section name:
[whisperingchaos.bash.component]
# entry within a section:
# Path            github Address to Repository                           Branch/Tag/Commit Hash
'sourcer'        'https://github.com/WhisperingChaos/sourcer.sh'        'master'
'base'           'https://github.com/WhisperingChaos/assert.source.sh'  'v1.0'

# See Formal Spec: https://github.com/WhisperingChaos/config.sh/blob/$config__COMPONENT_SEMANTIC_VERSION/README.md#vendorconfig

CONFIG_VENDOR_FORMAT_EXAMPLE
}


###############################################################################
#	Private functions - those not directly called by an external package are
#	defined below.  Also, although declared as global variables, the ones defined
# below this banner should, like functions below, be only referenced by functions
#	within this package.  The variables are declared global enabling another
#	package to override their values to adapt behavior without having to 
# physically modify this file.
###############################################################################

declare -g config__COMPONENT_SEMANTIC_VERSION=v1.2
declare -g config__VENDOR_CONFIG_SEMANTIC_VERSION=v1.0
declare -g config__VENDOR_MARK_DETECTOR='^#<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+>$'
declare -g config__VENDOR_LINENO_DETECTOR='^([0-9]+)[\ ]'
declare -g config__VENDOR_SECTION_DETECTOR='^\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\][[:space:]]*(.*)$'
declare -g config__VENDOR_FILE_SCOPE_MARK='||||FILE_SCOPE||||'
declare -gi config__VENDOR_VISIT_LEVEL_MAX=5
declare -gi config__VENDOR_COMPONENTS_PER_LEVEL_MAX=20


config__vendor_file_search_depth_first(){
	local -r rootDir="$1"
	local -ir level=$2+1

	if [[ $level -gt $config__VENDOR_VISIT_LEVEL_MAX ]]; then
		config__vendor_file_search_too_deep_error $config__VENDOR_VISIT_LEVEL_MAX "$rootDir" 
		return 1
	fi

	local -i compPerLevel=0
	local configPath
	local subDir
	while true; do
		configPath="$rootDir/vendor.config"
		while [ -e	"$configPath" ]; do
			if head -n 1 $configPath | config__vendor_banner_detected; then 
				echo "cat $configPath"
				break
			fi
			if head -n 2 $configPath | config__vendor_shebang_detected; then 
				echo "subshell $configPath"
				break
			fi
			break
		done

		for subDir in $(ls -d "$rootDir/"*/ 2>/dev/null); do
			if [[ $((++compPerLevel)) -gt $config__VENDOR_COMPONENTS_PER_LEVEL_MAX ]]; then 
				config__vendor_too_many_components_error "$config__VENDOR_COMPONENTS_PER_LEVEL_MAX" "$subDir"
				return 1
			fi
			if ! config__vendor_file_search_depth_first "$subDir" $level; then 
				return 1
			fi
		done
		return 0
	done
}

config__vendor_file_search_too_deep_error(){
	local -ri levelMax=$1
	local -r subdir="$2"

	config__msg_error 'Attempting to dive into directory: '"'$subdir'"' but its' \
		' depth exceeds maximum level of: '"'$levelMax'"'.' '  If max level too'  \
		' small then increase value of variable config__VENDOR_VISIT_LEVEL_MAX'   \
		' using override mechanism.'
}


config__vendor_too_many_components_error(){
	local -ri compMax=$1
	local -r  subdirStop="$2"

	config__msg_error 'Maximum component count: '"'$compMax'"' exceeded for a given' \
		' level while starting to process directory: '"'$subdirStop'"'.  This and all' \
		' component directories that sort after it were not processed.  If you'    \
		' want to exceed this limit increase the value of variable:'               \
		' '"'config__VENDOR_COMPONENTS_PER_LEVEL_MAX'"'.'
}


config__vendor_banner_detected(){

	local config
	if ! read -r config; then
		return 1
	fi
	if ! [[ $config =~ $config__VENDOR_MARK_DETECTOR ]]; then
		return 1
 	fi
}
config__vendor_shebang_detected(){
	local -r config__VENDOR_SHEBANG_MARK='#!/'
	local -ri shebangLen=${#config__VENDOR_SHEBANG_MARK}
	local config
	if ! read -r config; then
		return 1
	fi
	if [[ ${#config} -lt $shebangLen ]] || [[ "${config:0:$shebangLen}" != "$config__VENDOR_SHEBANG_MARK" ]]; then
		return 1
	fi
	config__vendor_banner_detected 
}
config__vendor_read(){

	local command
	while read -r command; do
		if ! [[ "$command" =~ ^(cat|subshell)[\ ](.+)$ ]]; then
			config__msg_error "'logic error - malformed command' command='$vendorFilePath'"
			return 1
		fi
		local commandOp="${BASH_REMATCH[1]}"
		local vendorFilePath="${BASH_REMATCH[2]}"
		echo "$config__VENDOR_FILE_SCOPE_MARK"'local vendorDir='"'$(dirname "$vendorFilePath")'"';'
		if [[ "$commandOp" = 'subshell' ]]; then
			( "$vendorFilePath" )
		else	
			$command
		fi
	done
}
config__vendor_whitespace_exclude(){

	local -r config__VENDOR_COMMENT_DETECTOR='^[[:space:]]*#.*$'
	local -r config__VENDOR_BLANK_LINE_DETECTOR='^[[:space:]]*$'
	local -ri markLen=${#config__VENDOR_FILE_SCOPE_MARK}
	local -i lineNum=0
	local config
	while read -r config; do
		if [[ ${#config} -ge $markLen ]] && [[ "${config:0:$markLen}" = "$config__VENDOR_FILE_SCOPE_MARK" ]]; then
			# forward file scope variables
			echo "$config"
			continue
		fi
		(( lineNum++ ))
		if [[ "$config" =~ $config__VENDOR_COMMENT_DETECTOR|$config__VENDOR_BLANK_LINE_DETECTOR|$config__VENDOR_MARK_DETECTOR ]]; then
		  continue
		fi
		# prefix each remaining config line to provide error location
		echo "$lineNum $config"
	done
}


config__entry_iterate(){

	local -A pasSectionDefs
	if ! config__section_default_bash_component 'pasSectionDefs'; then
		return 1
	fi

	local -r markLen=${#config__VENDOR_FILE_SCOPE_MARK}
	local pasTarOpts
	local tarOptsCurr
	local lineNum
	local targetPath
	local entry
	local errOccr=0
	while read -r entry; do
		if [[ ${#entry} -ge $markLen ]] && [[ "${entry:0:$markLen}" = "$config__VENDOR_FILE_SCOPE_MARK" ]]; then
			# extract file scope variables
			entry=${entry:$markLen}
			# declare file level variables and establish their values
			eval $entry
			continue
		fi
		if ! [[ "$entry" =~ ${config__VENDOR_LINENO_DETECTOR}(.+) ]]; then
			config__msg_error "'internal line number missing - error in program'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' entry='$entry'"
			return 1
		fi
		lineNum="${BASH_REMATCH[1]}"
		entry="${BASH_REMATCH[2]}"
		if [[ "$entry" =~ $config__VENDOR_SECTION_DETECTOR ]]; then
			if ! config__section_settings_extract "$entry" 'pasSectionDefs' 'pasTarOpts'; then
				config__msg_error "'error(s) while processing section definition'" \
				" vendorDir='$vendorDir' lineNum='$lineNum'"
				return 1
			fi
			tarOptsCurr="$pasTarOpts"
			continue
		fi
		# when set is given a string, it simply uses whitespace to delimit arguments
		# therefore a string like "'ab   c' d e" winds up as
		# $1="'ab", $2="c'" $3="d" $4="e" notice set doesn't understanded single/double
		# quoted strings.  However, by evaluating the contents of the string, the word
		# splitting done by eval considers quotes as a single word preventing the division
		# of a quoted string that contains one or more embedded whitespace(s).  Honoring
		# the behavior of quotes and the excape character "\" is the
		# evaluation behavior by those adding config file entries. 
		# lastly, it does permit the use of environment variables to allowing Just In Time
		# (dynamic) adaptation.
		eval set -- $entry
		if [[ "$#" -ne "3" ]]; then
			# record error but not problematic enough to stop processing
			config__msg_error "'expecting exactly three columns:" \
			" Path, Github Repro Download URL, Version'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' actualColms='$#' entry='$entry'"
			errOccr=1
			continue
		fi
		config__install_target_path "$1" "$vendorDir" 'targetPath'
		config__install_report "$targetPath" "$2" "$3" "$vendorDir" "$lineNum"
		if ! config__install "$targetPath" "$2" "$3" "$tarOptsCurr"; then
			# record error but not problematic enough to stop processing
			config__msg_error "'component install failed'" \
			" vendorDir='$vendorDir' lineNum='$lineNum' path='$targetPath' repo='$2'" \
			" version='$3' tarOpts='$tarOptsCurr"
			errOccr=1
			continue
		fi
	done
	return $errOccr
}
config__section_default_bash_component(){
	local rtnSectionDefs="$1"

	local pasOptsVal
	local sectionDefault="[whisperingchaos.bash.component] --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component'"
	if ! config__section_settings_extract "$sectionDefault" "$rtnSectionDefs" \
	   	'pasOptsVal'; then
		config__msg_error "Failed to parse default section settings='$sectionDefault'"
		return 1
	fi
}
config__section_settings_extract(){
	local -r sectionDefMaybe="$1"
	local -r rtnSectionDefs="$2"
	local -r rtnTarOpts="$3"

	[[ "$sectionDefMaybe" =~ $config__VENDOR_SECTION_DETECTOR ]] || return
	local -r sectionNm="${BASH_REMATCH[1]}"
	local opts=${BASH_REMATCH[3]}

	if [[ -z "$opts" ]]; then
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
}


config__install_target_path(){
	local entryPath="$1"
	local -r vendorDir="$2"
	local -r rtnTargetPath="$3"

	# Permit absolute paths - assume absolute
	if [ "$entryPath" == "${entryPath#/}" ]; then
		# was relative
		entryPath="$vendorDir/$entryPath"
	fi
	eval $rtnTargetPath\=\"\$entryPath\"
}

	
config__install(){
	local targetPath="$1"
	local -r repo="$2"
	local -r ver="$3"
	local -r tarOpts="$4"

	config__component_download "$repo/tarball/$ver" "$targetPath" "$tarOpts"
}
config__install_report(){
	local -r targetPath="$1"
	local -r repo="$2"
	local -r ver="$3"
	local -r vendorDir="$4"
	local -r lineNum=$5

   config__msg_info "Downloading & installing repo='$repo'"  \
	  " ver='$3' to directory='$targetPath' vendor.config="   \
    "'$vendorDir' lineNum='$lineNum'" 
} 
config__component_download(){
	local -r repoVerUrl="$1"
	local -r componentLocalPath="$2"
	local -r tarOpts="$3"

	if ! mkdir -p  "$componentLocalPath"; then
		config__msg_error "'failed to create local path'" \
		" componentLocalPath='$componentLocalPath'"
		return 1
	fi
	wget --dns-timeout=5 --connect-timeout=10 --read-timeout=60 -O -  "$repoVerUrl" 2>/dev/null | eval tar \-xz \-C \"\$componentLocalPath\" $tarOpts \2\>\/dev\/null
	config__pipe_status_ok "${PIPESTATUS[@]}"
}


config__pipe_status_ok(){
	local -r  pipeStat=$@

	local -ri pipeLen=${#pipeStat}
	local pipeComp='0 0 0 0'
	while [[ ${#pipeComp} -lt $pipeLen ]]; do
		pipeComp="$pipeComp $pipeComp"
	done

	[[ "${pipeStat}" = "${pipeComp:0:$pipeLen}" ]]
}


config__msg_error() {
	# due to bootstrap nature of config, better to replicate code than source it
	# therefore, it doesn't source the 'msg_' package
	local msg
	while [[ $# -gt 0 ]]; do
		msg=$msg$1
		shift
	done
	echo "error: msg='$msg' func_name='${FUNCNAME[1]}' line_no=${BASH_LINENO[1]} source_file='${BASH_SOURCE[1]}' time='$(date --iso-8601=ns)'" >&2
}
config__msg_info(){
	
	local msg
	while [[ $# -gt 0 ]]; do
		msg=$msg$1
		shift
	done

	echo "info: msg='$msg'" 
}
