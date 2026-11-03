$ErrorActionPreference = "Stop"

$ProjectRoot = $PSScriptRoot
$DataRoot = Join-Path $ProjectRoot "data\raw"
$MetadataRoot = Join-Path $ProjectRoot "data\metadata"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    throw "Docker is required. Install/start Docker Desktop first."
}
if (-not (Get-Command javac -ErrorAction SilentlyContinue) -or -not (Get-Command java -ErrorAction SilentlyContinue)) {
    throw "A Java JDK (java and javac) is required for linking-frequency estimation."
}

Copy-Item (Join-Path $MetadataRoot "duan.SC.10000.raw_sub.bed") $ProjectRoot -Force
New-Item -ItemType Directory -Force -Path (Join-Path $ProjectRoot "logs") | Out-Null

docker run --rm `
    -v "${ProjectRoot}:/app" `
    -v "${DataRoot}:/data:ro" `
    -v "${ProjectRoot}:/repo:ro" `
    pastis bash /repo/pipeline.sh

if ($LASTEXITCODE -ne 0) {
    throw "Docker pipeline failed with exit code $LASTEXITCODE. See logs under $ProjectRoot\logs."
}

javac -encoding UTF-8 -d $ProjectRoot (Join-Path $ProjectRoot "src\java\ComputeWriteC3.java")
if ($LASTEXITCODE -ne 0) {
    throw "Java compilation failed."
}

java -cp $ProjectRoot computewritec.ComputeWriteC3 `
    $ProjectRoot `
    (Join-Path $ProjectRoot "MDS_split") `
    (Join-Path $ProjectRoot "NMDS_split") `
    (Join-Path $ProjectRoot "PM1_split") `
    (Join-Path $ProjectRoot "PM2_split") *> (Join-Path $ProjectRoot "logs\java_linking.log")
if ($LASTEXITCODE -ne 0) {
    throw "Java linking-frequency calculation failed. See $ProjectRoot\logs\java_linking.log."
}

Write-Host "Complete. Generated files are in $ProjectRoot"
