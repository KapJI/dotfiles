-- nvim-colorizer.lua: highlight CSS-style colors inline (#ff0080, rgb(...),
-- hsl(...), etc.) with the actual color rendered as the background of the
-- token. Most useful in CSS / theme configs / colorschemes / yaml configs
-- with color values.
--
-- Using the catgoose fork — the original norcalli/nvim-colorizer.lua has
-- been unmaintained for years; catgoose is the de-facto continuation.
return {
  {
    "catgoose/nvim-colorizer.lua",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = { "*" },                       -- enable everywhere; opt-out via the user_default_options table below
      user_default_options = {
        RGB         = true,                       -- #RGB hex codes
        RRGGBB      = true,                       -- #RRGGBB hex codes
        RRGGBBAA    = true,                       -- #RRGGBBAA hex codes (with alpha)
        AARRGGBB    = false,                      -- 0xAARRGGBB hex (Android-style); rarely useful
        names       = false,                      -- "red", "blue" — too noisy in regular code; flip on for CSS files if needed
        rgb_fn      = true,                       -- rgb(...) / rgba(...) functions
        hsl_fn      = true,                       -- hsl(...) / hsla(...) functions
        css         = false,                      -- composite of names + RRGGBB + rgb_fn + hsl_fn (covered individually above)
        css_fn      = false,                      -- composite of rgb_fn + hsl_fn
        tailwind    = false,                      -- flip to "normal" or "lsp" if you write Tailwind
        sass        = { enable = false },
        mode        = "background",               -- "background" | "foreground" | "virtualtext"; bg shows token over the actual color
        virtualtext = "■",
      },
      -- Per-filetype overrides — turn on color names in CSS/theme files where they're useful.
      ["css"]  = { names = true },
      ["scss"] = { names = true },
      ["html"] = { names = true },
    },
  },
}
