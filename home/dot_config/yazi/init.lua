-- Yazi user init — overrides for the preset components.
--
-- Spell out the mode in the status bar (NORMAL, SELECT, UNSET) instead
-- of the default 3-char abbreviation (NOR / SEL / UNS). Copied verbatim
-- from yazi-plugin/preset/components/status.lua minus the :sub(1, 3)
-- truncation. Re-check on yazi upgrades — if the preset signature
-- changes upstream, this override needs to track it.
function Status:mode()
    local mode = tostring(self._tab.mode):upper()

    local style = self:style()
    return ui.Line {
        ui.Span(th.status.sep_left.open):fg(style.main:bg()):bg("reset"),
        ui.Span(" " .. mode .. " "):style(style.main),
        ui.Span(th.status.sep_left.close):fg(style.main:bg()):bg(style.alt:bg()),
    }
end
