-- Explicit dependency. plenary is used at runtime (transitively by fzf-lua
-- and others) and by the test harness under tests/nvim. Declaring it here
-- pins it as a first-class plugin so the tests don't rely on it being
-- pulled in incidentally by another plugin.
return {
  "nvim-lua/plenary.nvim",
  lazy = true,
}
