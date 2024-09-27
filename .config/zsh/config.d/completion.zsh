# Smart case completion. Case sensitive if upper case letters are used.
# Second rule enables completion at ".", "_" and "-". Example: f.b -> foo.bar
# Third rule enables completion on the left. Example: bar -> foobar
zstyle ':completion:*' matcher-list 'm:{[:lower:]-_}={[:upper:]_-}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Disable hashing for list of executables
zstyle ":completion:*:commands" rehash 1

# Fixed slow git autocompletion.
__git_files () {
    _wanted files expl 'local files' _files
}
