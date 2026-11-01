<#
.SYNOPSIS
  Banc d'essai deterministe CR380 sous WSL 2 (classe A).

.DESCRIPTION
  Recree a l'identique une distribution WSL jetable (cr380-*) depuis un etat de
  reference (tarball), y copie le depot dans le systeme de fichiers Linux,
  lance ./run-labs.sh, rapatrie results/ et logs/, puis supprime la distribution.

  Ne touche JAMAIS a une distribution dont le nom ne correspond pas a
  ^cr380-[a-z0-9-]+$, ni a .wslconfig.

.PARAMETER Prepare
  Construit l'etat de reference (installe Ubuntu-24.04 sous le nom cr380-base,
  execute wsl/provision-wsl.sh, exporte le tarball, supprime cr380-base).

.PARAMETER Name
  Nom de la distribution de test (defaut : cr380-test).

.PARAMETER BaseTar
  Chemin du tarball de reference.

.PARAMETER RunArgs
  Arguments passes a run-labs.sh (defaut : --validate).

.PARAMETER Keep
  Ne supprime pas la distribution a la fin (diagnostic).

.EXAMPLE
  .\wsl\run-wsl-tests.ps1 -Prepare
  .\wsl\run-wsl-tests.ps1
#>
[CmdletBinding()]
param(
    [switch]$Prepare,
    [string]$Name = 'cr380-test',
    [string]$BaseTar = (Join-Path $env:LOCALAPPDATA 'CR380-wsl\cr380-base.tar'),
    [string]$RunArgs = '--validate',
    [string]$LabUser = 'student',
    [string]$OutDir,
    [switch]$Keep
)

$ErrorActionPreference = 'Stop'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$NamePattern = '^cr380-[a-z0-9-]+$'
$Stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
if (-not $OutDir) { $OutDir = Join-Path $RepoRoot "wsl\out\$Name-$Stamp" }

function Assert-LabName([string]$n) {
    if ($n -notmatch $NamePattern) {
        throw "Nom de distribution refuse: '$n' ne correspond pas a $NamePattern"
    }
}

function Get-WslDistros {
    $prev = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        $list = & wsl.exe -l -q 2>$null
    } finally { [Console]::OutputEncoding = $prev }
    @($list | ForEach-Object { ($_ -replace "`0", '').Trim() } | Where-Object { $_ })
}

function Get-WslText([string[]]$wslArgs) {
    $prev = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::Unicode
        (& wsl.exe @wslArgs 2>&1 | Out-String) -replace "`0", ''
    } finally { [Console]::OutputEncoding = $prev }
}

# Execute une commande bash dans la distribution (sortie UTF-8 de Linux).
function Invoke-Guest([string]$distro, [string]$user, [string]$cmd) {
    Assert-LabName $distro
    $prev = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        & wsl.exe -d $distro -u $user -- bash -lc $cmd | Out-Host
        return $LASTEXITCODE
    } finally { [Console]::OutputEncoding = $prev }
}

function ConvertTo-WslPath([string]$distro, [string]$winPath) {
    # Montage par defaut /mnt/<lettre> (non modifie dans /etc/wsl.conf de la reference)
    $full = [System.IO.Path]::GetFullPath($winPath)
    if ($full -notmatch '^([A-Za-z]):\\(.*)$') { throw "Chemin Windows non pris en charge: $winPath" }
    '/mnt/' + $Matches[1].ToLower() + '/' + ($Matches[2] -replace '\\', '/')
}

function Remove-LabDistro([string]$n) {
    Assert-LabName $n
    if ((Get-WslDistros) -contains $n) {
        Write-Host "Suppression de la distribution jetable '$n'"
        & wsl.exe --terminate $n | Out-Null
        & wsl.exe --unregister $n | Out-Null
    }
}

