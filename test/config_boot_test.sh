#!/bin/bash
sourcer__build_CONFLICT_EXCEPTION=enable
sourcer__build_funcvar_exception_categorize(){ return 1; }
source ./config_boot_test_sh/sourcer/base/sourcer.build.source.sh ./config_boot_test_sh/sourcer ./config_boot_test_sh

declare -gr testFS='./config_boot_test_sh/file/'

test_default_all(){
	local -r testDir="$testFS/default_all"
	rm -rf "$testDir" 2>/dev/null
	test_config_sh_link_create "$testDir"
	assert_true '[ -e "$testDir/config.sh" ]'
	assert_output_true test_default_all_out \
		--- assert_false '"$testDir/config.sh"'
	assert_true '[ -d "$testDir/config_sh" ]'
	assert_true '[ -e "$testDir/config_sh/config.sh" ]'
}


test_default_all_out(){
	cat << TEST_DEFAULT_ALL_OUT
${assert_REGEX_COMPARE}^error: msg='Cannot access directory: "\./config_boot_test_sh/file//default_all/config_sh/vendor" either it does not exist or privilege violation occurred\.' func_name='configSh__root_dir_exist_error' line_no=[0-9]+ source_file='\./config_boot_test_sh/file//default_all/config_sh/config.sh' time='[^']+'
TEST_DEFAULT_ALL_OUT
}


test_default_all_vendor_specified(){
	local -r testDir="$testFS/default_all_vendor_specified"
	rm -rf "$testDir" 2>/dev/null
	test_config_sh_link_create "$testDir"
	test_vendor_create "$testDir/config_sh/vendor/" test_vendor_specified_in_default
	assert_true '[ -d "$testDir/config_sh" ]'
	assert_true '[ -e "$testDir/config_sh/vendor/vendor.config" ]'
	assert_output_true test_vendor_specified_in_default_out \
		--- assert_true "$testDir/config.sh"
	assert_true '[ -e "$testDir/config_sh/config.sh" ]'
	assert_true '[ -d "$testDir/config_sh/config_sh" ]'
	assert_true '[ -d "$testDir/sourcer" ]'
	assert_true '[ -e "$testDir/sourcer/sourcer.sh" ]'
	assert_true '[ -d "$testDir/test/base" ]'
	assert_true '[ -e "$testDir/test/base/assert.source.sh" ]'
}


test_vendor_specified_in_default(){
	cat <<TEST_VENDOR_SPECIFIED_IN_DEFAULT
#<vendor.config:v1.0>
[whisperingchaos.bash.component]
# Path          github repository url                                  Branch/Tag/Commit Hash
'../../sourcer'    'https://github.com/WhisperingChaos/sourcer.sh'        'master'
'../../test/base'  'https://github.com/WhisperingChaos/assert.source.sh'  'master'
TEST_VENDOR_SPECIFIED_IN_DEFAULT
}

test_vendor_specified_in_default_out(){
cat <<TEST_VENDOR_SPECIFIED_IN_DEFAULT_OUT
info: msg='Downloading & installing repo='https://github.com/WhisperingChaos/sourcer.sh' ver='master' to directory='./config_boot_test_sh/file//default_all_vendor_specified/config_sh/vendor/../../sourcer' vendor.config='./config_boot_test_sh/file//default_all_vendor_specified/config_sh/vendor' lineNum='4''
info: msg='Downloading & installing repo='https://github.com/WhisperingChaos/assert.source.sh' ver='master' to directory='./config_boot_test_sh/file//default_all_vendor_specified/config_sh/vendor/../../test/base' vendor.config='./config_boot_test_sh/file//default_all_vendor_specified/config_sh/vendor' lineNum='5''
TEST_VENDOR_SPECIFIED_IN_DEFAULT_OUT
}


test_version_specified(){
	local -r testDir="$testFS/version_specified"
	local -r configVer="v1.2"  # at least one version removed from current one.
	rm -rf "$testDir" 2>/dev/null
	test_config_sh_link_create "$testDir"
	assert_true '[ -e "$testDir/config.sh" ]'
	assert_output_true test_version_specified_out \
		--- assert_false '"$testDir/config.sh" "$configVer"'
	assert_true '[ -d "$testDir/config_sh" ]'
	assert_true '[ -e "$testDir/config_sh/config.sh" ]'
	assert_output_true echo "version: $configVer" \
		--- "$testDir/config_sh/config.sh" -v
}


