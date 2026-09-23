param(
    [string]$RepoRoot = (Join-Path $PSScriptRoot '..\..\..\..'),
    [switch]$Fetch
)

chcp 65001 > $null
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true
$RepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path
Push-Location -LiteralPath $RepoRoot
try {
    $upstreamUrl = [string](git remote get-url upstream)
    if ($upstreamUrl.TrimEnd('/') -ne 'https://github.com/QuantumNous/new-api.git') {
        throw 'The upstream remote does not match the official New API repository.'
    }
    if ($Fetch) {
        git fetch upstream --tags --prune
        git fetch origin --prune
    }
    $statePath = Join-Path $RepoRoot 'deploy/hi-rain/upstream-sync.json'
    $state = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
    $recorded = [string]$state.last_merged_commit
    $target = [string](git rev-parse upstream/main)
    $previousNativePreference = $PSNativeCommandUseErrorActionPreference
    $PSNativeCommandUseErrorActionPreference = $false
    git merge-base --is-ancestor $recorded HEAD
    $ancestorExit = $LASTEXITCODE
    $PSNativeCommandUseErrorActionPreference = $previousNativePreference
    if ($ancestorExit -gt 1) { throw 'Unable to check recorded merge ancestry.' }
    [ordered]@{
        branch = [string](git branch --show-current)
        head = [string](git rev-parse HEAD)
        working_tree = @(git status --short)
        upstream_url = $upstreamUrl
        recorded_upstream_commit = $recorded
        recorded_commit_is_ancestor = ($ancestorExit -eq 0)
        target_upstream_commit = $target
        upstream_commits_not_in_head = [int](git rev-list --count "HEAD..$target")
        current_stage = $state.stage
        pending_commits = @(git log --max-count=20 --format='%h %ad %s' --date=short "HEAD..$target")
    } | ConvertTo-Json -Depth 5
}
finally {
    Pop-Location
}
