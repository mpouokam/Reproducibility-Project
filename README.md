# HindIII + MspI chromosome-linking example

This example starts with the HindIII + MspI inter- and intra-chromosome interaction files. It maps the interactions to 10 kb bins, uses Pastis to reconstruct chromosome structures with four methods, then uses Java to estimate linking frequencies for every chromosome pair.

## Workflow and code

1. `src/locus.py` maps the raw inter/intra CSV files to the 10 kb bins and writes the contact matrix.
2. `config.ini` supplies the matrix and BED interval file to Pastis. Docker runs `pastis-pm2`, `pastis-pm1`, `pastis-mds`, and `pastis-nmds`.
3. `src/coordinates_blank.py` formats the four structure coordinate files by chromosome. `src/split_chromosomes.py` writes each chromosome to a numbered file.
4. `src/java/ComputeWriteC3.java` reads those numbered files and estimates pairwise linking frequencies using Monte Carlo random closures.
5. `analysis/EB.py` and `analysis/chi-square.py` are optional follow-up analyses of the four linking-frequency files.

The Panel thresholding example is separate from the HindIII + MspI workflow. `analysis/semi-threshold.py` and `analysis/semi2.py` use the example vectors in `data/thresholding/`; those vectors are not generated from the HindIII + MspI input files.

## Install and build Docker

Install and start Docker Desktop for Windows. Open PowerShell in the repository root, then build the image from the included `Dockerfile`:

```powershell
docker build -t pastis .
```

The image contains Pastis and the Python libraries used by the pipeline. The project files are mounted into the container when each command runs.

## Step 1: Prepare the run directory and contact matrix

Run these commands from the repository root. Use a fresh results directory for each run.

```powershell
$ProjectRoot = $PWD.Path
$RunDir = Join-Path $ProjectRoot "results\HindIII_MspI"
New-Item -ItemType Directory -Force -Path $RunDir | Out-Null
Copy-Item .\config.ini $RunDir
Copy-Item .\data\metadata\duan.SC.10000.raw_sub.bed $RunDir

docker run --rm `
  -v "${RunDir}:/app" `
  -v "${ProjectRoot}\data\raw:/data:ro" `
  -v "${ProjectRoot}\src:/src:ro" `
  pastis python3 -u /src/locus.py `
    --inter-file "/data/HindIII_MspI_inter.csv" `
    --intra-file "/data/HindIII_MspI_intra.csv" `
    --bed "/app/duan.SC.10000.raw_sub.bed" `
    --out "/app/duan.SC.10000.raw_sub.matrix"
```

This creates `duan.SC.10000.raw_sub.matrix` in the run directory. Pastis reads it along with `config.ini` and the BED file.

## Step 2: Run the four Pastis reconstructions

Still in PowerShell, run each Pastis method from the run directory so `.` refers to the directory containing the configuration and matrix:

```powershell
Push-Location $RunDir

docker run -it --rm -v "${PWD}:/app" pastis pastis-pm2 .
docker run -it --rm -v "${PWD}:/app" pastis pastis-pm1 .
docker run -it --rm -v "${PWD}:/app" pastis pastis-mds .
docker run -it --rm -v "${PWD}:/app" pastis pastis-nmds .

Pop-Location
```

These commands create the four structure outputs in the mounted run directory. The same commands can be run individually when you want to rerun only one method.

## Step 3: Format and split the chromosome coordinates

The coordinate formatter and splitter run in the same Docker image and write their results into the mounted run directory:

```powershell
docker run --rm `
  -v "${RunDir}:/app" `
  -v "${ProjectRoot}\src:/src:ro" `
  pastis python3 -u /src/coordinates_blank.py

docker run --rm `
  -v "${RunDir}:/app" `
  -v "${ProjectRoot}\src:/src:ro" `
  pastis python3 -u /src/split_chromosomes.py
```

The result directories are `MDS_split`, `NMDS_split`, `PM1_split`, and `PM2_split`. Each contains numbered chromosome coordinate files such as `1.txt` and `2.txt`.

## Step 4: Compile and run Java to calculate linking frequency

Install a Java JDK so both `javac` and `java` are available in PowerShell. Then compile and run the Java program from the repository root:

```powershell
$ClassesDir = Join-Path $RunDir "java-classes"
$LinkingDir = Join-Path $RunDir "linking"
New-Item -ItemType Directory -Force -Path $ClassesDir, $LinkingDir | Out-Null

javac -encoding UTF-8 -d $ClassesDir .\src\java\ComputeWriteC3.java
java -cp $ClassesDir computewritec.ComputeWriteC3 `
  $LinkingDir `
  (Join-Path $RunDir "MDS_split") `
  (Join-Path $RunDir "NMDS_split") `
  (Join-Path $RunDir "PM1_split") `
  (Join-Path $RunDir "PM2_split")
```

The linking-frequency results are written under `results/HindIII_MspI/linking/`:

```text
MDS_split_linking_frequency.txt
NMDS_split_linking_frequency.txt
PM1_split_linking_frequency.txt
PM2_split_linking_frequency.txt
```

Each file contains one percentage for each of the 120 chromosome pairs. The Java program uses 1,000 random samples per pair, so repeated runs can differ slightly.

## One-command alternative

`run_example.ps1` automates the matrix preparation, all four Pastis commands, coordinate formatting, Java compilation, and linking-frequency calculation. After building the image with `docker build -t pastis .`, run:

```powershell
.\run_example.ps1
```

It writes the full run to `results/HindIII_MspI/`. It stops if that output directory already exists to avoid mixing results from different runs.

## Optional analyses

After the linking-frequency files have been created, run these from the repository root with Python dependencies installed:

```powershell
python -m pip install -r requirements.txt
python .\analysis\EB.py
python .\analysis\chi-square.py
```

For the separate Panel 1 / Panel 2 thresholding example:

```powershell
python .\analysis\semi-threshold.py
python .\analysis\semi2.py
```

Both scripts read percentage values from `data/thresholding/panel_1_max.txt` and `panel_2_max.txt`, then convert them to proportions. `semi-threshold.py` saves its F-hat plots under `results/thresholding/`.

An earlier run of `semi-threshold.py` reported the values below. That run searched `c` over -10 to 10, including invalid negative and near-zero values. The current script restricts `c` to the positive range 0.01 to 10, so rerun it before reporting results for this repository version.

| Scale | Rule | c-hat | Minimum F-hat | Near-zero after shrinkage | Baseline near-zero |
|---|---:|---:|---:|---:|---:|
| Untransformed | G1 | -0.001 | -5.6763 | 3.33% | 2.50% |
| Untransformed | G2 | 0.001 | -5.6763 | 3.33% | 2.50% |
| Transformed | G1 | -0.001 | -7.5970 | 1.67% | Not reported |
| Transformed | G2 | 0.001 | -7.5970 | 1.67% | Not reported |

## Project files

```text
data/raw/              HindIII + MspI inter/intra input CSV files
data/metadata/         10 kb BED intervals used for mapping
data/thresholding/     Panel 1 and Panel 2 vectors for the separate thresholding example
src/locus.py           Interaction-to-bin mapping and contact matrix creation
src/coordinates_blank.py
src/split_chromosomes.py
src/java/ComputeWriteC3.java
analysis/               EB, chi-square, and semi-soft threshold analyses
results/                Generated outputs (not tracked by Git)
```
