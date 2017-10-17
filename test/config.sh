#!/bin/bash
config_executeable(){
	local -r myRoot="$1"
	# include components required to create this executable
	local mod
	for mod in $( "$myRoot/composer/include.composer.sh" "$myRoot"); do
		source "$mod"
	done
	# include component to be tested 
	source "$myRoot/config.include.sh"
}

test_config_vendor_file_banner_detected(){
	assert_true "echo '#<vendor.config:1.0>' | config_vendor_file"
	assert_true 'test_config_vendor_file_banner_white_space | config_vendor_file'
	assert_true 'test_config_vendor_file_banner_detect_anywhere | config_vendor_file'
	assert_false "echo '#<vendor.config:.0>' | config_vendor_file"
	assert_false "echo 'bad#<vendor.config:.0>' | config_vendor_file"
}

test_config_vendor_file_banner_white_space(){
	echo ' 	#<vendor.config:1.0>' 
}

test_config_vendor_file_banner_detect_anywhere(){
	echo '# hi there!'
	echo '#<vendor.config:1.0>' 
}

test_config_vendor_file_entries(){
	assert_true 'test_config_vendor_file_entries_single_line | config_vendor_file_entries | assert_output_true test_config_vendor_file_entries_single_line'
	assert_true 'test_config_vendor_file_entries_single_line_comments | config_vendor_file_entries | assert_output_true test_config_vendor_file_entries_single_line'
}

test_config_vendor_file_entries_single_line(){
	echo 'column1 column2 colum3'
}
test_config_vendor_file_entries_single_line_comments(){
	echo '#<vendor.config:1.0>'
	test_config_vendor_file_entries_single_line
	echo '# my comment'
	echo '# another comment'
}

test_config_vendor_path_append(){
	assert_true 'test_config_vendor_path_parents | config_vendor_path_append "/vendor" | assert_output_true test_config_vendor_path_parents_with_vendor'
}	

test_config_vendor_path_parents(){
cat <<vendor_path_parents
col1 col2 col3
col1.1 col2.1 col3.1
vendor_path_parents
}	

test_config_vendor_path_parents_with_vendor(){
cat <<vendor_path_parents
col1 col2 col3 /vendor
col1.1 col2.1 col3.1 /vendor 
vendor_path_parents
}	

config_executeable  "$(dirname "${BASH_SOURCE[0]}")" 

# invoke tests

test_config_vendor_file_banner_detected
test_config_vendor_file_entries
test_config_vendor_path_append
