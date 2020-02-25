![CI](https://github.com/WhisperingChaos/config.sh/workflows/CI/badge.svg)

#<vendor.config:1.0>
###############################################################################
#
#	Purpose:
#		Defines components that are used to create the current component. Given
#		this definition, the script: config.sh will download from github and
#		install the component to a local directory.
#
#		A dependent component may also represent an aggregrated component too.
#		In this case, a vendor.config file in its "conceptual" root directory 
#		is recursively processed to configure this dependent (sub) component.
#
#	Usage:
#		There are two "types" of vendor.config files:
#		> Static  - A text file whose contents are directly consumed by config.sh.
#		> Dynamic - A shebang file, that's executed as a subprocess by config.sh,
#		whose captured STDOUT conforms to the format defined for the static
#		file. Dynamic execution constructs the contents of vendor.config
#		using the facilities of any programming language enabling 
#		imagination.
#
#
#	File Format/Interface:
#		> File must include a banner that complies with the following regex:
#			^[[:space:]]*#<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+>$ 
#			For statically defined files, this mark must appear as first
#			line in the file.
#			For dynamically defined files, this mark must appear after the
#			shebang line that at least matches the following:
#			'#!/' 
#		> One or more sections follow a banner.  A section consists of a name
#			and a list of zero or more parameters used to control the files
#			extracted from a github repository.  A section maybe repeated in
#			a file and if its parameters are omitted, it inherits the ones
#			defined by the immediate prior definition that shares the same name.
#			A section can be redefined with new parameters.  In this situation,
#			nothing is inherited from a pre-existing declaration.  Finally, declaring
#			a new section without specifying any parameters simply downloads
#			the entire working tree (excluding .git) of the desired repository
#			version. 
#			
#			A section name complies with the following pattern:
#			^\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\](.*)$
#
#			This name may be followed by a list of options supported by tar.  For example,
#			tar options such as '--strip-component' and '--wildcards' can be specified
#			and are appended to the tar command in exactly the same order as
#			they appear.
#
#			ex: "[whisperingchaos.bash.component] --strip-component=1 --wildcards 'component/*'"
#
#			Elimate the repository root directory and copy all files from the
#			'component' directory - ignoring any other files in the repository.
#
#		> Component entries follow the a section.  A component is a unit of reuse.
#			Other components may consume other components to create aggregrate ones.
#			Compnents can be executable or simply "included" to construct an 
#			aggregrated one.  Components are typically scripts, executables, source
#			files, configuration files - essentially any object you wish to reused
#			that's expressed as one or more files.
#			
#			Component entries adhere to the following form:
#			> Relative Path - a path relative to the directory containing
#				the vendor.config file.  Better ensures a component's components
#				are encapsulated within the aggregrate (root) component.  If the 
#				path produced by appending the Relative Path to the one that 
#				defines by the location of the vendor.config file doesn't exist,
#				it will be created.  Pre-existing files and directories that overlap
#				the ones being extracted by tar adhere to tar's replacement rules. 
#			> Github Repository Path - a github routing specification used to locate
#				the desired component's repository (repo).
#			> Branch/Tag/Commit Hash - a git label that specifies the desired
#				component's repo version.
#
#			All columns must be assigned a value and be separated from each other
#			by at least a single whitespace.  Use quotes or escape '\' to preserve
#			embedded whitespace.
#
#		Misc:
#			> Single full line comments are supported.  However, uncommented
#				input followed by a comment causes the minimal parser to consider
#				this partial line comment as data.
#			> Blank lines are ignored.
#
############################################################################### 
[whisperingchaos.bash.component]
'sourcer'	'https://github.com/WhisperingChaos/sourcer.sh'	'master'
