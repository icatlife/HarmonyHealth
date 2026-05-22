$content = Get-Content "D:\HarmonyHealth\entry\src\main\ets\viewmodel\MusicViewModel.ets" -Encoding UTF8
$content | Select-Object -Skip 740
