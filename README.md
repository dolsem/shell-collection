# Shell Collection
[![License: MIT][license-image]][license-url]
## Installation
```sh
$ git clone --recursive https://github.com/dolsem/shell-collection && cd shell-collection && bash install.bash
```
## What's included
#### Below is the list of items that can be installed with the installation script.
- [**Oh My Zsh**][ohmyzsh-url]
- **Shell scripts && shell functions**
- **Setting extra environment variables**
  - Make Vim default editor

## Repository Overview
#### Below is an overview of the repository by directory.
- **functions** - useful shell functions (commands). Zsh-compatible.
  - **pipe** - opens named pipe and reads in a loop, closes on SIGINT
  - **gdiff** - diff with git-like visualization
  - **lynxmd** - view Markdown from terminal (requires pandoc and lynx)
  - **theme** - fast switching of oh-my-zsh themes
- **scripts** - useful shell scripts (commands). Zsh-compatible.
  - **git** - git wrapper with useful subcommands
  - **bind-dns** - runs bind DNS server in docker container
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
  - *output colors*
  - **reset_color**
- **validation**
    - **is_valid_ip**

[license-image]: https://img.shields.io/badge/License-MIT-blue.svg
[license-url]: https://opensource.org/licenses/MIT
[ohmyzsh-url]: https://github.com/robbyrussell/oh-my-zsh
