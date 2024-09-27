# you-should-use
YSU_MESSAGE_POSITION="after"
YSU_IGNORED_ALIASES=("hgsl" "vi")
COLOUR_NONE="$(tput sgr0)"
COLOUR_BOLD="$(tput bold)"
COLOUR_YELLOW="$(tput setaf 3)"
COLOUR_PURPLE="$(tput setaf 5)"
YSU_MESSAGE_FORMAT="${COLOUR_BOLD}${COLOUR_YELLOW}\
Found existing %alias_type for ${COLOUR_PURPLE}\"%command\"${COLOUR_YELLOW}. \
You can use ${COLOUR_PURPLE}\"%alias\"${COLOUR_YELLOW} instead.${COLOUR_NONE}"