test_version_specified_out(){
	cat << TEST_VERSION_SPECIFIED_OUT
${assert_REGEX_COMPARE}^error: msg='Cannot access directory: "\./config_boot_test_sh/file//version_specified/config_sh/vendor" either it does not exist or privilege violation occurred\.' func_name='configSh__root_dir_exist_error' line_no=[0-9]+ source_file='\./config_boot_test_sh/file//version_specified/config_sh/config\.sh' time='[^']+'
TEST_VERSION_SPECIFIED_OUT
}


test_install_path_specified(){
	local -r testDir="$testFS/install_path_specified"
	local -r installDir="$testDir/install_here"
	rm -rf "$testDir" 2>/dev/null
	test_config_sh_link_create "$testDir"
	assert_true '[ -e "$testDir/config.sh" ]'

	assert_output_true test_install_path_specified_out \
		--- assert_false '"$testDir/config.sh" "master" "$installDir" '
	assert_true '[ -d "$installDir" ]'
	assert_true '[ -e "$installDir/config.sh" ]'
}


test_install_path_specified_out(){
	cat << TEST_INSTALL_PATH_SPECIFIED_OUT
${assert_REGEX_COMPARE}^error: msg='Cannot access directory: "\./config_boot_test_sh/file//install_path_specified/install_here/vendor" either it does not exist or privilege violation occurred\.' func_name='configSh__root_dir_exist_error' line_no=[0-9]+ source_file='\./config_boot_test_sh/file//install_path_specified/install_here/config\.sh' time='[^']+'
TEST_INSTALL_PATH_SPECIFIED_OUT
}


test_vendor_specified(){
	local -r testDir="$testFS/vendor_specified"
	local -r installDir="$testDir/config_sh"
	rm -rf "$testDir" 2>/dev/null
	test_config_sh_link_create "$testDir"
	assert_true '[ -e "$testDir/config.sh" ]'
	local -r vendorDir="$testDir/vendor_here/"
	test_vendor_create "$vendorDir" test_vendor_specified_vendor_here
	assert_output_true test_vendor_specified_vendor_here_out  \
		--- assert_true '"$testDir/config.sh" "" "" "$vendorDir" '
	assert_true '[ -d "$installDir" ]'
	assert_true '[ -e "$installDir/config.sh" ]'
}


test_vendor_specified_vendor_here(){
	cat <<TEST_VENDOR_SPECIFIED_IN_DEFAULT
#<vendor.config:v1.0>
[whisperingchaos.bash.component]
# Path      github repository url                                  Branch/Tag/Commit Hash
'sourcer'  'https://github.com/WhisperingChaos/sourcer.sh'        'master'
'base'     'https://github.com/WhisperingChaos/assert.source.sh'  'master'
TEST_VENDOR_SPECIFIED_IN_DEFAULT
}


test_vendor_specified_vendor_here_out(){
	cat <<TEST_VENDOR_SPECIFIED_IN_DEFAULT_OUT
info: msg='Downloading & installing repo='https://github.com/WhisperingChaos/sourcer.sh' ver='master' to directory='./config_boot_test_sh/file//vendor_specified/vendor_here/sourcer' vendor.config='./config_boot_test_sh/file//vendor_specified/vendor_here' lineNum='4''
info: msg='Downloading & installing repo='https://github.com/WhisperingChaos/assert.source.sh' ver='master' to directory='./config_boot_test_sh/file//vendor_specified/vendor_here/base' vendor.config='./config_boot_test_sh/file//vendor_specified/vendor_here' lineNum='5''
TEST_VENDOR_SPECIFIED_IN_DEFAULT_OUT
}


test_config_sh_link_create(){
	local -r testDir="$1"
	
	assert_true 'mkdir -p "$testDir"'
	assert_true 'ln -s "../../../../bootstrap/config.sh" "$testDir/config.sh"'
}


test_vendor_create(){
	local -r vendorDir="$1"
	local -r configFun="$2"

	assert_true 'mkdir -p "$vendorDir"'
	assert_true '$configFun >"$vendorDir/vendor.config"'	
}


main(){
	test_default_all
	test_default_all_vendor_specified
	test_version_specified
	test_install_path_specified
	test_vendor_specified

	assert_return_code_set
}

main


