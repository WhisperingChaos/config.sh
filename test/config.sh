#!/bin/bash
config_executeable(){
	local -r myRoot="$1"
	# include components required to create this executable
	local mod
	for mod in $( "$myRoot/composer/composer.sh" "$myRoot"); do
		source "$mod"
	done
	# include component to be tested 
	source "$myRoot/config.include.sh"
}

test_config_vendor_banner_detected(){
	assert_true "echo '#<vendor.config:1.0>' | config_vendor_banner_detected"
	assert_true 'test_config_vendor_banner_white_space | config_vendor_banner_detected'
	assert_false "echo '#<vendorxconfig:1.0>' | config_vendor_banner_detected"

	assert_false 'test_config_vendor_banner_not_first | config_vendor_banner_detected'
	assert_false "echo '#<vendor.config:.0>' | config_vendor_banner_detected"
	assert_false "echo 'bad#<vendor.config:.0>' | config_vendor_banner_detected"
}

test_config_vendor_banner_white_space(){
	echo ' 	#<vendor.config:1.0>' 
}

test_config_vendor_banner_not_first(){
	echo '# hi there!'
	echo '#<vendor.config:1.0>' 
}

test_config_vendor_read(){
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_file_empty test_config_vendor_file_empty"
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_file_one_entry test_config_vendor_file_one_entry_output"
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_file_two_entry test_config_vendor_file_two_entry_output"
 }
test_config_vendor_temp_file_reading(){
	local -r vendorGen="$1"
	local -r vendorGenOut="$2"

	local pasTempFileNm
	test_config_vendor_temp_file_create "$vendorGen" 'pasTempFileNm'
	test_vendorGenOut_wrapper(){
		$vendorGenOut "$pasTempFileNm"
	}
	echo "$pasTempFileNm" | config_vendor_read | assert_output_true test_vendorGenOut_wrapper

	local -i returnCd=$?
	local -r tmpDirPrefix='/tmp/' 
	if [ "${pasTempFileNm:0:${#tmpDirPrefix}}" == "$tmpDirPrefix" ]; then
		rm -rf $( dirname "$pasTempFileNm" )
		(( returnCd = ( returnCd + $? )	))
	fi
	return $returnCd
}
test_config_vendor_temp_file_create(){
	local -r vendorGen="$1"
	local -r rtnTempFileNm="$2"
	local -r tmpVendor=$(mktemp --tmpdir -d test_config_vendor.XXXXXXXXXX)'/vendor.config'
	assert_true "'$vendorGen' > '$tmpVendor'"
	eval $rtnTempFileNm=\"\$tmpVendor\"
}
test_config_vendor_file_empty(){
	return
}
test_config_vendor_file_one_entry(){
	echo "column1 column2 colum3"
}
test_config_vendor_file_one_entry_output(){
	test_config_vendor_file_mark_gen "$1"
	test_config_vendor_file_one_entry
}
test_config_vendor_file_two_entry(){
	test_config_vendor_file_one_entry
	test_config_vendor_file_one_entry
}
test_config_vendor_file_two_entry_output(){
	test_config_vendor_file_mark_gen "$1"
	test_config_vendor_file_one_entry
	test_config_vendor_file_one_entry
}
test_config_vendor_file_mark_gen(){
	local vendorFileNm="$1"
	echo "$config_VENDOR_FILE_SCOPE_MARK"'unset vendorDir; local -r vendorDir='"'$(dirname $vendorFileNm)'"';'
}

test_config_vendor_file_entries(){
	assert_true 'test_config_vendor_file_entries_single_line | config_vendor_file_entries | assert_output_true test_config_vendor_file_entries_single_line'
	assert_true 'test_config_vendor_file_entries_single_line_comments | config_vendor_file_entries | assert_output_true test_config_vendor_file_entries_single_line'
}

