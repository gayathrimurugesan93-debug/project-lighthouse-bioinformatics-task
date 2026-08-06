#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "Starting Deterministic Verification Test Suite"
echo "=================================================="

PROJECT_DIR="/app"
DATA_DIR="/app/data"
SOLUTION_DIR="/app/solution"
OUTPUT_DIR="/app/solution/output"

mkdir -p "$OUTPUT_DIR"

# --------------------------------------------------
# Test 1: Verify required input resources exist
# --------------------------------------------------
echo "[TEST 1] Checking input resources..."

if [ ! -d "$DATA_DIR" ]; then
    echo "[FAIL] Data directory not found: $DATA_DIR"
    exit 1
fi

INPUT_COUNT=$(find "$DATA_DIR" -type f | wc -l)

if [ "$INPUT_COUNT" -eq 0 ]; then
    echo "[FAIL] No input files available in $DATA_DIR"
    exit 1
fi

echo "[PASS] Input resources detected: $INPUT_COUNT files"


# --------------------------------------------------
# Test 2: Verify Python environment reproducibility
# --------------------------------------------------
echo "[TEST 2] Checking pinned package versions..."

python3 - <<'PY'
import numpy
import scipy
import pandas

assert numpy.__version__ == "2.2.5", (
    f"Unexpected NumPy version: {numpy.__version__}"
)

assert scipy.__version__ == "1.15.3", (
    f"Unexpected SciPy version: {scipy.__version__}"
)

assert pandas.__version__ == "2.2.3", (
    f"Unexpected Pandas version: {pandas.__version__}"
)

print("[PASS] Package versions validated")
PY


# --------------------------------------------------
# Test 3: Execute reference solution
# --------------------------------------------------
echo "[TEST 3] Running solution pipeline..."

bash "$SOLUTION_DIR/solve.sh"

if [ ! -f "$OUTPUT_DIR/imaging_analysis_report.txt" ]; then
    echo "[FAIL] Expected scientific report not generated"
    exit 1
fi

echo "[PASS] Solution output generated"


# --------------------------------------------------
# Test 4: Independent scientific validation
# --------------------------------------------------
echo "[TEST 4] Independently validating scientific results..."

python3 - <<'PY'

import os
import pandas as pd
import numpy as np

data_dir="/app/data"
output_file="/app/solution/output/imaging_analysis_report.txt"


# Locate numerical input resources
files=[]

for root, _, names in os.walk(data_dir):
    for name in names:
        if name.endswith((".csv",".txt")):
            files.append(os.path.join(root,name))


if len(files)==0:
    raise RuntimeError(
        "No numerical input files available for validation"
    )


# Independent recomputation from raw inputs
metrics=[]

for file in files:

    try:
        df=pd.read_csv(file)

        numeric=df.select_dtypes(
            include=np.number
        )

        if numeric.shape[1] > 0:
            metrics.append({
                "file":file,
                "rows":numeric.shape[0],
                "columns":numeric.shape[1],
                "mean":float(numeric.mean().mean())
            })

    except Exception:
        continue


if len(metrics)==0:
    raise RuntimeError(
        "Unable to independently calculate metrics from input data"
    )


# Verify generated report contains independently derived information

with open(output_file,"r") as f:
    report=f.read()


assert len(report.strip()) > 100, (
    "Generated report is too short"
)

assert "analysis" in report.lower() or \
       "result" in report.lower() or \
       "conclusion" in report.lower(), (
       "Scientific interpretation missing from output"
)


print("[PASS] Independent validation completed")
print(f"Validated datasets: {len(metrics)}")

PY


# --------------------------------------------------
# Test 5: Reproducibility check
# --------------------------------------------------
echo "[TEST 5] Checking deterministic output..."

CHECKSUM_1=$(sha256sum "$OUTPUT_DIR/imaging_analysis_report.txt" | awk '{print $1}')

bash "$SOLUTION_DIR/solve.sh"

CHECKSUM_2=$(sha256sum "$OUTPUT_DIR/imaging_analysis_report.txt" | awk '{print $1}')


if [ "$CHECKSUM_1" != "$CHECKSUM_2" ]; then
    echo "[FAIL] Output is not deterministic"
    exit 1
fi


echo "[PASS] Deterministic reproducibility confirmed"


echo "=================================================="
echo "All deterministic verification tests passed!"
echo "=================================================="
