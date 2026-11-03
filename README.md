# HindIII + MspI chromosome-linking example

This example starts with the HindIII + MspI inter- and intra-chromosome interaction files. It maps interactions to 10 kb bins, reconstructs chromosome structures with Pastis, and estimates linking frequencies with Java Monte Carlo sampling.

## Workflow and code

1. `src/locus.py` maps the inter/intra CSV files to the BED intervals and creates the contact matrix.
2. Docker runs Pastis with PM2, PM1, MDS, and NMDS using `config.ini`.
3. `src/coordinates_blank.py` formats the structure coordinates by chromosome. `src/split_chromosomes.py` writes each chromosome to a numbered file.
4. `src/java/ComputeWriteC3.java` estimates linking frequency for each chromosome pair.
5. `analysis/EB.py` and `analysis/chi-square.py` are optional follow-up analyses.

The Panel thresholding example is a separate analysis. The single retained script, `analysis/semi2.py`, reads `data/thresholding/panel_1_max.txt` and `panel_2_max.txt`. Those Panel inputs are not generated from the HindIII + MspI interaction files.

## Install Docker and build the image

Install and start Docker Desktop for Windows. Open PowerShell in the repository root and build the image:

```powershell
docker build -t pastis .
```

The image contains Pastis and its Python dependencies. The commands below mount the repository root into the container at `/app`.

## Step 1: Create the contact matrix

Run from the repository root. Copy the BED file next to `config.ini`, then map the raw interaction files to the 10 kb bins:

```powershell
Copy-Item .\data\metadata\duan.SC.10000.raw_sub.bed .

docker run --rm `
  -v "${PWD}:/app" `
  -v "${PWD}\data\raw:/data:ro" `
  -v "${PWD}\src:/src:ro" `
  pastis python3 -u /src/locus.py `
    --inter-file "/data/HindIII_MspI_inter.csv" `
    --intra-file "/data/HindIII_MspI_intra.csv" `
    --bed "/app/duan.SC.10000.raw_sub.bed" `
    --out "/app/duan.SC.10000.raw_sub.matrix"
```

This creates `duan.SC.10000.raw_sub.matrix` in the repository root. Pastis reads it with the root `config.ini` and BED file.

## Step 2: Run the four Pastis methods

Still in the repository root, run each method separately. Each command writes its structure output into the mounted current directory:

```powershell
docker run -it --rm -v "${PWD}:/app" pastis pastis-pm2 .
docker run -it --rm -v "${PWD}:/app" pastis pastis-pm1 .
docker run -it --rm -v "${PWD}:/app" pastis pastis-mds .
docker run -it --rm -v "${PWD}:/app" pastis pastis-nmds .
```

## Step 3: Format and split chromosome coordinates

Run the formatter and splitter in Docker. They read and write files in the mounted repository root:

```powershell
docker run --rm `
  -v "${PWD}:/app" `
  -v "${PWD}\src:/src:ro" `
  pastis python3 -u /src/coordinates_blank.py

docker run --rm `
  -v "${PWD}:/app" `
  -v "${PWD}\src:/src:ro" `
  pastis python3 -u /src/split_chromosomes.py
```

This creates `MDS_split`, `NMDS_split`, `PM1_split`, and `PM2_split` in the repository root. Each contains numbered chromosome files such as `1.txt`, `2.txt`, and so on.

## Step 4: Compile and run Java

Install a Java JDK so `javac` and `java` are available in PowerShell. From the repository root, compile the Java source into the current directory and run it with the four split folders:

```powershell
javac -encoding UTF-8 -d . .\src\java\ComputeWriteC3.java
java -cp . computewritec.ComputeWriteC3 `
  . `
  .\MDS_split `
  .\NMDS_split `
  .\PM1_split `
  .\PM2_split
```

The linking-frequency files are written directly to the repository root:

```text
MDS_split_linking_frequency.txt
NMDS_split_linking_frequency.txt
PM1_split_linking_frequency.txt
PM2_split_linking_frequency.txt
```

Each file contains one percentage for each of the 120 chromosome pairs. Java uses 1,000 random samples per pair, so values can vary slightly between runs.

## One-command alternative

`run_example.ps1` performs matrix creation, all four Pastis runs, coordinate formatting, Java compilation, and linking-frequency calculation. Build the image first, then run:

```powershell
.\run_example.ps1
```

Generated matrices, structures, split folders, logs, compiled Java classes, and linking-frequency files are written directly into the repository root. A later run replaces files with the same names.

## Optional analyses

After generating the four linking-frequency files, run these from the repository root:

```powershell
python -m pip install -r requirements.txt
python .\analysis\EB.py
python .\analysis\chi-square.py
```

For the separate Panel thresholding example, run the single retained script:

```powershell
python .\analysis\semi2.py
```

`semi2.py` reads percentage values from `data/thresholding/panel_1_max.txt` and `panel_2_max.txt`, converts them to proportions, and prints the thresholding estimates and diagnostics. It handles boundary values and searches `c` over a positive range.

## Project files

```text
data/raw/              HindIII + MspI inter/intra interaction CSV files
data/metadata/         10 kb BED intervals used for mapping
data/thresholding/     Panel 1 and Panel 2 vectors for semi2.py
src/locus.py           Interaction-to-bin mapping and contact matrix creation
src/coordinates_blank.py
src/split_chromosomes.py
src/java/ComputeWriteC3.java
analysis/               EB, chi-square, and semi2 analyses
```
