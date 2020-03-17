#!/bin/bash
sourcer__build_CONFLICT_EXCEPTION='enable'
sourcer__build_funcvar_exception_categorize(){ return 1; }
source ./config_test_sh/sourcer/base/sourcer.build.source.sh ./config_test_sh/sourcer ./config_test_sh


test_config__vendor_banner_detected(){
	assert_true "echo '#<vendor.config:v1.0>' | config__vendor_banner_detected"
	assert_true 'test_config__vendor_banner_white_space | config__vendor_banner_detected'
	assert_false "echo '#<vendorxconfig:1.0>' | config__vendor_banner_detected"

	assert_false 'test_config__vendor_banner_not_first | config__vendor_banner_detected'
	assert_false "echo '#<vendor.config:.0>' | config__vendor_banner_detected"
	assert_false "echo 'bad#<vendor.config:.0>' | config__vendor_banner_detected"
}

test_config__vendor_banner_white_space(){
	echo ' 	#<vendor.config:v1.0>' 
}

test_config__vendor_banner_not_first(){
	echo '# hi there!'
	echo '#<vendor.config:v1.0>' 
}
test_config__vendor_shebang_detected(){
	assert_false 'test_config__vendor_bash_shebang | config__vendor_shebang_detected'
	assert_false 'test_config__vendor_bash_shebang_plus | config__vendor_shebang_detected'
	assert_true 'test_config__vendor_bash_shebang_vendor | config__vendor_shebang_detected'
	assert_false 'test_config__vendor_bash_vendor_shebang | config__vendor_shebang_detected'
	assert_false 'test_config__vendor_bad_shebang_vendor | config__vendor_shebang_detected'
}
test_config__vendor_bash_shebang(){
	echo "#!/bin/bash"
}
test_config__vendor_bash_shebang_plus(){
	echo "#!/bin/bash"
	echo "# another line"
}
test_config__vendor_shell_shebang_vendor(){
	echo "#!/bin/sh -x"
	echo '#<vendor.config:v1.0>' 
}
test_config__vendor_bash_shebang_vendor(){
	echo "#!/bin/bash"
	echo '#<vendor.config:v1.0>' 
}
test_config__vendor_bash_vendor_shebang(){
	echo '#<vendor.config:v1.0>' 
	echo "#!/bin/bash"
}
test_config__vendor_bad_shebang_vendor(){
echo "#!"
echo '#<vendor.config:v1.0>' 
}
test_config__vendor_read(){
	assert_true "test_config__vendor_temp_file_reading test_config__vendor_file_empty test_config__vendor_file_empty_output"
	assert_true "test_config__vendor_temp_file_reading test_config__vendor_file_one_entry test_config__vendor_file_one_entry_output"
	assert_true "test_config__vendor_temp_file_reading test_config__vendor_file_two_entry test_config__vendor_file_two_entry_output"
	assert_true "test_config__vendor_temp_file_reading test_config__vendor_read_bash test_config__vendor_read_bash_output 'subshell'"
 }
