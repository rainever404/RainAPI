param(
    [string]$ImageTag = 'rainapi:v1.0.0-rc.36-rain.1'
)

$ErrorActionPreference = 'Stop'
$repoRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path

$proxyPort = $null
foreach ($candidatePort in @(7897, 7890, 7891, 7892, 7893, 7894, 7895, 7896, 7898, 7899)) {
    $client = [System.Net.Sockets.TcpClient]::new()
    try {
        $connectTask = $client.ConnectAsync('127.0.0.1', $candidatePort)
        if ($connectTask.Wait(250) -and $client.Connected) {
            $proxyPort = $candidatePort
            break
        }
    }
    catch {
        # Continue to the next known local proxy port.
    }
    finally {
        $client.Dispose()
    }
}

$buildArguments = @('build', '--pull', '--tag', $ImageTag)
if ($null -ne $proxyPort) {
    $proxyUrl = "http://host.docker.internal:$proxyPort"
    $buildArguments += @(
        '--build-arg', "HTTP_PROXY=$proxyUrl",
        '--build-arg', "HTTPS_PROXY=$proxyUrl",
        '--build-arg', "ALL_PROXY=$proxyUrl",
        '--build-arg', "http_proxy=$proxyUrl",
        '--build-arg', "https_proxy=$proxyUrl",
        '--build-arg', "all_proxy=$proxyUrl"
    )
}
$buildArguments += $repoRoot

& docker @buildArguments
if ($LASTEXITCODE -ne 0) {
    throw "docker build failed with exit code $LASTEXITCODE"
}

$imageId = docker image inspect $ImageTag --format '{{.Id}}'
if ($LASTEXITCODE -ne 0 -or -not $imageId) {
    throw "Unable to inspect built image $ImageTag"
}

Write-Output "image=$ImageTag"
Write-Output "image_id=$imageId"
Write-Output "proxy_port=$($proxyPort ?? 'none')"
