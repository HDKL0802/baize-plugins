# Build the Baize plugin source repo:
#   <channel>/<stage>/<category>/<id>/  ->  packages/<id>-<version>.zip + index.json
#   channel = official | community      stage = stable | beta
#
# NOTE: keep this file ASCII-only. PowerShell 5.1 reads .ps1 as ANSI, and non-ASCII bytes can be
#       mis-parsed (they can even swallow the following line). All human-readable Chinese lives in
#       README.md / source.json / the plugin files, which are read as UTF-8 explicitly below.
#
# Usage:  powershell -ExecutionPolicy Bypass -File tools\build.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root        = Split-Path -Parent $PSScriptRoot
$packagesDir = Join-Path $root 'packages'
$indexPath   = Join-Path $root 'index.json'
$sourceCfg   = Join-Path $root 'source.json'
$idPattern   = '^[a-z0-9][a-z0-9._-]*$'

$channels = @('official', 'community')   # board order in the index
$stages   = @('stable', 'beta')          # release-stage order in the index

function Read-Utf8([string]$path) {
  return [System.IO.File]::ReadAllText($path, (New-Object System.Text.UTF8Encoding($false)))
}
function Write-Utf8([string]$path, [string]$text) {
  [System.IO.File]::WriteAllText($path, $text, (New-Object System.Text.UTF8Encoding($false)))
}

$sourceName = 'plugin source'
if (Test-Path $sourceCfg) {
  $sc = Read-Utf8 $sourceCfg | ConvertFrom-Json
  if ($sc.name) { $sourceName = [string]$sc.name }
}

# every plugin.json outside .git / packages / tools
$manifests = @(Get-ChildItem -LiteralPath $root -Recurse -File -Filter 'plugin.json' -ErrorAction SilentlyContinue |
  Where-Object { $_.FullName -notmatch '\\\.git\\' -and $_.FullName -notmatch '\\packages\\' -and $_.FullName -notmatch '\\tools\\' })
if ($manifests.Count -eq 0) {
  throw "no plugins found (expected <channel>/<stage>/<category>/<id>/plugin.json)"
}

if (Test-Path $packagesDir) { Remove-Item -LiteralPath $packagesDir -Recurse -Force }
New-Item -ItemType Directory -Path $packagesDir | Out-Null

$entries = New-Object System.Collections.ArrayList
$seenIDs = New-Object 'System.Collections.Generic.HashSet[string]'

foreach ($mf in ($manifests | Sort-Object FullName)) {
  $rel = $mf.FullName.Substring($root.Length + 1)
  $parts = $rel.Split('\')
  if ($parts.Count -ne 5) {
    throw "$rel : plugin.json must sit at <channel>/<stage>/<category>/<id>/plugin.json"
  }
  $channel, $stage, $category, $id = $parts[0], $parts[1], $parts[2], $parts[3]
  if ($channels -notcontains $channel) { throw "$rel : unknown channel '$channel' (use official / community)" }
  if ($stages -notcontains $stage)     { throw "$rel : unknown stage '$stage' (use stable / beta)" }
  if ([string]::IsNullOrWhiteSpace($category)) { throw "$rel : empty category directory name" }
  if ($id -notmatch $idPattern) {
    throw "$rel : plugin id (directory name) not allowed (lowercase letters / digits / - / . / _ , starting with a letter or digit)"
  }
  if (-not $seenIDs.Add($id)) { throw "$rel : duplicate plugin id '$id' (ids must be unique across the whole repo)" }

  $m = Read-Utf8 $mf.FullName | ConvertFrom-Json
  if (-not $m.id)      { throw "$rel : plugin.json has no id" }
  if ($m.id -ne $id)   { throw "$rel : plugin.json id is '$($m.id)' but the directory is '$id' (they must match)" }
  if (-not $m.name)    { throw "$rel : plugin.json has no name" }
  if (-not $m.version) { throw "$rel : plugin.json has no version" }

  $pluginDir = $mf.Directory.FullName
  $skillRoot = Join-Path $pluginDir 'skills'
  if (-not (Test-Path $skillRoot)) { throw "$rel : no skills/ directory (a plugin must bring at least one skill)" }
  $skillCount = 0
  foreach ($sk in (Get-ChildItem -LiteralPath $skillRoot -Directory)) {
    $skillCount++
    $skillMd = Join-Path $sk.FullName 'SKILL.md'
    if (-not (Test-Path $skillMd)) { throw "$rel / $($sk.Name) : missing SKILL.md" }
    $text = Read-Utf8 $skillMd
    if (-not $text.TrimStart().StartsWith('---')) {
      throw "$rel / $($sk.Name) : SKILL.md must start with a YAML front-matter (---)"
    }
    $fm = $text.Substring(0, [Math]::Min(800, $text.Length))
    if ($fm -notmatch '(?m)^\s*name:')        { throw "$rel / $($sk.Name) : SKILL.md front-matter has no name" }
    if ($fm -notmatch '(?m)^\s*description:') { throw "$rel / $($sk.Name) : SKILL.md front-matter has no description" }
  }
  if ($skillCount -eq 0) { throw "$rel : skills/ is empty" }

  $zipName = "$id-$($m.version).zip"
  $zipPath = Join-Path $packagesDir $zipName
  Compress-Archive -Path (Join-Path $pluginDir '*') -DestinationPath $zipPath -Force

  # sanity: plugin.json must sit at the zip root (Baize rejects a package without it)
  $z = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
  $hasManifest = $false
  foreach ($e in $z.Entries) { if ($e.FullName -eq 'plugin.json') { $hasManifest = $true } }
  $z.Dispose()
  if (-not $hasManifest) { throw "$rel : the zip root has no plugin.json" }

  $sha  = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToLower()
  $size = (Get-Item -LiteralPath $zipPath).Length

  $entry = [ordered]@{
    id       = $id
    name     = [string]$m.name
    version  = [string]$m.version
    channel  = $channel
    stage    = $stage
    category = $category
  }
  foreach ($k in @('description', 'author', 'homepage', 'license', 'minBaize')) {
    if ($m.$k) { $entry[$k] = [string]$m.$k }
  }
  if ($m.tags -and @($m.tags).Count -gt 0) { $entry['tags'] = @($m.tags) }
  $entry['url']    = "packages/$zipName"
  $entry['sha256'] = $sha
  $entry['size']   = $size
  [void]$entries.Add($entry)

  "  [$channel/$stage/$category] $id  v$($m.version)  ->  packages/$zipName  ($size bytes)"
}

# deterministic order: channel -> stage -> category -> id
$sorted = @($entries | Sort-Object `
  @{ Expression = { $channels.IndexOf([string]$_['channel']) } }, `
  @{ Expression = { $stages.IndexOf([string]$_['stage']) } }, `
  @{ Expression = { [string]$_['category'] } }, `
  @{ Expression = { [string]$_['id'] } })

$index = [ordered]@{
  schema  = 1
  name    = $sourceName
  updated = (Get-Date -Format 'yyyy-MM-dd')
  plugins = $sorted
}
Write-Utf8 $indexPath ($index | ConvertTo-Json -Depth 6)

""
"OK: $($entries.Count) plugin(s) -> $indexPath"
"next: commit index.json + packages/ (both from THIS same run), then push."
