![CI](https://github.com/WhisperingChaos/config.sh/workflows/CI/badge.svg)

## Config.sh

Recursively walks a local file system branch, rooted at a provided directory, searching for a file named ```vendor.config```.  Once found, it uses entries defined within this file to download and save a repository's working files locally.

The recursive walk first processes the ```vendor.config```, if it exists, in the root (current) directory before deeply diving into one of its subdirectories to locate others before it broadly traverses other subdirectories in this root (current) directory.  The visiting is ordered by the collating sqeuence of the directory names.  These ordering properties can be applied to, for example, to enable a 'bootable' ```vendor.config``` - one that downloads and installs other ```vendor.config```s to other branches within the specified root, as these will be later visited.

[config.sh](./component) download behavior relies on Github's tarball API.  Therefore, only working files of a specified version are downloaded - **not** the .git repository (versioning data).  Additionally, this tarball is piped into [tar](http://manpages.ubuntu.com/manpages/bionic/man1/tar.1.html) and through use of tar selection options, like ```--anchored```, ```--strip-components```, and ```--wildcards```, specific artifacts can be extracted and locally saved.  Please review [vendor.config](#vendorconfig) section below 

Although the features of this script can be broadly applied, it was written as a tool to enable constructing scripts that adhere to principles outlined by [SOLID_Bash](https://github.com/WhisperingChaos/SOLID_Bash).

### Install
```config.sh``` script can be either dynamically incroporated or statically copied into a project (repository).  Dynamic incorporation reduces your project's repository footprint as it relies on a simple bootstrap script which when executed downloads and runs ```config.sh```.  Also, the default bootstrap behavior delivers the latest version of ```config.sh```.  Meanwhile, the static method replicates a copy of a desired version of ```config.sh``` into a project.  This method eliminates the dependency between the consuming project and this repository.  It also guarantees the consistency of ```config.sh```'s behavior and interface.

#### Dynamic Bootstrap
Copy [```./bootstrap/config.sh```](./bootstrap/config.sh) to an appropriate directory in your project.  By default, running this ```config.sh``` proxy will download and install the actual one to a subdirectory named ```config_sh``` whose parent contains the proxy.  After completing the download, the proxy will execute the actual ```config.sh``` and by default treat the ```config_sh/vendor``` directory as the root to begin its search for ```vendor.config```.  These defaults can be overridden.  View the comments in [```./bootstrap/config.sh```](./bootstrap/config.sh) for the order and descriptions of arguments.

Use the following to download the latest bootstrap:
```
>wget -O - "https://github.com/WhisperingChaos/config.sh/tarball/master" | tar -xz -C ./  --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/bootstrap'
```

#### Static Include
Use ```wget``` below to copy the desired version of ```config.sh``` to the currnet working directory.  Replace ```<version>``` with the desired repository branch, tag, or commit hash label:

```
>wget --dns-timeout=5 --connect-timeout=10 --read-timeout=60 -O - "https://github.com/WhisperingChaos/config.sh/tarball/<version>" | tar -xz -C ./  --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component'
```

### Usage

```
usage: config.sh [OPTION] [ARGUMENT]

Search for and download components defined in a 'vendor.config' file.
Save each downloaded file to its specified directory.  Perform this process
for the provided directory and recursively dive deeply into each of
its subdirectories. 

OPTION:

  --sample     Display sample 'vendor.config' file & exit.
  -h,--help    Display help & exit.
  -v,--version Display version information & exit.

ARGUMENT:

  <FilePath>  A file path that identifies the root directory to begin
              searching for a 'vendor.config'.  If unspecified, the
              process begins in the directory containing the config.sh
              script.  Promotes installing config.sh to <FilePath>.
              Moreover, encourages using symbolic links to a single 
              copy of config.sh in projects containing many
              configurable components as a means of specifying the
              <FilePath> without having to provide it as a parameter.
              For this invocation the <FilePath> would
              be: '$(dirname "$0")'.

Visit: https://github.com/WhisperingChaos/config.sh#configsh for further
information and to report bugs.

```

### vendor.config

#### Purpose

Define one or more aggregate components through the composition of shared, more elemental ones.  The elemental components can exist in various github repositories.

#### Sample
To generate the sample contents of a ```vendor.config``` execute ```./config.sh --sample``` in a terminal.  This command should produce:

```
#<vendor.config:v1.0>
# banner above ^
# this is a comment
# section name:
[whisperingchaos.bash.component]
# entry within a section:
# Path            github Address to Repository                           Branch/Tag/Commit Hash
'sourcer'        'https://github.com/WhisperingChaos/sourcer.sh'        'master'
'base'           'https://github.com/WhisperingChaos/assert.source.sh'  'v1.0'

# See Formal Spec: https://github.com/WhisperingChaos/config.sh/blob/v1.1/README.md#vendorconfig

```

#### Format

##### Banner

  - A file must include a Banner that complies with the following regex: ```^[[:space:]]*#<vendor\.config:([[:alnum:]]+[.-][[:alnum:]]+)+>$```. For statically defined files, this mark must appear as first line in the file. For dynamically defined files, this mark must appear after the shebang line that at least matches the following: ```#!/```.  See [Static vs Dynamic](#static-vs-dynamic).

##### Section 

  - One or more sections follow a [Banner](#banner).  It defines a consistent set of ```tar``` download options applied to each [Component Entry](#component-entry).   A section consists of a name	and a list of zero or more parameters used to control the files extracted from a github repository.  A section maybe repeated in a file and if its parameters are omitted, it inherits the ones defined by the immediate prior definition that shares the same name.  A section can be redefined with new parameters.  In this situation, nothing is inherited from a pre-existing declaration.  Finally, declaring a new section without specifying any parameters simply downloads the entire [working tree](https://stackoverflow.com/questions/3689838/whats-the-difference-between-head-working-tree-and-index-in-git) (excluding .git) of the specified repository version.

  - A section name complies with the following pattern: ```^\[([[:alpha:]][[:alnum:]]+([[:alnum:]]+\.[[:alnum:]]+|[[:alnum:]])+)\](.*)$```.  This name may be followed by a list of options supported by [tar](http://manpages.ubuntu.com/manpages/bionic/man1/tar.1.html).  For example, tar options such as ```--strip-component``` and ```--wildcards``` can be specified and are appended to the tar command in exactly the same order as they appear:

```
# For every component entry following the section named 'whisperingchaos.bash.component'
# elimate the repository root directory and recursively copy all files from
# the 'component' directory - ignoring any other files in the tarball.
"[whisperingchaos.bash.component]  --strip-component=2 --wildcards --no-wildcards-match-slash --anchor '*/component''"
```

##### Component Entry

  - Component entries follow a [Section](#section).  A component is a unit of reuse.  An aggregate component consumes other components to define itself. Components can be executable or simply "included" to construct an aggregrate one.  Components are typically scripts, executables, source files, configuration files - essentially any object you wish to reused	that's expressed as one or more files.

  - An Entry consists of the following fields all appearing on the same line:

    - Path - A relative or absolute directory reference.  A relative directory reverence is anchored to the directory containing the ```vendor.config file```.  Example: if the Path's value were '.' *(current directory)*, the downloaded file(s) would appear in the same directory as the ```vendor.config``` file.  Although this field supports specifying an absolute directory reference, relative paths are highly recommended.  A relative path is adaptive, as it automatically adjusts to variations in directory structures external to its relative scope.  It also better ensures components are encapsulated within an aggregrate (root) component.  If the path produced by appending the relative path to the one that defines the location of the vendor.config file doesn't exist, it will be created.  Absolute directory references are handled the same way.  Pre-existing files and directories that overlap the ones being extracted by tar adhere to its replacement rules.

    - Github Repository Path - A github routing specification used to locate the desired component's repository (repo).

    - Branch/Tag/Commit Hash - A git label that specifies the desired component's repo version.

All columns must be assigned a value and be separated from each other	by at least a single whitespace.  Use quotes or escape ('\\') to preserve embedded whitespace.

#### Static vs Dynamic

The format of a ```vendor.config``` represents an interface that's consumed by ```config.sh```.  This interface can be statically or dynamically constructed:
  - Static - A text file whose contents directly reflect the format defined above and is immediately consumed by ```config.sh```.
  - Dynamic - A shebang file, whose second line starts with a ```config.sh```'s [Banner](#banner).  When detected, ```config.sh``` executes this file as a subshell to ```config.sh```.  The STDOUT of this subshell is captured and processed like any statically defined ```vendor.config``` file.

#### Miscellaneous 

  - Single full line comments are supported.  However, uncommented input followed by a comment causes the minimal parser to consider this partial line comment as data.
  - Blank lines are ignored.
