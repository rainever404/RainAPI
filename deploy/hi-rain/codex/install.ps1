# Rainever New API -> Codex configuration installer for Windows PowerShell.
# Usage:
#   iex (irm https://api.hi-rain.com/codex/install.ps1)
#   $env:RAINEVER_API_KEY = "sk-your-token"; iex (irm https://api.hi-rain.com/codex/install.ps1)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()

$BaseUrl = 'https://api.hi-rain.com/v1'
$DefaultModel = 'gpt-6-sol'
$ProviderName = 'OpenAI'
$ManagedTopKeys = @(
  'model_provider',
  'model',
  'review_model',
  'model_reasoning_effort',
  'disable_response_storage',
  'network_access',
  'windows_wsl_setup_acknowledged'
)

function Write-Step {
  param([string]$Message)
  Write-Host "[rainever-codex] $Message"
}

function Backup-File {
  param([string]$Path)
  if (Test-Path -LiteralPath $Path) {
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    Copy-Item -LiteralPath $Path -Destination "$Path.bak.$stamp" -Force
    Write-Step "Backed up $Path"
  }
}

function Strip-ManagedConfig {
  param([string[]]$Lines)

  $topPart = New-Object System.Collections.Generic.List[string]
  $restPart = New-Object System.Collections.Generic.List[string]
  $beforeSection = $true
  $inManagedSection = $false
  $managedKeyPattern = '^\s*(' + ($ManagedTopKeys -join '|') + ')\s*='

  foreach ($line in $Lines) {
    if ($line -match '^\[model_providers\.OpenAI\]\s*$') {
      $inManagedSection = $true
      $beforeSection = $false
      continue
    }

    if ($line -match '^\[') {
      $inManagedSection = $false
      $beforeSection = $false
      $restPart.Add($line)
      continue
    }

    if ($inManagedSection) {
      continue
    }

    if ($beforeSection) {
      if ($line -match $managedKeyPattern) {
        continue
      }
      $topPart.Add($line)
    } else {
      $restPart.Add($line)
    }
  }

  while ($topPart.Count -gt 0 -and -not $topPart[$topPart.Count - 1].Trim()) {
    $topPart.RemoveAt($topPart.Count - 1)
  }
  while ($restPart.Count -gt 0 -and -not $restPart[$restPart.Count - 1].Trim()) {
    $restPart.RemoveAt($restPart.Count - 1)
  }

  return @{
    Top = $topPart
    Rest = $restPart
  }
}

Write-Host ''
Write-Step 'Rainever New API Codex setup'
Write-Step "Base URL: $BaseUrl"
Write-Step "Default model: $DefaultModel"
Write-Host ''

$codexDir = Join-Path $env:USERPROFILE '.codex'
$configFile = Join-Path $codexDir 'config.toml'
$authFile = Join-Path $codexDir 'auth.json'

if (-not (Test-Path -LiteralPath $codexDir)) {
  New-Item -ItemType Directory -Force -Path $codexDir | Out-Null
  Write-Step "Created $codexDir"
}

$apiKey = $env:RAINEVER_API_KEY
if (-not $apiKey) {
  $apiKey = $env:OPENAI_API_KEY
}
if (-not $apiKey) {
  Write-Host 'Paste your Rainever/New API token, then press Enter:'
  $apiKey = [Console]::ReadLine()
}
if (-not $apiKey) {
  throw 'API token is empty.'
}

Backup-File $configFile
Backup-File $authFile

$existingLines = @()
if (Test-Path -LiteralPath $configFile) {
  $existingLines = Get-Content -LiteralPath $configFile -Encoding UTF8
}

$parts = Strip-ManagedConfig -Lines $existingLines
$managedTopBlock = @(
  "model_provider = `"$ProviderName`"",
  "model = `"$DefaultModel`"",
  "review_model = `"$DefaultModel`"",
  'model_reasoning_effort = "medium"',
  'disable_response_storage = true',
  'network_access = "enabled"',
  'windows_wsl_setup_acknowledged = true'
) -join "`n"

$managedProviderBlock = @(
  "[model_providers.$ProviderName]",
  "name = `"$ProviderName`"",
  "base_url = `"$BaseUrl`"",
  'wire_api = "responses"',
  'requires_openai_auth = true'
) -join "`n"

$chunks = New-Object System.Collections.Generic.List[string]
if ($parts.Top.Count -gt 0) {
  $chunks.Add(($parts.Top -join "`n"))
}
$chunks.Add($managedTopBlock)
if ($parts.Rest.Count -gt 0) {
  $chunks.Add(($parts.Rest -join "`n"))
}
$chunks.Add($managedProviderBlock)

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText($configFile, (($chunks -join "`n`n") + "`n"), $utf8NoBom)
Write-Step "Wrote $configFile"

$authData = @{}
if (Test-Path -LiteralPath $authFile) {
  try {
    $raw = Get-Content -LiteralPath $authFile -Raw -Encoding UTF8
    if ($raw.Trim()) {
      $obj = $raw | ConvertFrom-Json
      $obj.PSObject.Properties | ForEach-Object {
        $authData[$_.Name] = $_.Value
      }
    }
  } catch {
    Write-Step 'Existing auth.json is not valid JSON; replacing managed auth file.'
    $authData = @{}
  }
}
$authData['OPENAI_API_KEY'] = $apiKey
[System.IO.File]::WriteAllText($authFile, (($authData | ConvertTo-Json -Depth 10) + "`n"), $utf8NoBom)
Write-Step "Wrote $authFile"

Write-Host ''
Write-Step 'Done.'
Write-Step 'Fully quit Codex from the Windows tray, then open it again.'
Write-Step 'If it does not take effect, restore the latest .bak file in %USERPROFILE%\.codex.'
