# Facebook stuff
local fb_config="/usr/facebook/ops/rc/master.zshrc"
if [ -f "$fb_config" ]; then
    source "$fb_config"
fi

# Facebook hg prompt
WANT_OLD_SCM_PROMPT="true"
local fb_prompt_file="/opt/facebook/share/scm-prompt"
if [ -f "$fb_prompt_file" ]; then
    source "$fb_prompt_file"
elif [[ -v LOCAL_ADMIN_SCRIPTS ]]; then
    source "$LOCAL_ADMIN_SCRIPTS/scm-prompt"
fi