test_config_vendor_file_entries_single_line(){
	echo 'column1 column2 colum3'
}
test_config_vendor_whitespace_exclude(){
	assert_true 'test_config_vendor_file_entries_single_line_comments | config_vendor_whitespace_exclude | assert_output_true "exit 0"'
	#set -x
	assert_true 'test_config_vendor_file_entries_marks_allow | config_vendor_whitespace_exclude | assert_output_true test_config_vendor_file_entries_marks_allow_output'
	assert_true 'test_config_vendor_file_entries_single_line | config_vendor_whitespace_exclude | assert_output_true test_config_vendor_file_single_ws_output'

}
test_config_vendor_file_entries_single_line_comments(){
	echo '#<vendor.config:1.0>'
	echo '# my comment'
	echo '# another comment'
	echo '         '
}
test_config_vendor_file_entries_marks_allow(){
	test_config_vendor_file_mark_gen 'testdir/testfile'
	echo "${config_VENDOR_BASH_SNIPPETS_MARK}local -r variableName='value'"
}
test_config_vendor_file_entries_marks_allow_output(){
	echo "1 $(test_config_vendor_file_mark_gen 'testdir/testfile')"
	echo "2 ${config_VENDOR_BASH_SNIPPETS_MARK}local -r variableName='value'"
}
test_config_vendor_file_single_ws_output(){
	echo "1 $( test_config_vendor_file_entries_single_line )" 
}

test_config_section_parse(){
	assert_true test_config_section_parse_all_good
	assert_true test_config_section_parse_name_starts_with_at_least_3_characters
	assert_true test_config_section_parse_section_qualifier_between_words
	assert_true test_config_section_parse_name_contains_illegal_characters
	assert_true test_config_section_parse_name_starts_with_period
	assert_true test_config_section_parse_name_ends_with_period
	assert_true test_config_section_parse_name_less_than_3_characters
	assert_true test_config_section_parse_name_values_empty
	assert_true test_config_section_parse_name_strip_null
	assert_true test_config_section_parse_name_both_null
}
test_config_section_parse_all_good(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal
	assert_true	"config_section_parse '[test] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
	assert_true '[[ "$pasSectionNm" == "test" ]]'
	assert_true '$pasStripIs'
	assert_true	'[[ "$pasStripVal" == 2 ]]'
	assert_true '$pasWildcardsIs'
	assert_true '[[ "$pasWildcardsVal" == "*/component" ]]'
}
test_config_section_parse_name_starts_with_at_least_3_characters(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_true	"config_section_parse '[tes] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
	assert_true '[[ "$pasSectionNm" == "tes" ]]'
	assert_true '$pasStripIs'
	assert_true	'[[ "$pasStripVal" == "2" ]]'
	assert_true '$pasWildcardsIs'
	assert_true '[[ "$pasWildcardsVal" == "*/component" ]]'
}
test_config_section_parse_section_qualifier_between_words(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_true	"config_section_parse '[tes.it] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
	assert_true '[[ "$pasSectionNm" == "tes.it" ]]'
	assert_true '$pasStripIs'
	assert_true	'[[ "$pasStripVal" == "2" ]]'
	assert_true '$pasWildcardsIs'
	assert_true '[[ "$pasWildcardsVal" == "*/component" ]]'
}