test_config__vendor_temp_file_reading(){
	local -r vendorGen="$1"
	local -r vendorGenOut="$2"
	local -r readerOpt="${3:-cat}"

	local pasTempFileNm
	test_config__vendor_temp_file_create "$vendorGen" 'pasTempFileNm'
	if [ "$readerOpt" == 'subshell' ]; then 
		assert_true 'chmod +x "$pasTempFileNm"'
	fi
	test_vendorGenOut_wrapper(){
		$vendorGenOut "$pasTempFileNm"
	}
	echo "$readerOpt $pasTempFileNm" | config__vendor_read | assert_output_true test_vendorGenOut_wrapper

	local -i returnCd=$?
	test_config__vendor_temp_file_destroy "$pasTempFileNm"
	return $returnCd
}
test_config__vendor_temp_file_create(){
	local -r vendorGen="$1"
	local -r rtnTempFileNm="$2"
	local -r tmpVendor=$(mktemp --tmpdir -d test_config_vendor.XXXXXXXXXX)'/vendor.config'
	assert_true "'$vendorGen' > '$tmpVendor'"
	eval $rtnTempFileNm=\"\$tmpVendor\"
}
test_config__vendor_temp_file_destroy(){
	local tmpDirName="$(dirname "$1")"
	local -r tmpDirPrefix='/tmp/'
	assert_halt
	assert_true '[ "${tmpDirName:0:${#tmpDirPrefix}}" == "$tmpDirPrefix" ]'
	assert_continue
	rm -rf "$tmpDirName"
}
test_config__vendor_file_empty(){
	return
}
test_config__vendor_file_empty_output(){
	test_config__vendor_scope_mark_gen "$1"
	return
}
test_config__vendor_file_one_entry(){
	echo "column1 column2 colum3"
}
test_config__vendor_file_one_entry_output(){
	test_config__vendor_scope_mark_gen "$1"
	test_config__vendor_file_one_entry
}
test_config__vendor_file_two_entry(){
	test_config__vendor_file_one_entry
	test_config__vendor_file_one_entry
}
test_config__vendor_file_two_entry_output(){
	test_config__vendor_scope_mark_gen "$1"
	test_config__vendor_file_one_entry
	test_config__vendor_file_one_entry
}
test_config__vendor_scope_mark_gen(){
	local vendorFileNm="$1"
	echo "$config__VENDOR_FILE_SCOPE_MARK"'local vendorDir='"'$(dirname $vendorFileNm)'"';'
}
test_config__vendor_read_bash(){
	cat <<'bashFileDefinition'
#!/bin/bash
test_config_file_bash_main(){
	local -r localVar='hellWorld'
	echo "$localVar column2 colum3"
}
test_config_file_bash_main
bashFileDefinition
}
test_config__vendor_read_bash_output(){
	test_config__vendor_scope_mark_gen "$1"
	echo 'hellWorld column2 colum3'
}
test_config__vendor_whitespace_exclude(){
	assert_true 'test_config__vendor_file_entries_single_line_comments | config__vendor_whitespace_exclude | assert_output_true "exit 0"'
	#set -x
	assert_true 'test_config__vendor_scope_mark_allow | config__vendor_whitespace_exclude | assert_output_true test_config__vendor_scope_mark_allow_output'
	assert_true 'test_config__vendor_file_entries_single_line | config__vendor_whitespace_exclude | assert_output_true test_config__vendor_file_single_ws_output'
}
test_config__vendor_file_entries_single_line_comments(){
	echo '#<vendor.config:v1.0>'
	echo '# my comment'
	echo '# another comment'
	echo '         '
	echo
}
test_config__vendor_scope_mark_allow(){
	test_config__vendor_scope_mark_gen 'testdir/testfile'
}
test_config__vendor_scope_mark_allow_output(){
	test_config__vendor_scope_mark_gen 'testdir/testfile'
}
test_config__vendor_file_entries_single_line(){
	echo 'column1 column2 colum3'
}
test_config__vendor_file_single_ws_output(){
	echo "1 $( test_config__vendor_file_entries_single_line )" 
}
test_config__section_settings_extract(){
	assert_true test_config__section_settings_extract_all_good
	assert_true test_config__section_settings_extract_name_starts_with_at_least_3_characters
	assert_true test_config__section_settings_extract_section_qualifier_between_words
	assert_true test_config__section_settings_extract_name_contains_illegal_characters
	assert_true test_config__section_settings_extract_name_less_than_3_characters
	assert_true test_config__section_settings_extract_name_period_start
	assert_true test_config__section_settings_extract_name_period_end
	assert_true test_config__section_settings_extract_name_values_empty
	assert_true test_config__section_settings_extract_empty_section
	assert_true test_config__section_settings_extract_strip
	assert_true test_config__section_settings_extract_prior_def
	assert_true test_config__section_settings_extract_prior_def_change
}
test_config__section_settings_extract_all_good(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config__section_settings_extract '[test] --strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[test]}" == "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component=2 --wildcards */component" ]'
}
test_config__section_settings_extract_name_starts_with_at_least_3_characters(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config__section_settings_extract '[tes] --strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[tes]}" == "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component=2 --wildcards */component" ]'
}
test_config__section_settings_extract_section_qualifier_between_words(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config__section_settings_extract '[tes.it]--strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[tes.it]}" == "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component=2 --wildcards */component" ]'
}
test_config__section_settings_extract_name_contains_illegal_characters(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config__section_settings_extract '[tesiti!] --strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 0 ]'
}
test_config__section_settings_extract_name_less_than_3_characters(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config__section_settings_extract '[te] --strip-component 2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
}
test_config__section_settings_extract_name_period_start(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config__section_settings_extract '[.te] --strip-component 2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
}
test_config__section_settings_extract_name_period_end(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config__section_settings_extract '[test.] --strip-component 2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
}
test_config__section_settings_extract_name_values_empty(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config__section_settings_extract '[tes.it]  ' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 0 ]'
	assert_true '[ -z "$pasTarOpts" ]'
}
test_config__section_settings_extract_empty_section(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config__section_settings_extract '[test.section]' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 0 ]'
	assert_true '[ -z "$pasTarOpts" ]'
}
test_config__section_settings_extract_strip(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config__section_settings_extract '[test.section] --strip-component 3' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[test.section]}" = "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component 3" ]'
}
test_config__section_settings_extract_prior_def(){
	local -A pasSectionDefs
	local pasTarOpts
	local -r tarOptsExpected='--wildcards ./ --strip-component 5'
	assert_true "config__section_settings_extract '[test.section] $tarOptsExpected' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
	pasTarOpts=''
	assert_true	"config__section_settings_extract '[test.section]' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
}
test_config__section_settings_extract_prior_def_change(){
	local -A pasSectionDefs
	local pasTarOpts
	local -r tarOptsExpected='--wildcards ./ --strip-component 5'
	assert_true "config__section_settings_extract '[test.section] $tarOptsExpected' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
	pasTarOpts=''
	assert_true	"config__section_settings_extract '[test.section]' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
	pasStripVal=''
	local -r tarOptNewVal='--strip-component 6'
	assert_true	"config__section_settings_extract '[test.section] $tarOptNewVal' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptNewVal" ]'
}
test_config__install()(
	local pasRepoVersion
	local pasComponentLocalPath
	local pasTarOpts

	config__component_download(){
		pasRepoVersion=$1
		pasComponentLocalPath="$2"
		pasTarOpts="$3"
		true
	}
	assert_true test_config__install_entire_tarball
	assert_true test_config__install_with_strip
	assert_true test_config__install_with_strip_wildcards

	assert_return_code_set
)


