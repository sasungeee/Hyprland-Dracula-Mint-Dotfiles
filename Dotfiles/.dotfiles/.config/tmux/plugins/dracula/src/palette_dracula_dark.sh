#!/bin/bash

##########################
# dracula dark palette
# matched to lualine Dracula theme (Neovim statusline)
##########################
#
# lualine Dracula reference:
#   normal.a = purple bg (#bd93f9) + black fg  → mode / left segment
#   normal.b = light_gray (#5f6a8e) + white
#   normal.c = grey (#44475a) + white          → main status bg
#
# shellcheck disable=2034

col_bg="#282a36"          # black / darkest
col_bg0_h="#21222c"
col_bg0="#282a36"
col_bg1="#44475a"         # grey — main statusbar background (lualine c)
col_bg2="#5f6a8e"         # light_gray — inactive windows / middle segments (lualine b)
col_bg3="#bd93f9"         # purple — LEFT segment like NORMAL mode (lualine a)
col_bg4="#6272a4"         # comment
col_gray0="#6272a4"
col_gray1="#6272a4"
col_gray2="#6272a4"
col_bg0_s="#343746"

col_fg="#f8f8f2"          # white
col_fg4="#6272a4"         # muted
col_fg3="#282a36"         # dark text ON purple left segment (like NORMAL)
col_fg2="#f8f8f2"
col_fg1="#f8f8f2"
col_fg0="#ffffff"

col_red="#ff5555"
col_red2="#ff6e6e"
col_green="#50fa7b"
col_green2="#69ff94"
col_yellow="#f1fa8c"
col_yellow2="#50fa7b"     # pink — current window accent
col_blue="#8be9fd"
col_blue2="#8be9fd"
col_purple="#bd93f9"
col_purple2="#d6acff"
col_aqua="#8be9fd"
col_aqua2="#a4ffff"
col_orange="#ffb86c"
col_orange2="#ffca80"
