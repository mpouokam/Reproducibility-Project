#!/usr/bin/env bash
set -euo pipefail

cd /app
mkdir -p logs

echo "[1/6] Mapping HindIII + MspI interactions to genomic bins"
python3 -u /repo/src/locus.py \
  --inter-file "/data/HindIII_MspI_inter.csv" \
  --intra-file "/data/HindIII_MspI_intra.csv" \
  --bed "/app/duan.SC.10000.raw_sub.bed" \
  --out "/app/duan.SC.10000.raw_sub.matrix" \
  > logs/locus.log 2>&1

echo "[2/6] Running Pastis PM2"
pastis-pm2 . > logs/pastis_pm2.log 2>&1

echo "[3/6] Running Pastis PM1"
pastis-pm1 . > logs/pastis_pm1.log 2>&1

echo "[4/6] Running Pastis MDS"
pastis-mds . > logs/pastis_mds.log 2>&1

echo "[5/6] Running Pastis NMDS"
pastis-nmds . > logs/pastis_nmds.log 2>&1

echo "[6/6] Formatting and splitting chromosome coordinates"
python3 -u /repo/src/coordinates_blank.py > logs/coordinates.log 2>&1
python3 -u /repo/src/split_chromosomes.py > logs/split.log 2>&1

echo "Pastis reconstruction and coordinate preparation are complete."
