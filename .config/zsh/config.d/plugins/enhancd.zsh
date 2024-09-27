# Enhacd configuration
case $(type "...") in
    (*alias*) unalias "...";;
esac

ENHANCD_FILTER=fzf
ENHANCD_ARG_DOUBLE_DOT="..."
ENHANCD_ENABLE_HOME=false
# Breaks "cd ."
# ENHANCD_USE_ABBREV=true
