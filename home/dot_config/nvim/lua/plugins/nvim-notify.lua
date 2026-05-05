-- nvim-notify — backend for noice's notify view (see noice.lua).
-- Loaded as a noice dependency, but lazy.nvim doesn't auto-configure
-- dependencies. This spec adds an opts table so notify.setup() runs.
--
-- merge_duplicates default (true) silently collapses repeat messages
-- once the first toast has faded, so a second `:badcmd` produces no
-- visible notification. Disable it: each repeated error/warn should
-- still pop a fresh toast.
return {
  "rcarriga/nvim-notify",
  main = "notify",
  opts = {
    merge_duplicates = false,
  },
}
