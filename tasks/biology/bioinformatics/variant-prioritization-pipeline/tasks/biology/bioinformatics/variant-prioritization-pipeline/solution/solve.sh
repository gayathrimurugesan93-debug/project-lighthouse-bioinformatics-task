#!/usr/bin/env bash
set -euo pipefail

echo "Starting Subcellular Imaging Analysis"

INPUT_DIR="/app/data"
OUTPUT_DIR="/app/solution/output"

mkdir -p "$OUTPUT_DIR"

echo "Validating environment..."

python3 - <<EOF
import numpy
import scipy
import pandas

assert numpy.__version__ == "2.2.5"
assert scipy.__version__ == "1.15.3"
assert pandas.__version__ == "2.2.3"

print("Environment validation successful")
EOF

echo "Running oracle solution..."

python3 /app/solution/pipeline.py \
    --input "$INPUT_DIR" \
    --output "$OUTPUT_DIR/imaging_analysis_report.txt"

echo "Analysis completed."