test_config_section_parse_name_contains_illegal_characters(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_false	"config_section_parse '[tesiti!] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
}
test_config_section_parse_name_starts_with_period(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_false	"config_section_parse '[.test] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
}
test_config_section_parse_name_ends_with_period(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_false "config_section_parse '[test.] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
}
test_config_section_parse_name_less_than_3_characters(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_false "config_section_parse '[te] --strip-component 2 --wildcards */component' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
}
test_config_section_parse_name_values_empty(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_true "config_section_parse '[test.values] --strip-component  --wildcards' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
	assert_true '[[ "$pasSectionNm" == "test.values" ]]'
	assert_true '$pasStripIs'
	assert_true	'[[ -z "$pasStripVal" ]]'
	assert_true '$pasWildcardsIs'
	assert_true '[[ -z "$pasWildcardsVal" ]]'
}
test_config_section_parse_name_strip_null(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_true "config_section_parse '[test.values] --wildcards' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
	assert_true '[[ "$pasSectionNm" == "test.values" ]]'
	assert_false '$pasStripIs'
	assert_true	'[[ -z "$pasStripVal" ]]'
	assert_true '$pasWildcardsIs'
	assert_true '[[ -z "$pasWildcardsVal" ]]'
}
test_config_section_parse_name_both_null(){
	local pasSectionNm
	local pasStripIs
	local pasStripVal
	local pasWildcardsIs
	local pasWildcardsVal

	assert_true "config_section_parse '[test.values]' 'pasSectionNm' 'pasStripIs' 'pasStripVal' 'pasWildcardsIs' 'pasWildcardsVal'"
	assert_true '[[ "$pasSectionNm" == "test.values" ]]'
	assert_false '$pasStripIs'
	assert_true	'[[ -z "$pasStripVal" ]]'
	assert_false '$pasWildcardsIs'
	assert_true '[[ -z "$pasWildcardsVal" ]]'
}
test_config_section_settings_extract(){
	assert_true test_config_section_settings_extract_empty_section
	assert_true test_config_section_settings_extract_strip_3
	assert_true test_config_section_settings_extract_strip_not_number
	assert_true test_config_section_settings_extract_wildcards	
	assert_true test_config_section_settings_extract_wildcards_strip
	assert_true test_config_section_settings_extract_prior_def
	assert_true test_config_section_settings_extract_prior_def_change
	assert_true test_config_section_settings_extract_unknown_opt
}
test_config_section_settings_extract_empty_section(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal
	assert_true	"config_section_settings_extract '[test.section]' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 0 ]]'
	assert_true '[[ -z $pasStripVal ]]'
	assert_true '[[ -z $pasWildcardsVal ]]'
}
test_config_section_settings_extract_strip_3(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal
	assert_true	"config_section_settings_extract '[test.section] --strip-component 3' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ 3 -eq $pasStripVal ]]'
	assert_true '[[ -z $pasWildcardsVal ]]'
}
test_config_section_settings_extract_strip_not_number(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal

	local output="$( assert_false "config_section_settings_extract '[test.section] --strip-component A' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'" 2>&1)"
	assert_true  "echo \"\$output\" | assert_output_true 'echo <RegEx>^error: msg=..invalid tar --strip-component value - should be positive integer.+'"
}
test_config_section_settings_extract_wildcards(){
	declare -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal
	assert_true	"config_section_settings_extract '[test.section] --wildcards abc' 'pasSectionDefs' 'pasStripValue' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ -z $pasStripVal ]]'
	assert_true '[[ "abc" == "$pasWildcardsVal" ]]'
}
test_config_section_settings_extract_wildcards_strip(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal
assert_true	"config_section_settings_extract '[test.section] --wildcards ./ --strip-component 5' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ $pasStripVal -eq 5 ]]'
	assert_true '[[ "./" == "$pasWildcardsVal" ]]'
}
test_config_section_settings_extract_prior_def(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal
	assert_true	"config_section_settings_extract '[test.section] --wildcards ./ --strip-component 5' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ $pasStripVal -eq 5 ]]'
	assert_true '[[ "./" == "$pasWildcardsVal" ]]'
	pasStripVal=''
	pasWildcardsVal=''
	assert_true	"config_section_settings_extract '[test.section]' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ $pasStripVal -eq 5 ]]'
	assert_true '[[ "./" == "$pasWildcardsVal" ]]'
}
test_config_section_settings_extract_prior_def_change(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal
	assert_true	"config_section_settings_extract '[test.section] --wildcards ./ --strip-component 5' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ $pasStripVal -eq 5 ]]'
	assert_true '[[ "./" == "$pasWildcardsVal" ]]'
	pasStripVal=''
	pasWildcardsVal=''
	assert_true	"config_section_settings_extract '[test.section]' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ $pasStripVal -eq 5 ]]'
	assert_true '[[ "./" == "$pasWildcardsVal" ]]'
	pasStripVal=''
	pasWildcardsVal=''
	assert_true	"config_section_settings_extract '[test.section] --strip-component 6' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'"
	assert_true '[[ ${#pasSectionDefs[@]} -eq 1 ]]'
	assert_true '[[ $pasStripVal -eq 6 ]]'
	assert_true '[[ -z "$pasWildcardsVal" ]]'
}
test_config_section_settings_extract_unknown_opt(){
	local -A pasSectionDefs
	local pasSectionDefs
	local pasStripVal
	local pasWildcardsVal

	local output="$( assert_false "config_section_settings_extract '[test.section] --strip-component 6 --badopt A' 'pasSectionDefs' 'pasStripVal' 'pasWildcardsVal'" 2>&1)"
	assert_true  "echo \"\$output\" | assert_output_true 'echo <RegEx>^error: msg=.Unknown section option=.--badopt.+$'"
}
test_config_install(){
	local pasRepoVersion
	local pasComponentLocalPath
	local pasTarOpts

	config_component_download(){
		pasRepoVersion=$1
		pasComponentLocalPath="$2"
		pasTarOpts="$3"
		true
	}
	assert_true test_config_install_entire_tarball
	assert_true test_config_install_with_strip
	assert_true test_config_install_with_strip_wildcards
}
test_config_install_entire_tarball(){
	assert_true "config_install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '/home/dev/'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "/home/dev//component" ]]'
	assert_true '[[ -z "$pasTarOpts" ]]'
}
test_config_install_with_strip(){
	assert_true "config_install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '/home/dev/' '5'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "/home/dev//component" ]]'
	assert_true '[[ "$pasTarOpts" == '\''--strip-component=5'\'' ]]'
}
test_config_install_with_strip_wildcards(){
	assert_true "config_install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '/home/dev/' '5' 'config.include.sh'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "/home/dev//component" ]]'
	local opts="--strip-component=5 --wildcards 'config.include.sh'"
	assert_true '[[ "$pasTarOpts" == "$opts" ]]'
}
test_config_entry_iterate(){
}
test_config_vendor_path_append(){

	assert_true 'test_config_vendor_path_parents | config_vendor_path_append "/vendor" | assert_output_true test_config_vendor_path_parents_with_vendor'
	assert_true 'test_config_vendor_path_parents_quoted | config_vendor_path_append "/vendor" | assert_output_true test_config_vendor_path_parents_with_vendor_quoted'
}	
test_config_vendor_path_parents(){
cat <<vendor_path_parents
col1 col2 col3
col1.1 col2.1 col3.1
vendor_path_parents
}	

