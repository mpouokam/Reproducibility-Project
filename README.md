# HindIII + MspI chromosome-linking example

This repository contains a single example workflow built around the supplied HindIII + MspI inter- and intra-chromosome interaction files. It maps interactions to 10 kb bins, reconstructs chromosome structures with Pastis, and estimates pairwise linking frequencies with Monte Carlo sampling.

## Workflow and code

1. `src/locus.py` reads the example inter/intra CSV files, maps genomic positions using the BED intervals, and writes the contact matrix.
2. `config.ini` configures Pastis. `pipeline.sh` runs PM2, PM1, MDS, and NMDS in Docker.
3. `src/coordinates_blank.py` formats the four coordinate outputs by chromosome. `src/split_chromosomes.py` writes each chromosome to a numbered file.
4. `src/java/ComputeWriteC3.java` samples random closures for each chromosome pair and writes the estimated linking frequencies as percentages.
5. `analysis/EB.py` and `analysis/chi-square.py` provide optional follow-up analyses of the four linking-frequency files.

The Panel thresholding example is a separate analysis: `analysis/semi-threshold.py` and `analysis/semi2.py` use the two small files under `data/thresholding/`. Those Panel inputs are not generated from the HindIII + MspI interaction data.

## Files

```text
data/
  raw/             HindIII + MspI inter/intra input CSV files
  metadata/        10 kb BED intervals used for the mapping
  thresholding/    Panel 1 and Panel 2 example vectors for semi-soft thresholding
src/               Matrix preparation, coordinate formatting, and Java linking code
analysis/           EB, chi-square, and semi-soft threshold analyses
results/            Generated files (not tracked by Git)
```

## Run the HindIII + MspI workflow

Requirements: Docker Desktop and a Java JDK (`java` and `javac`) on Windows.

From PowerShell in the repository directory:

```powershell
docker build -t reproducibility-project .
.\run_example.ps1
```

The run script uses paths relative to the repository, mounts the raw data read-only, and writes outputs to `results/HindIII_MspI/`. Linking-frequency files are written under `results/HindIII_MspI/linking/`; each file contains one percentage for each chromosome pair. Logs are under `results/HindIII_MspI/logs/`.

## Run the optional analyses

After the main workflow has generated the four linking files, run from the repository root:

```powershell
python .\analysis\EB.py
python .\analysis\chi-square.py
```

For the independent Panel thresholding example, run:

```powershell
python -m pip install -r requirements.txt
python .\analysis\semi-threshold.py
python .\analysis\semi2.py
```

The semi-soft scripts expect percentage values in `data/thresholding/panel_1_max.txt` and `panel_2_max.txt`; they convert them to proportions internally. `semi-threshold.py` saves its F-hat plots under `results/thresholding/`.

## Previous Panel thresholding output

The following values were supplied from an earlier `semi-threshold.py` run:

| Scale | Rule | c-hat | Minimum F-hat | Near-zero after shrinkage | Baseline near-zero |
|---|---:|---:|---:|---:|---:|
| Untransformed | G1 | -0.001 | -5.6763 | 3.33% | 2.50% |
| Untransformed | G2 | 0.001 | -5.6763 | 3.33% | 2.50% |
| Transformed | G1 | -0.001 | -7.5970 | 1.67% | Not reported |
| Transformed | G2 | 0.001 | -7.5970 | 1.67% | Not reported |

That earlier run searched `c` from -10 to 10, including negative and near-zero values. Since `c` is a positive scale parameter, the current script restricts the search to 0.01 through 10. The table above is retained as a record of the earlier run; rerun the current script before reporting results for this repository version.

## Notes

- The linking-frequency calculation uses random sampling, so small run-to-run differences are expected.
- The example data files are included so the workflow has concrete inputs. Check applicable data-sharing terms before redistributing them elsewhere.
