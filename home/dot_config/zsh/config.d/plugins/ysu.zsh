# you-should-use
YSU_MESSAGE_POSITION="after"
# Don't nag about the vim=nvim alias when typing nvim directly.
YSU_IGNORED_ALIASES=("vim")
# Literal SGR escapes instead of tput — saves four forks per startup.
COLOUR_NONE=$'\e[0m'
COLOUR_BOLD=$'\e[1m'
COLOUR_YELLOW=$'\e[33m'
COLOUR_PURPLE=$'\e[35m'
YSU_MESSAGE_FORMAT="${COLOUR_BOLD}${COLOUR_YELLOW}\
Found existing %alias_type for ${COLOUR_PURPLE}\"%command\"${COLOUR_YELLOW}. \
You can use ${COLOUR_PURPLE}\"%alias\"${COLOUR_YELLOW} instead.${COLOUR_NONE}"
