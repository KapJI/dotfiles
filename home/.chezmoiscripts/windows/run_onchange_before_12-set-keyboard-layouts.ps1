# Configure keyboard layouts: English (US ANSI) + Russian.
#
# Goal: only two entries in the language switcher (ENG, RUS), with US-ANSI
# key semantics under ENG and the Windows UI continuing to display in
# English (United Kingdom).
#
# Win11 enforces that each input method's locale matches its parent language
# entry: putting 0409 (US kb) under en-GB causes Windows to silently split
# the list and auto-create an en-US entry. So the user language list must
# hold en-US, not en-GB. The UK display is preserved separately via
# Set-WinUILanguageOverride; the en-GB language pack stays installed (only
# Uninstall-Language removes it).

$desiredList = @(
    @{ Tag = 'en-US'; Tips = @('0409:00000409') },
    @{ Tag = 'ru';    Tips = @('0419:00000419') }
)
$desiredUI = 'en-GB'

$current = Get-WinUserLanguageList
$listMatches = $current.Count -eq $desiredList.Count
if ($listMatches) {
    for ($i = 0; $i -lt $desiredList.Count; $i++) {
        if ($current[$i].LanguageTag -ne $desiredList[$i].Tag) { $listMatches = $false; break }
        $a = @($current[$i].InputMethodTips)
        $b = $desiredList[$i].Tips
        if ($a.Count -ne $b.Count) { $listMatches = $false; break }
        for ($j = 0; $j -lt $b.Count; $j++) {
            if ($a[$j] -ne $b[$j]) { $listMatches = $false; break }
        }
        if (-not $listMatches) { break }
    }
}

$uiMatches = (Get-WinUILanguageOverride).Name -eq $desiredUI

if ($listMatches -and $uiMatches) {
    Write-Host "Keyboard layouts already configured: en-US + ru, UI display $desiredUI."
    return
}

if (-not $listMatches) {
    $list = New-WinUserLanguageList -Language en-US
    $list.Add('ru')
    Set-WinUserLanguageList -LanguageList $list -Force
}

if (-not $uiMatches) {
    Set-WinUILanguageOverride -Language $desiredUI
}

Write-Host "Configured keyboard layouts: en-US + ru, UI display $desiredUI."
