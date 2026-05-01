# Configure keyboard layouts: English (US ANSI) + Russian.
#
# Display language stays English (United Kingdom): we keep en-GB at the top
# of the user language list (so the en-GB UI pack stays installed and
# Set-WinUILanguageOverride keeps working) but swap its keyboard from UK
# (0809:00000809) to US (0409:00000409). On an ISO keyboard, 0409 gives
# US-ANSI key semantics (@ on Shift+2, " on Shift+', etc).
# Russian (0419:00000419) is the second list entry.

$desired = @(
    @{ Tag = 'en-GB'; Tips = @('0409:00000409') },
    @{ Tag = 'ru';    Tips = @('0419:00000419') }
)

$current = Get-WinUserLanguageList
$matches = $current.Count -eq $desired.Count
if ($matches) {
    for ($i = 0; $i -lt $desired.Count; $i++) {
        if ($current[$i].LanguageTag -ne $desired[$i].Tag) { $matches = $false; break }
        $a = @($current[$i].InputMethodTips)
        $b = $desired[$i].Tips
        if ($a.Count -ne $b.Count) { $matches = $false; break }
        for ($j = 0; $j -lt $b.Count; $j++) {
            if ($a[$j] -ne $b[$j]) { $matches = $false; break }
        }
        if (-not $matches) { break }
    }
}

if ($matches) {
    Write-Host "Keyboard layouts already configured: en-GB (US keyboard) + ru."
    return
}

$list = New-WinUserLanguageList -Language en-GB
$list[0].InputMethodTips.Clear()
$list[0].InputMethodTips.Add('0409:00000409')
$list.Add('ru')

Set-WinUserLanguageList -LanguageList $list -Force
Write-Host "Configured keyboard layouts: en-GB (US keyboard) + ru."
