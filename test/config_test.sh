#!/bin/bash
config_executeable(){
	local -r myRoot="$1"
	# include components required to create this executable
	local mod
	for mod in $( "$myRoot/composer/composer.sh" "$myRoot"); do
		source "$mod"
	done
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
test_config_vendor_shebang_detected(){
	assert_false 'test_config_vendor_bash_shebang | config_vendor_shebang_detected'
	assert_false 'test_config_vendor_bash_shebang_plus | config_vendor_shebang_detected'
	assert_true 'test_config_vendor_bash_shebang_vendor | config_vendor_shebang_detected'
	assert_false 'test_config_vendor_bash_vendor_shebang | config_vendor_shebang_detected'
	assert_false 'test_config_vendor_bad_shebang_vendor | config_vendor_shebang_detected'
}
test_config_vendor_bash_shebang(){
	echo "#!/bin/bash"
}
test_config_vendor_bash_shebang_plus(){
	echo "#!/bin/bash"
	echo "# another line"
}
test_config_vendor_shell_shebang_vendor(){
	echo "#!/bin/sh -x"
	echo '#<vendor.config:1.0>' 
}
test_config_vendor_bash_shebang_vendor(){
	echo "#!/bin/bash"
	echo '#<vendor.config:1.0>' 
}
test_config_vendor_bash_vendor_shebang(){
	echo '#<vendor.config:1.0>' 
	echo "#!/bin/bash"
}
test_config_vendor_bad_shebang_vendor(){
echo "#!"
echo '#<vendor.config:1.0>' 
}
test_config_vendor_read(){
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_file_empty test_config_vendor_file_empty_output"
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_file_one_entry test_config_vendor_file_one_entry_output"
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_file_two_entry test_config_vendor_file_two_entry_output"
	assert_true "test_config_vendor_temp_file_reading test_config_vendor_read_bash test_config_vendor_read_bash_output 'subshell'"
 }
test_config_vendor_temp_file_reading(){
	local -r vendorGen="$1"
	local -r vendorGenOut="$2"
	local -r readerOpt="${3:-cat}"

	local pasTempFileNm
	test_config_vendor_temp_file_create "$vendorGen" 'pasTempFileNm'
	if [ "$readerOpt" == 'subshell' ]; then 
		assert_true 'chmod +x "$pasTempFileNm"'
	fi
	test_vendorGenOut_wrapper(){
		$vendorGenOut "$pasTempFileNm"
	}
	echo "$readerOpt $pasTempFileNm" | config_vendor_read | assert_output_true test_vendorGenOut_wrapper

	local -i returnCd=$?
	test_config_vendor_temp_file_destroy "$pasTempFileNm"
	return $returnCd
}
test_config_vendor_temp_file_create(){
	local -r vendorGen="$1"
	local -r rtnTempFileNm="$2"
	local -r tmpVendor=$(mktemp --tmpdir -d test_config_vendor.XXXXXXXXXX)'/vendor.config'
	assert_true "'$vendorGen' > '$tmpVendor'"
	eval $rtnTempFileNm=\"\$tmpVendor\"
}
test_config_vendor_temp_file_destroy(){
	local tmpDirName="$(dirname "$1")"
	local -r tmpDirPrefix='/tmp/'
	assert_halt
	assert_true '[ "${tmpDirName:0:${#tmpDirPrefix}}" == "$tmpDirPrefix" ]'
	assert_continue
	rm -rf "$tmpDirName"
}
test_config_vendor_file_empty(){
	return
}
test_config_vendor_file_empty_output(){
	test_config_vendor_scope_mark_gen "$1"
	return
}
test_config_vendor_file_one_entry(){
	echo "column1 column2 colum3"
}
test_config_vendor_file_one_entry_output(){
	test_config_vendor_scope_mark_gen "$1"
	test_config_vendor_file_one_entry
}
test_config_vendor_file_two_entry(){
	test_config_vendor_file_one_entry
	test_config_vendor_file_one_entry
}
test_config_vendor_file_two_entry_output(){
	test_config_vendor_scope_mark_gen "$1"
	test_config_vendor_file_one_entry
	test_config_vendor_file_one_entry
}
test_config_vendor_scope_mark_gen(){
	local vendorFileNm="$1"
	echo "$config_VENDOR_FILE_SCOPE_MARK"'local vendorDir='"'$(dirname $vendorFileNm)'"';'
}
test_config_vendor_read_bash(){
	cat <<'bashFileDefinition'
#!/bin/bash
test_config_file_bash_main(){
	local -r localVar='hellWorld'
	echo "$localVar column2 colum3"
}
test_config_file_bash_main
bashFileDefinition
}
test_config_vendor_read_bash_output(){
	test_config_vendor_scope_mark_gen "$1"
	echo 'hellWorld column2 colum3'
}
test_config_vendor_whitespace_exclude(){
	assert_true 'test_config_vendor_file_entries_single_line_comments | config_vendor_whitespace_exclude | assert_output_true "exit 0"'
	#set -x
	assert_true 'test_config_vendor_scope_mark_allow | config_vendor_whitespace_exclude | assert_output_true test_config_vendor_scope_mark_allow_output'
	assert_true 'test_config_vendor_file_entries_single_line | config_vendor_whitespace_exclude | assert_output_true test_config_vendor_file_single_ws_output'
}
test_config_vendor_file_entries_single_line_comments(){
	echo '#<vendor.config:1.0>'
	echo '# my comment'
	echo '# another comment'
	echo '         '
	echo
}
test_config_vendor_scope_mark_allow(){
	test_config_vendor_scope_mark_gen 'testdir/testfile'
}
test_config_vendor_scope_mark_allow_output(){
	test_config_vendor_scope_mark_gen 'testdir/testfile'
}
test_config_vendor_file_entries_single_line(){
	echo 'column1 column2 colum3'
}
test_config_vendor_file_single_ws_output(){
	echo "1 $( test_config_vendor_file_entries_single_line )" 
}
test_config_section_settings_extract(){
	assert_true test_config_section_settings_extract_all_good
	assert_true test_config_section_settings_extract_name_starts_with_at_least_3_characters
	assert_true test_config_section_settings_extract_section_qualifier_between_words
	assert_true test_config_section_settings_extract_name_contains_illegal_characters
	assert_true test_config_section_settings_extract_name_less_than_3_characters
	assert_true test_config_section_settings_extract_name_period_start
	assert_true test_config_section_settings_extract_name_period_end
	assert_true test_config_section_settings_extract_name_values_empty
	assert_true test_config_section_settings_extract_empty_section
	assert_true test_config_section_settings_extract_strip
	assert_true test_config_section_settings_extract_prior_def
	assert_true test_config_section_settings_extract_prior_def_change
}
test_config_section_settings_extract_all_good(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config_section_settings_extract '[test] --strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[test]}" == "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component=2 --wildcards */component" ]'
}
test_config_section_settings_extract_name_starts_with_at_least_3_characters(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config_section_settings_extract '[tes] --strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[tes]}" == "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component=2 --wildcards */component" ]'
}
test_config_section_settings_extract_section_qualifier_between_words(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config_section_settings_extract '[tes.it]--strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[tes.it]}" == "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component=2 --wildcards */component" ]'
}
test_config_section_settings_extract_name_contains_illegal_characters(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config_section_settings_extract '[tesiti!] --strip-component=2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 0 ]'
}
test_config_section_settings_extract_name_less_than_3_characters(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config_section_settings_extract '[te] --strip-component 2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
}
test_config_section_settings_extract_name_period_start(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config_section_settings_extract '[.te] --strip-component 2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
}
test_config_section_settings_extract_name_period_end(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_false	"config_section_settings_extract '[test.] --strip-component 2 --wildcards */component' 'pasSectionDefs' 'pasTarOpts'"
}
test_config_section_settings_extract_name_values_empty(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config_section_settings_extract '[tes.it]  ' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 0 ]'
	assert_true '[ -z "$pasTarOpts" ]'
}
test_config_section_settings_extract_empty_section(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config_section_settings_extract '[test.section]' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 0 ]'
	assert_true '[ -z "$pasTarOpts" ]'
}
test_config_section_settings_extract_strip(){
	local -A pasSectionDefs
	local pasTarOpts
	assert_true	"config_section_settings_extract '[test.section] --strip-component 3' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[test.section]}" = "$pasTarOpts" ]'
	assert_true '[ "$pasTarOpts" = "--strip-component 3" ]'
}
test_config_section_settings_extract_prior_def(){
	local -A pasSectionDefs
	local pasTarOpts
	local -r tarOptsExpected='--wildcards ./ --strip-component 5'
	assert_true "config_section_settings_extract '[test.section] $tarOptsExpected' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
	pasTarOpts=''
	assert_true	"config_section_settings_extract '[test.section]' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
}
test_config_section_settings_extract_prior_def_change(){
	local -A pasSectionDefs
	local pasTarOpts
	local -r tarOptsExpected='--wildcards ./ --strip-component 5'
	assert_true "config_section_settings_extract '[test.section] $tarOptsExpected' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
	pasTarOpts=''
	assert_true	"config_section_settings_extract '[test.section]' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptsExpected" ]'
	pasStripVal=''
	local -r tarOptNewVal='--strip-component 6'
	assert_true	"config_section_settings_extract '[test.section] $tarOptNewVal' 'pasSectionDefs' 'pasTarOpts'"
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "$pasTarOpts" = "$tarOptNewVal" ]'
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
	assert_true "config_install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '/home/dev/' '--strip-component=5'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "/home/dev//component" ]]'
	assert_true '[[ "$pasTarOpts" == '\''--strip-component=5'\'' ]]'
}
test_config_install_with_strip_wildcards(){
	assert_true "config_install 'component' 'https://github.com/WhisperingChaos/config.sh' 'master' '/home/dev/' '--strip-component=5 --wildcards config.include.sh'"
	assert_true '[[ "$pasRepoVersion" == '\''https://github.com/WhisperingChaos/config.sh/tarball/master'\'' ]]'
	assert_true '[[ "$pasComponentLocalPath" == "/home/dev//component" ]]'
	local opts="--strip-component=5 --wildcards config.include.sh"
	assert_true '[[ "$pasTarOpts" == "$opts" ]]'
}
test_config_section_default_bash_component(){
	local -A pasSectionDefs
	local -r expected='--strip-component=1 --wildcards '\''*/component'\'
	assert_true "config_section_default_bash_component 'pasSectionDefs'" 
	assert_true '[ ${#pasSectionDefs[@]} -eq 1 ]'
	assert_true '[ "${pasSectionDefs[whisperingchaos.bash.component]}" == "$expected" ]'

}
test_config_entry_iterate(){
	config_install_report(){
		return
	}
	config_component_download(){
		echo "$1" --- "$2" --- "$3"
	}
	assert_true 'test_config_vendor_file_single_section | config_entry_iterate | assert_output_true test_config_vendor_file_single_section_out'  
	assert_true 'test_config_vendor_file_two_sections | config_entry_iterate | assert_output_true test_config_vendor_file_two_sections_out'
	assert_true 'test_config_vendor_file_reference_prior_sections | config_entry_iterate | assert_output_true test_config_vendor_file_reference_prior_sections_out'
	assert_true 'test_config_vendor_file_default_section | config_entry_iterate | assert_output_true test_config_vendor_file_default_section_out'
}
test_config_vendor_file_single_section(){
cat <<vendor_iterate_test
$config_VENDOR_FILE_SCOPE_MARK local vendorDir='~/'
1 [section] --strip-component=1 --wildcards '*.include.sh'
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relComponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}	
test_config_vendor_file_single_section_out(){
cat <<vendor_iterate_test_out
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.include.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=1 --wildcards '*.include.sh'
vendor_iterate_test_out
}
test_config_vendor_file_two_sections(){
cat <<vendor_iterate_test
$config_VENDOR_FILE_SCOPE_MARK local vendorDir='~/'
1 [section] --strip-component=1 --wildcards '*.include.sh'
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relComponentPath2' 'repoUrl2' 'repoVer2'
5 [section2] --strip-component=2 --wildcards "*.sh"
6 relComponentPath repoUrl repoVer
7 relComponentPath1 repoUrl1 repoVer1
8 'relComponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}	
test_config_vendor_file_two_sections_out(){
cat <<vendor_iterate_test_out
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.include.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=2 --wildcards "*.sh"
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=2 --wildcards "*.sh"
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=2 --wildcards "*.sh"
vendor_iterate_test_out
}
test_config_vendor_file_reference_prior_sections(){
cat <<vendor_iterate_test
$config_VENDOR_FILE_SCOPE_MARK local vendorDir='~/'
1 [section] --strip-component=1 --wildcards '*.include.sh'
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
test_config_vendor_file_reference_prior_sections_out(){
cat <<vendor_iterate_test_out
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.include.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl2/tarball/repoVer2 --- ~//relCom ponentPath2 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=2 --wildcards "*.sh"
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=2 --wildcards "*.sh"
repoUrl2/tarball/repoVer2 --- ~//relCom ponentPath2 --- --strip-component=2 --wildcards "*.sh"
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=1 --wildcards '*.include.sh'
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl2/tarball/repoVer2 --- ~//relComponentPath2 --- --strip-component=1 --wildcards '*.include.sh'
repoUrl/tarball/repoVer --- ~//relComponentPath --- --strip-component=2 --wildcards "*.sh"
repoUrl1/tarball/repoVer1 --- ~//relComponentPath1 --- --strip-component=2 --wildcards "*.sh"
repoUrl2/tarball/repoVer2 --- ~//relCom\ ponentPath2 --- --strip-component=2 --wildcards "*.sh"
vendor_iterate_test_out
}	
test_config_vendor_file_default_section(){
cat <<vendor_iterate_test
$config_VENDOR_FILE_SCOPE_MARK local vendorDir=/home/dev/
1 [whisperingchaos.bash.component]
2 relComponentPath repoUrl repoVer
3 relComponentPath1 repoUrl1 repoVer1
4 'relComponentPath2' 'repoUrl2' 'repoVer2'
vendor_iterate_test
}
test_config_vendor_file_default_section_out(){
cat <<vendor_iterate_test
repoUrl/tarball/repoVer --- /home/dev//relComponentPath --- --strip-component=1 --wildcards '*/component'
repoUrl1/tarball/repoVer1 --- /home/dev//relComponentPath1 --- --strip-component=1 --wildcards '*/component'
repoUrl2/tarball/repoVer2 --- /home/dev//relComponentPath2 --- --strip-component=1 --wildcards '*/component'
vendor_iterate_test
}
test_config_msg_error(){
	assert_true 'test_config_msg_error_generate | assert_output_true test_config_msg_error_expected'
}
test_config_msg_error_generate(){
	config_msg_error "testing error message" 2>&1 
}
test_config_msg_error_expected(){
	echo "${assert_REGEX_COMPARE}error: msg='testing error message' func_name='test_config_msg_error_generate' line_no=[0-9]+ source_file='./config.sh' time=.*"
}
test_config_tree_walk(){
	local myRoot="$1"

	local pasTempFileNm
	# reset any source changes
	source "$myRoot/config.include.sh"
	assert_true  "test_config_vendor_temp_file_create test_config_tree_walk_generate_one_component_vendor 'pasTempFileNm'"
	assert_true 'config_vendor_tree_walk "$(dirname "$pasTempFileNm")"|assert_output_true test_config_tree_walk_generate_one_component_vendor_output' 
	test_config_vendor_temp_file_destroy "$pasTempFileNm"
	assert_true  "test_config_vendor_temp_file_create test_config_tree_walk_generate_bad_component_vendor 'pasTempFileNm'"
	assert_true 'test_config_tree_walk_one_bad "$pasTempFileNm" 2>&1 |assert_output_true test_config_tree_walk_generate_bad_component_vendor_output' 
	test_config_vendor_temp_file_destroy "$pasTempFileNm"
}
test_config_tree_walk_generate_one_component_vendor(){
	cat <<'vendorfile'
#<vendor.config:1.0>
[whisperingchaos.bash.component]
assert	https://github.com/WhisperingChaos/assert.include.sh master
vendorfile
}
test_config_tree_walk_generate_one_component_vendor_output(){
	echo "${assert_REGEX_COMPARE}^info\: msg\='Downloading \& installing repo\='https\://github\.com/WhisperingChaos/assert\.include\.sh' ver='master' to directory='/tmp/.+assert.*"
}
test_config_tree_walk_one_bad(){
( config_vendor_tree_walk "$(dirname "$1")")
}
test_config_tree_walk_generate_bad_component_vendor(){
	cat <<'vendorfile'
#<vendor.config:1.0>
[whisperingchaos.bash.component]
assert	https://github.com/WhisperingChaos/doesnotexist master
vendorfile
}
test_config_tree_walk_generate_bad_component_vendor_output(){
	echo "${assert_REGEX_COMPARE}^info\: msg='Downloading \& installing repo\='https\://github.com/WhisperingChaos/doesnotexist' ver\='master' to directory\='/tmp/test_config_vendor.+/assert.*"
}

main(){
	config_executeable "$(dirname "${BASH_SOURCE[0]}")" 
	test_config_vendor_banner_detected
	test_config_vendor_shebang_detected
	test_config_vendor_read
	test_config_vendor_whitespace_exclude
	test_config_section_settings_extract
	test_config_install
	test_config_section_default_bash_component
	test_config_entry_iterate
	test_config_msg_error
	test_config_tree_walk "$(dirname "${BASH_SOURCE[0]}")" 
	assert_raised_check
}
main
