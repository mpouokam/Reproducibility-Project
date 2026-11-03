$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$DataRoot = Join-Path $ProjectRoot "data\raw"
$MetadataRoot = Join-Path $ProjectRoot "data\metadata"
$ResultsRoot = Join-Path $ProjectRoot "results\HindIII_MspI"
$LinkingRoot = Join-Path $ResultsRoot "linking"
$ClassesRoot = Join-Path $ResultsRoot "java-classes"

if (Test-Path -LiteralPath $ResultsRoot) {
    throw "Output folder already exists: $ResultsRoot. Move or rename it before starting a fresh run."
}

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is required. Install/start Docker Desktop first."
}
if (-not (Get-Command javac -ErrorAction SilentlyContinue) -or -not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "A Java JDK (java and javac) is required for linking-frequency estimation."
}

New-Item -ItemType Directory -Force -Path $ResultsRoot, $LinkingRoot, $ClassesRoot | Out-Null
Copy-Item (Join-Path $ProjectRoot "config.ini") $ResultsRoot -Force
Copy-Item (Join-Path $MetadataRoot "duan.SC.10000.raw_sub.bed") $ResultsRoot -Force

docker run --rm `
    -v "${ResultsRoot}:/app" `
    -v "${DataRoot}:/data:ro" `
    -v "${ProjectRoot}:/repo:ro" `
    pastis bash /repo/pipeline.sh

if ($LASTEXITCODE -ne 0) {
    throw "Docker pipeline failed with exit code $LASTEXITCODE. See logs under $ResultsRoot\logs."
}

javac -encoding UTF-8 -d $ClassesRoot (Join-Path $ProjectRoot "src\java\ComputeWriteC3.java")
if ($LASTEXITCODE -ne 0) {
    throw "Java compilation failed."
}

$MdsDir = Join-Path $ResultsRoot "MDS_split"
$NmdsDir = Join-Path $ResultsRoot "NMDS_split"
$Pm1Dir = Join-Path $ResultsRoot "PM1_split"
$Pm2Dir = Join-Path $ResultsRoot "PM2_split"

java -cp $ClassesRoot computewritec.ComputeWriteC3 $LinkingRoot $MdsDir $NmdsDir $Pm1Dir $Pm2Dir *> (Join-Path $ResultsRoot "logs\java_linking.log")
if ($LASTEXITCODE -ne 0) {
    throw "Java linking-frequency calculation failed. See $ResultsRoot\logs\java_linking.log."
}

Write-Host "Complete. Results are in $ResultsRoot"
