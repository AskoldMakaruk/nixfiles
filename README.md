This repository contains nix config for my system. 

Stated goals are:
- beautifuly napierdolena systema
- easy to use work machine all custom perdoling should be justified
- maximally confined to reasonable default where there is such 
- minimazing specific knowledge I need to remebmer to work

non-goals: 
- performance optimizations (meh I use KDE not because it is fast but because it is not so slow)
- saving time (maybe it'll payoff in a longrun)

Config is split into parts.

## System managment
- [x] done: bash aliases for easier nix life (batat stack)

## Console
Terminal emulator: tilda (for smoothscroll)
Shell: zsh
- [ ] todo: zsh plugins
- [ ] todo: getting to know tilda and it's various configurations capabilities
- [ ] todo: use direnv + nix-direnv for new package managment 
- [ ] todo: .ssh/config file from nixos repo 

## Editors
- [x] done: setup neovim
- [ ] todo: setup jetbrains tools

## Desktop enviroment
- [ ] todo: manage plasma config from home manager
- [ ] todo: hotkeys and fine shortcuts

## Development
- [ ] todo: add rust, c# as optinal dependencies 
- [a] active: setup dev postgres (nix-shell)

## Shortcuts
- [ ] todo configure KWin maximaze window meta+shift+up shortcut

## Core utils
- [ ] todo additional utils
 - usbutils
 - ripgrep
 - fzf
 - ...

## Gaming
- [x] done: steam and proton
- [ ] todo: rocket league

## Boot and disk managment
- [ ] todo: put it all in one place and never touch it again

## Audio, video, camera, cardreader and fingerprint scanner
- [ ] todo: just works

## Honorable mentions of unjustified perdoling:
- [alt] found alternative: custom alacritty fork with smooth scrooling https://github.com/alacritty/alacritty/pull/6705/files
- [crazy]: term-roulette: open random terminal emulator each time (candidates wezterm, kitty, alacritty, tilda, cool-retro-term etc.)
