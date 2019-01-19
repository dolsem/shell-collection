# Shell Collection
[![License: MIT][license-image]][license-url]
## Installation
```sh
$ git clone https://github.com/dolsem/shell-collection && ./install.bash
```
## Overview
#### Below is an overview of the repository by directory.
- **functions** - useful shell functions (commands). Zsh-compatible.
  - **gdiff** - diff with git-like visualization
  - **git** - git wrapper with useful subcommands
  - **lynxmd** - view Markdown from terminal (requires pandoc and lynx)
  - **theme** - fast switching of oh-my-zsh themes
- **util** - useful functions for usage in scripts (bash)
  - **filesystem**
    - **abspath**
  - **network**
    - **get_ip**
  - **os**
    - **is_macos**
  - **prompt**
    - **prompt_with_default**
    - **prompt_for_bool**
    - **prompt_for_file**
    - **prompt_for_option**
    - **prompt_for_multiselect**
  - **string**
    - **strip_whitespace**
  - **term**
    - **output colors**
  - **validation**
    - **is_valid_ip**

[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: https://opensource.org/licenses/MIT