test_config_vendor_path_parents_with_vendor(){
cat <<vendor_path_parents
col1 col2 col3 '/vendor'
col1.1 col2.1 col3.1 '/vendor' 
vendor_path_parents
}	

test_config_vendor_path_parents_quoted(){
cat <<vendor_path_parents
'col1' 'col2' 'col3'
'col1.1' 'col2.1' 'col3.1'
vendor_path_parents
}	

test_config_vendor_path_parents_with_vendor_quoted(){
cat <<vendor_path_parents
'col1' 'col2' 'col3' '/vendor'
'col1.1' 'col2.1' 'col3.1' '/vendor' 
vendor_path_parents
}	

test_config_section_found(){
	assert_true test_config_section_found_true
	assert_true test_config_section_found_true_section_begins_with_less_at_least_3_characters
	assert_true test_config_section_found_true_section_qualifier_between_words
	assert_false test_config_section_found_false_section_name_contains_illegal_characters
	assert_false test_config_section_found_false_section_name_starts_with_period
	assert_false test_config_section_found_false_section_name_ends_with_period
	assert_false test_config_section_found_false_section_begins_with_less_than_2_characters
}

test_config_component_part(){
	assert_true 'config_component_part "https://github.com/WhisperingChaos/assert.include.sh" | assert_output_true "echo WhisperingChaos-assert.include.sh"'
}

test_config_msg_error(){
	assert_true 'test_config_msg_error_generate | assert_output_true test_config_msg_error_expected'
}
test_config_msg_error_generate(){
	config_msg_error "testing error message" 2>&1 
}

test_config_msg_error_expected(){
	# note test probably failed due to deleted/added lines added to assert.include.sh
	echo "error: msg='testing error message' func_name='test_config_msg_error_generate' line_no=52 source_file='./config.sh' time=.*"
}

main(){
	config_executeable  "$(dirname "${BASH_SOURCE[0]}")" 
	# invoke tests
#	test_config_section_found
	test_config_vendor_banner_detected
	test_config_vendor_read
	test_config_vendor_whitespace_exclude
	test_config_section_parse
	test_config_section_settings_extract
	test_config_install
#	test_config_vendor_file_entries
#	test_config_vendor_path_append
#	test_config_component_part
#	test_config_msg_error
}
main