function Wait-Systemd([string]$distro) {
    for ($i = 0; $i -lt 60; $i++) {
        $state = (Invoke-GuestCapture $distro 'root' 'systemctl is-system-running 2>/dev/null').Trim()
        if ($state -eq 'running') { return $state }
        if ($state -eq 'degraded') {
            Write-Warning 'systemd est degraded; unites en echec :'
            Invoke-Guest $distro 'root' 'systemctl --failed --no-legend' | Out-Null
            return $state
        }
        Start-Sleep -Seconds 2
    }
    throw "systemd n'est pas devenu actif dans '$distro' (dernier etat: '$state')"
}

function Invoke-GuestCapture([string]$distro, [string]$user, [string]$cmd) {
    Assert-LabName $distro
    $ErrorActionPreference = 'Continue'
    $prev = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        (& wsl.exe -d $distro -u $user -- bash -lc $cmd 2>&1 | Out-String)
    } finally { [Console]::OutputEncoding = $prev }
}

Assert-LabName $Name
$BaseName = 'cr380-base'

# --- Mode -Prepare : etat de reference -------------------------------------
if ($Prepare) {
    if (Test-Path $BaseTar) { throw "Le tarball de reference existe deja: $BaseTar (supprimez-le pour le recreer)" }
    if ((Get-WslDistros) -contains $BaseName) { throw "La distribution '$BaseName' existe deja : refus de l'ecraser." }
    New-Item -ItemType Directory -Force -Path (Split-Path $BaseTar) | Out-Null
    try {
        Write-Host "Installation d'Ubuntu-24.04 sous le nom '$BaseName'"
        & wsl.exe --install Ubuntu-24.04 --name $BaseName --no-launch
        if ($LASTEXITCODE -ne 0) { throw "wsl --install a echoue (code $LASTEXITCODE)" }
        $prov = ConvertTo-WslPath $BaseName ((Join-Path $RepoRoot 'wsl\provision-wsl.sh'))
        $rc = Invoke-Guest $BaseName 'root' "set -o pipefail; test -f '$prov' && tr -d '\r' < '$prov' | bash -s $LabUser"
        if ($rc -ne 0) { throw "provision-wsl.sh a echoue (code $rc)" }
        $chk = Invoke-GuestCapture $BaseName 'root' "grep -q '^systemd=true' /etc/wsl.conf && id $LabUser >/dev/null && echo OK"
        if ($chk.Trim() -ne 'OK') { throw 'Verification du provisionnement echouee (wsl.conf ou utilisateur absent)' }
        & wsl.exe --terminate $BaseName | Out-Null
        & wsl.exe --export $BaseName $BaseTar
        if ($LASTEXITCODE -ne 0) { throw "wsl --export a echoue (code $LASTEXITCODE)" }
        Write-Host "Etat de reference cree: $BaseTar"
    } finally {
        Remove-LabDistro $BaseName
    }
    exit 0
}

# --- Mode normal : campagne sur distribution neuve -----------------------------
if (-not (Test-Path $BaseTar)) { throw "Etat de reference absent ($BaseTar). Lancez d'abord: .\wsl\run-wsl-tests.ps1 -Prepare" }
if ((Get-WslDistros) -contains $Name) { throw "La distribution '$Name' existe deja : refus de l'ecraser." }