test_config__install_entire_tarball(){
	assert_true "config__install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "component" ]]'
	assert_true '[[ -z "$pasTarOpts" ]]'
}


test_config__install_with_strip(){
	assert_true "config__install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '--strip-component=5'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "component" ]]'
	assert_true '[[ "$pasTarOpts" == '\''--strip-component=5'\'' ]]'
}


test_config__install_with_strip_wildcards(){
	assert_true "config__install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '--strip-component=5 --wildcards config.source.sh'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "component" ]]'
	local opts="--strip-component=5 --wildcards config.source.sh"
	assert_true '[[ "$pasTarOpts" == "$opts" ]]'
}


test_config__section_default_bash_component(){
	local -A pasSectionDefs
	local -r expected='--strip-component=2 --wildcards --no-wildcards-match-slash --anchor '\''*/component'\'
	assert_true "config__section_default_bash_component 'pasSectionDefs'" 
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[whisperingchaos.bash.component]}" == "$expected" ]'
}
test_config__entry_iterate()(
	config__install_report(){
		return
	}
	config__component_download(){
		echo "$1" --- "$2" --- "$3"
	}
	assert_true 'test_config__vendor_file_single_section | config__entry_iterate | assert_output_true test_config__vendor_file_single_section_out'  
	assert_true 'test_config__vendor_file_two_sections | config__entry_iterate | assert_output_true test_config__vendor_file_two_sections_out'
	assert_true 'test_config__vendor_file_reference_prior_sections | config__entry_iterate | assert_output_true test_config__vendor_file_reference_prior_sections_out'
	assert_true 'test_config__vendor_file_default_section | config__entry_iterate | assert_output_true test_config__vendor_file_default_section_out'

	assert_return_code_set
)
test_config__vendor_file_single_section(){
cat <<vendor_iterate_test
$config__VENDOR_FILE_SCOPE_MARK local vendorDir='~/'
1 [section] --strip-component=1 --wildcards '*.source.sh'
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relComponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}	
test_config__vendor_file_single_section_out(){
cat <<vendor_iterate_test_out
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.source.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=1 --wildcards '*.source.sh'
vendor_iterate_test_out
}
test_config__vendor_file_two_sections(){
cat <<vendor_iterate_test
$config__VENDOR_FILE_SCOPE_MARK local vendorDir='~/'
1 [section] --strip-component=1 --wildcards '*.source.sh'
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relComponentPath2' 'repoUrl2' 'repoVer2'
5 [section2] --strip-component=2 --wildcards "*.sh"
6 relComponentPath repoUrl repoVer
7 relComponentPath1 repoUrl1 repoVer1
8 'relComponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}	
test_config__vendor_file_two_sections_out(){
cat <<vendor_iterate_test_out
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.source.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=2 --wildcards "*.sh"
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=2 --wildcards "*.sh"
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=2 --wildcards "*.sh"
vendor_iterate_test_out
}
test_config__vendor_file_reference_prior_sections(){
cat <<vendor_iterate_test
$config__VENDOR_FILE_SCOPE_MARK local vendorDir='~/'
1 [section] --strip-component=1 --wildcards '*.source.sh'
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relCom ponentPath2' 'repoUrl2' 'repoVer2'
5 [section2] --strip-component=2 --wildcards "*.sh"
6 relComponentPath repoUrl repoVer
7 relComponentPath1 repoUrl1 repoVer1
8 relCom\ ponentPath2 'repoUrl2' 'repoVer2'
9 [section]
10 relComponentPath repoUrl repoVer
11 relComponentPath1 repoUrl1 repoVer1
12 'relComponentPath2' 'repoUrl2' 'repoVer2'
13 [section2] --strip-component=2 --wildcards "*.sh"
14 relComponentPath repoUrl repoVer
15 relComponentPath1 repoUrl1 repoVer1
16 'relCom\ ponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}	
test_config__vendor_file_reference_prior_sections_out(){
cat <<vendor_iterate_test_out
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.source.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl2/tarball/repoVer2 --- ~//relCom ponentPath2 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=2 --wildcards "*.sh"
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=2 --wildcards "*.sh"
repoUrl2/tarball/repoVer2 --- ~//relCom ponentPath2 --- --strip-component=2 --wildcards "*.sh"
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.source.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=1 --wildcards '*.source.sh'
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=2 --wildcards "*.sh"
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=2 --wildcards "*.sh"
repoUrl2/tarball/repoVer2 --- ~//relCom\ ponentPath2 --- --strip-component=2 --wildcards "*.sh"
vendor_iterate_test_out
}	
test_config__vendor_file_default_section(){
cat <<vendor_iterate_test
$config__VENDOR_FILE_SCOPE_MARK local vendorDir=/home/dev/
1 [whisperingchaos.bash.component]
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relComponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}
test_config__vendor_file_default_section_out(){
cat <<vendor_iterate_test
repoUrl/tarball/repoVer --- /home/dev//relComponentPath --- --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component'
repoUrl1/tarball/repoVer1 --- /home/dev//relComponentPath1 --- --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component'
repoUrl2/tarball/repoVer2 --- /home/dev//relComponentPath2 --- --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component'
vendor_iterate_test
}


test_config__pipe_status_ok(){

	local -ai statusPipe
	statusPipe=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
	assert_true 'config__pipe_status_ok "${statusPipe[@]}"'
	statusPipe=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1)
	assert_false 'config__pipe_status_ok "${statusPipe[@]}"'
	statusPipe=(1)
	assert_false 'config__pipe_status_ok "${statusPipe[@]}"'
	statusPipe=(0)
	assert_true 'config__pipe_status_ok "${statusPipe[@]}"'
}


test_config__msg_error(){
	assert_true 'test_config__msg_error_generate | assert_output_true test_config__msg_error_expected'
}
test_config__msg_error_generate(){
	config__msg_error "testing error message" 2>&1 
}
test_config__msg_error_expected(){
	echo "${assert_REGEX_COMPARE}error: msg='testing error message' func_name='test_config__msg_error_generate' line_no=[0-9]+ source_file='./config_test.sh' time=.*"
}
test_config_tree_walk(){

	local pasTempFileNm
	assert_true  "test_config__vendor_temp_file_create test_config_tree_walk_generate_one_component_vendor 'pasTempFileNm'"
	assert_true 'config_vendor_tree_walk "$(dirname "$pasTempFileNm")"|assert_output_true test_config_tree_walk_generate_one_component_vendor_output' 
	test_config__vendor_temp_file_destroy "$pasTempFileNm"

	assert_output_true \
		---	assert_true 'config_vendor_tree_walk ./config_test_sh/file/vendor_tree_walk/max_directories'
	assert_output_true test_config__vendor_file_search_too_deep_error_out \
		--- assert_false 'config_vendor_tree_walk ./config_test_sh/file/vendor_tree_walk/too_deep'
	assert_output_true test_config__vendor_file_search_too_broad_out \
		--- assert_false 'config_vendor_tree_walk ./config_test_sh/file/vendor_tree_walk/too_broad'
	assert_output_true test_config_tree_walk_generate_bad_component_vendor_output \
		--- assert_false 'config_vendor_tree_walk ./config_test_sh/file/vendor_tree_walk/bad_component_repository'

	assert_return_code_set
}
test_config_tree_walk_generate_one_component_vendor(){
	cat <<'vendorfile'
#<vendor.config:v1.0>
[whisperingchaos.bash.component]
assert	https://github.com/WhisperingChaos/assert.source.sh master
vendorfile
}
test_config_tree_walk_generate_one_component_vendor_output(){
	echo "${assert_REGEX_COMPARE}^info\: msg\='Downloading \& installing repo\='https\://github\.com/WhisperingChaos/assert\.source\.sh' ver='master' to directory='/tmp/.+assert.*"
}
test_config_tree_walk_one_bad(){
( config_vendor_tree_walk "$(dirname "$1")")
}
test_config_tree_walk_generate_bad_component_vendor(){
	cat <<'vendorfile'
#<vendor.config:v1.0>
[whisperingchaos.bash.component]
assert	https://github.com/WhisperingChaos/doesnotexist master
vendorfile
}

test_config_tree_walk_generate_bad_component_vendor_output(){
	echo "${assert_REGEX_COMPARE}^info: msg='Downloading \& installing repo='https://github.com/WhisperingChaos/doesnotexist' ver='master' to directory='\./config_test_sh/file/vendor_tree_walk/bad_component_repository/assert' vendor.config='\./config_test_sh/file/vendor_tree_walk/bad_component_repository' lineNum='[0-9]+''"
	echo "${assert_REGEX_COMPARE}^error: msg\=''component install failed' vendorDir\='\./config_test_sh/file/vendor_tree_walk/bad_component_repository' lineNum='[0-9]+' path='\./config_test_sh/file/vendor_tree_walk/bad_component_repository/assert' repo='https://github\.com/WhisperingChaos/doesnotexist' version='master' tarOpts\='\-\-strip-component=2 \-\-wildcards \-\-no\-wildcards\-match\-slash \-\-anchor '\*/component'' func_name='config__entry_iterate' line_no=[0-9]+ source_file='\./config_test_sh/base/config\.source\.sh' time\='[^']+'"
}


test_config__vendor_file_search_too_deep_error_out(){
	cat <<TEST_CONFIG__VENDOR_FILE_SEARCH_TOO_DEEP_ERROR
${assert_REGEX_COMPARE}error: msg='Attempting to dive into directory: '\./config_test_sh/file/vendor_tree_walk/too_deep/level_2//level_3//Level_4//Level_5//Level_6/' but its depth exceeds maximum level of: '[0-9]+'\.  If max level too small then increase value of variable config__VENDOR_VISIT_LEVEL_MAX using override mechanism\.' func_name='config__vendor_file_search_too_deep_error' line_no=[0-9]+ source_file='\./config_test_sh/base/config\.source\.sh' time='.+'$
TEST_CONFIG__VENDOR_FILE_SEARCH_TOO_DEEP_ERROR
}

test_config__vendor_file_search_too_broad_out(){
	cat <<TEST_CONFIG__VENDOR_FILE_SEARCH_TOO_BROAD_ERROR
${assert_REGEX_COMPARE}^error: msg='Maximum component count: '20' exceeded for a given level while starting to process directory: '\./config_test_sh/file/vendor_tree_walk/too_broad/component_21/'\.  This and all component directories that sort after it were not processed\.  If you want to exceed this limit increase the value of variable: 'config__VENDOR_COMPONENTS_PER_LEVEL_MAX'\.' func_name='config__vendor_too_many_components_error' line_no=[0-9]+ source_file='\./config_test_sh/base/config.source.sh' time='[^']+'
TEST_CONFIG__VENDOR_FILE_SEARCH_TOO_BROAD_ERROR
}


