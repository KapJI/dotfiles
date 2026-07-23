-- echasnovski/mini.ai — extends vim's i/a text-object grammar with
-- last/next modifiers (cin) cil" etc.) and additional textobjects.
--
-- Conflict avoidance: mini.ai's built-in defaults include f (function
-- CALL), a (argument), and b (any balanced bracket). Treesitter-
-- textobjects already owns the same letters with different meanings
-- (@function, @parameter, @block — i.e. function DEFINITION, argument,
-- and if/for/while body). Disabling them in mini.ai so the
-- treesitter versions stay authoritative; otherwise `vinf` picks the
-- next function CALL's args (e.g. `(self)`) instead of the next
-- function definition.
--
-- Q is also disabled — vim's built-in i'/i"/i` already cover quotes,
-- and `q` is more useful free.
--
-- What mini.ai keeps providing:
--   ( ) [ ] { } < > ' " `   bracket / quote pairs (with l/n modifiers!)
--   t                       HTML/XML tag
--   ?                       user-prompt: type any pair on the fly
--
-- The l/n modifiers (last/next) work on ALL of the above:
--   cin)   change inside the next ()
--   dil"   delete inside the previous ""
--   van]   visual around the next []
return {
    "echasnovski/mini.ai",
    event = { "BufReadPost", "BufNewFile" },
    opts = {
        n_lines = 500, -- limit search range so massive files don't stall
        custom_textobjects = {
            f = false, -- defer to treesitter-textobjects' @function (definition, not call)
            a = false, -- defer to treesitter-textobjects' @parameter
            b = false, -- defer to treesitter-textobjects' @block
            q = false, -- vim's built-in i'/i"/i` already covers quotes
        },
        -- l/n (last/next) modifiers are enabled by default; no setting needed.
    },
}