New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$exitCode = 1
$created = $false
try {
    # Environnement de la campagne
    $os = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion'
    $build = [int]$os.CurrentBuild
    $winName = if ($build -ge 22000) { 'Windows 11' } else { 'Windows 10' }
    $env_ = @(
        "Windows : $winName ($($os.ProductName) $($os.DisplayVersion) build $($os.CurrentBuild).$($os.UBR))",
        'wsl --version :', (Get-WslText @('--version'))
    )

    $installDir = Join-Path $env:LOCALAPPDATA "CR380-wsl\$Name"
    Write-Host "Import de '$Name' depuis $BaseTar"
    & wsl.exe --import $Name $installDir $BaseTar --version 2
    if ($LASTEXITCODE -ne 0) { throw "wsl --import a echoue (code $LASTEXITCODE)" }
    $created = $true

    $null = Wait-Systemd $Name

    # Garde-fou : on ne travaille que dans la distribution cr380-*
    $who = (Invoke-GuestCapture $Name $LabUser 'echo $WSL_DISTRO_NAME').Trim()
    if ($who -ne $Name) { throw "WSL_DISTRO_NAME='$who' differe de '$Name' : arret." }

    # Copie du depot dans le systeme de fichiers Linux (jamais d'execution sous /mnt/c)
    $src = ConvertTo-WslPath $Name $RepoRoot
    $copy = "rm -rf ~/CR380-incus-lab && mkdir -p ~/CR380-incus-lab && tar -C '$src' --exclude=.git --exclude=wsl/out -cf - . | tar -C ~/CR380-incus-lab -xf -"
    if ((Invoke-Guest $Name $LabUser $copy) -ne 0) { throw 'La copie du depot a echoue' }

    # Fins de ligne : on signale et on convertit (un CR dans un .sh est un bug de classe B)
    $crlf = 'cd ~/CR380-incus-lab && grep -rIlP --include=*.sh --include=*.env --include=*.yaml ''\r$'' . | tee ~/.crlf-converted.txt | xargs -r sed -i ''s/\r$//''; echo Fichiers CRLF convertis: $(wc -l < ~/.crlf-converted.txt); cat ~/.crlf-converted.txt'
    $null = Invoke-Guest $Name $LabUser $crlf

    $env_ += (Invoke-GuestCapture $Name $LabUser 'echo noyau $(uname -r); echo distribution $(lsb_release -ds)')
    $env_ | Set-Content -Path (Join-Path $OutDir 'environnement.txt') -Encoding UTF8

    # Execution du lab
    $log = Join-Path $OutDir 'run.log'
    Write-Host "Execution: sudo ./run-labs.sh $RunArgs"
    $prev = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
        & wsl.exe -d $Name -u $LabUser -- bash -lc "cd ~/CR380-incus-lab && sudo ./run-labs.sh $RunArgs" 2>&1 |
            Tee-Object -FilePath $log
        $runCode = $LASTEXITCODE
    } finally { [Console]::OutputEncoding = $prev }

    Invoke-GuestCapture $Name $LabUser 'echo incus $(incus --version); dpkg -l incus | tail -n 1' |
        Add-Content -Path (Join-Path $OutDir 'environnement.txt') -Encoding UTF8

    # Rapatriement de results/ et logs/ (ecriture cote Windows via /mnt/c)
    $dst = ConvertTo-WslPath $Name $OutDir
    $null = Invoke-Guest $Name $LabUser "cp -r ~/CR380-incus-lab/results '$dst/' ; cp -r ~/CR380-incus-lab/logs '$dst/'"

    # Verdict : code de sortie, 0 echec, 0 ignore
    $report = Get-ChildItem (Join-Path $OutDir 'results') -Filter 'report-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime | Select-Object -Last 1
    $verdict = 'echec'
    if ($report) {
        $sum = (Get-Content $report.FullName -Raw | ConvertFrom-Json).summary
        Write-Host ("Resume: {0} reussis, {1} echecs, {2} ignores" -f $sum.pass, $sum.fail, $sum.skip)
        if ($runCode -eq 0 -and $sum.fail -eq 0 -and $sum.skip -eq 0) { $verdict = 'ok' }
    } else {
        Write-Warning 'Aucun rapport JSON retrouve.'
    }
    Write-Host "Sortie: $OutDir"
    $exitCode = if ($verdict -eq 'ok') { 0 } else { 1 }
} finally {
    if ($created -and -not $Keep) { Remove-LabDistro $Name }
    elseif ($created) { Write-Host "Distribution '$Name' conservee (-Keep)." }
}
exit $exitCode
