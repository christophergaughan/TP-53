# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

---

## Project: TP53 Paper Receipts

This repo contains code, workflows, and artifacts for the **TP53 publication analysis**.  
The focus is on evaluating codon vs. sequence context performance (AUROC, PR, calibration, DCA) under LOCO-site validation.  

---

## Conventions

- **Data**:  
  - Raw or external data is **not committed**.  
  - Only small demo CSVs may live under `data/`.  
  - Real results are written under `artifacts/`.

- **Artifacts**:  
  - Each run writes to a timestamped folder:  
    ```
    artifacts/RUN_YYYYMMDDTHHMMSSZ/
    ```  
  - These are **gitignored** by default.  
  - Shareable results (e.g. zip receipts) are placed under:  
    ```
    artifacts/receipts/
    ```

- **Scripts**:  
  - Live in `scripts/` (e.g., `run_tp53_receipts.py`).  
  - Generate per-fold metrics, plots, and MathJax HTML.

- **Makefile**:  
  - `make receipts` → run analysis and drop artifacts.  
  - `make zip` → package results into `artifacts/receipts/*.zip`.  

- **Warp Workflows**:  
  - Defined in `.warp/workflows.yaml`.  
  - Examples:
    - `new RUN` → create a new timestamped run directory.  
    - `tp53: receipts` → run analysis + plots.  
    - `tp53: zip & open` → bundle results.  

---

## Git & Auth

- Repo is connected over **SSH**: `git@github.com:christophergaughan/TP-53.git`  
- Main branch: `main`  
- License: MIT

---

## Common Development Commands

### Analysis Pipeline
```bash
# Run complete TP53 analysis and generate artifacts
make receipts

# Package results for sharing
make zip

# Run specific analysis script
python scripts/run_tp53_receipts.py
```

### Development Setup
```bash
# Install dependencies (when requirements.txt exists)
pip install -r requirements.txt

# Or using conda environment (when environment.yml exists)
conda env create -f environment.yml
conda activate tp53-analysis
```

### Warp Workflows
```bash
# Create new timestamped run directory
warp run "new RUN"

# Execute analysis pipeline
warp run "tp53: receipts"

# Package and open results
warp run "tp53: zip & open"
```

---

## Project Architecture

### Analysis Focus
- **Codon vs. Sequence Context Performance**: Comparing different approaches for predicting outcomes
- **Metrics**: AUROC (Area Under ROC Curve), PR (Precision-Recall), calibration, DCA (Direct Coupling Analysis)
- **Validation**: LOCO-site (Leave-One-Codon-Out) validation methodology

### Expected Directory Structure
```
TP-53/
├── data/                    # Small demo datasets only
├── scripts/                 # Analysis scripts
│   └── run_tp53_receipts.py
├── artifacts/               # Generated results (gitignored)
│   ├── RUN_YYYYMMDDTHHMMSSZ/    # Timestamped runs
│   └── receipts/            # Shareable packaged results
├── .warp/
│   └── workflows.yaml       # Warp workflow definitions
├── Makefile                 # Build and analysis commands
├── requirements.txt         # Python dependencies
└── environment.yml          # Conda environment
```

### Output Artifacts
- **Per-fold metrics**: Quantitative performance measures  
- **Plots**: Visualization of results and comparisons
- **MathJax HTML**: Formatted reports with mathematical notation
- **ZIP receipts**: Packaged results for distribution

---

## Research Context

**TP53** (tumor protein p53) is a crucial tumor suppressor gene. This analysis focuses on:
- Evaluating different computational approaches for sequence analysis
- Cross-validation using LOCO-site methodology to prevent overfitting
- Performance comparison across multiple metrics (AUROC, PR, calibration, DCA)
- Publication-quality result generation with proper statistical validation