# Almost "clean" the executing environment by starting
# a new shell as child process during recursive call.
# This is different from creating a subshell within
# an existing shell.  Did not use 'env -i' because
# it eliminates nearly all environment variables, some
# of which might be handy in writing a test.
test_execute_clean(){
	bash ./config_test.sh --clean "$@"
	assert_return_code_child_failure_relay
}


test_config_sh(){

	assert_output_true config_vendor_format_example \
		--- assert_true './config_test_sh/config.sh --sample'
	assert_output_true test_config_sh_file_search_too_deep_error_out \
		--- assert_false './config_test_sh/config.sh ./config_test_sh/file/vendor_tree_walk/too_deep'
	assert_output_true test_config_sh_file_absolute_path_with_hash_out \
		--- assert_true './config_test_sh/config.sh ./config_test_sh/file/vendor_absolute_path/absolute_1'
	assert_output_true 	echo "version: v1.3" \
		--- assert_true './config_test_sh/config.sh --version'

	assert_return_code_set
}


test_config_sh_file_search_too_deep_error_out(){
	cat << TEST_CONFIG_SH_FILE_SEARCH_TOO_DEEP_ERROR_OUT
${assert_REGEX_COMPARE}^error: msg='Attempting to dive into directory: '\./config_test_sh/file/vendor_tree_walk/too_deep/level_2//level_3//Level_4//Level_5//Level_6/' but its depth exceeds maximum level of: '[0-9]+'\.  If max level too small then increase value of variable config__VENDOR_VISIT_LEVEL_MAX using override mechanism\.' func_name='config__vendor_file_search_too_deep_error' line_no=[0-9]+ source_file='[^']+config.sh/component/config_sh/base/config.source.sh' time='[^']+'
TEST_CONFIG_SH_FILE_SEARCH_TOO_DEEP_ERROR_OUT
}

