New Release Process:
- In new host directory:
  - ```git clone https://github.com/WhisperingChaos/config.sh.git```
- Configure and run unit tests on the current master branch:
  ```
  >cd ./test
  >./config.sh
  >./config_test.sh
  ```
- If testing fails, fix and rerun.
- Determine the [semantic version](https://semver.org/) numbers for config.sh and its bundled components:
  - Review prior [annotated tag](https://github.com/WhisperingChaos/config.sh/releases) for repository *config.sh* and determine its new version number.  Once determined:
    - Edit: [```./component/config.sh```](./component/config.sh)
    - Search for the variable ```configSh__vendor_version```.
    - Replace its value with the new version number.
    - Save the change.
    - Notes
      - The new composite version number should always be greater than the old one.
  - Review the commit log for file [```./component/config_sh/base/config.source.sh```](./component/config_sh/base/config.source.sh), if it's changed:
    - Edit this file.
    - Search for the variable ```config__COMPONENT_SEMANTIC_VERSION```.
    - Replace its value with a new version number.
    - Save the change.
    - Notes
      - The new composite version number should always be greater than the old one.
      - Since it represents a *package*, it can be independently consumed :: it's assigned a separate version number.  In other words its version number doesn't necessarily need to be the same as the one assigned to ```./component/config.sh```.  They are different components.  Although ```./component/config.sh``` relies on ```./component/config_sh/base/config.source.sh``` the relationship isn't symmetric. 
  - Review the commit log for file [```./README.md```](./README.md) and [```./component/config_sh/base/config.source.sh```](./component/config_sh/base/config.source.sh), if either of these files suggest that the format (interface) of this file has changed then:
    - Edit the following file: [```./component/config_sh/base/config.source.sh```](./component/config_sh/base/config.source.sh).
    - Search for the variable ```config__VENDOR_CONFIG_SEMANTIC_VERSION```.
    - Replace its value with a new version number.
    - Save the change.
    - Notes
      - As above, the format of ```vendor.config``` isn't fully functionally dependent on the other components of this repository :: it's assigned a different version variable.
      - Currently, the ```config.source.sh``` package located in file ```./component/config_sh/base/config.source.sh``` doesn't need this variable as a [control couple](https://en.wikipedia.org/wiki/Coupling_(computer_programming)).  However, future versions might.  Therefore, this version number may already reflect the correct one.
  - After applying these changes, run the unit tests.  These tests **should fail** because they assert the prior semantic version values instead of the new ones.
  - Fix the assert version tests located in [```./test/config_test.sh```](./test/config_test.sh).
- Create annotated tag:
  -  Replace the variables below with their variable values found in the source even if they haven't changed.
    - ```git tag -a <<configSh__vendor_version>> -m "./component/config.sh: <<configSh__vendor_version>>, ./component/config_sh/base/config.source.sh: <<config__COMPONENT_SEMANTIC_VERSION>>, vendor.config: <<config__COMPONENT_SEMANTIC_VERSION>> "```
  - Push tag to github:
    - ```git push origin --tag # new tag```