test_config_sh_file_absolute_path_with_hash_out(){
	cat << TEST_CONFIG_SH_ABSOLUTE_PATH_WITH_HASH_OUT
${assert_REGEX_COMPARE}^info: msg\='Downloading & installing repo='https://github.com/WhisperingChaos/sourcer\.sh' ver\='master' to directory\='/.+/config.sh/test/config_test_sh/file/vendor_absolute_path/absolute_1/absolute_1' vendor.config\='\./config_test_sh/file/vendor_absolute_path/absolute_1' lineNum='[0-9]+''
info: msg='Downloading & installing repo='https://github.com/WhisperingChaos/assert.source.sh' ver='9c4806e49bee4166b056aa627d1255549b1a4920' to directory='./config_test_sh/file/vendor_absolute_path/absolute_1/absolute_1' vendor.config='./config_test_sh/file/vendor_absolute_path/absolute_1' lineNum='8''
info: msg='Downloading & installing repo='https://github.com/WhisperingChaos/assert.source.sh' ver='9c4806e49bee4166b056aa627d1255549b1a4920' to directory='./config_test_sh/file/vendor_absolute_path/absolute_1/.' vendor.config='./config_test_sh/file/vendor_absolute_path/absolute_1' lineNum='9''
TEST_CONFIG_SH_ABSOLUTE_PATH_WITH_HASH_OUT
}


test_version_verify(){
	assert_true "[[ 'v1.2' = \"$config__COMPONENT_SEMANTIC_VERSION\" ]]"
	assert_true "[[ 'v1.0' = \"$config__VENDOR_CONFIG_SEMANTIC_VERSION\" ]]"
}


main(){

	if [[ "$1" = '--clean' ]]; then
		$2 "${@:2}"
		assert_return_code_set
		return
	fi

	test_config__msg_error
	test_config__pipe_status_ok
	test_config__vendor_banner_detected
	test_config__vendor_shebang_detected
	test_config__vendor_read
	test_config__vendor_whitespace_exclude
	test_config__section_settings_extract
	assert_return_code_child_failure_relay	test_config__install
	test_config__section_default_bash_component
	assert_return_code_child_failure_relay  test_config__entry_iterate
	test_execute_clean	test_config_tree_walk
	test_execute_clean	test_config_sh
	test_version_verify

	assert_return_code_set
}
main "$@"
