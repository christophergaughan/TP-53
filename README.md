# TP-53 — Does local sequence context carry information about missense pathogenicity?

**Status: exploratory pilot. The headline result is not established.** The ablations that would
distinguish the interesting explanation from the boring one have not been run. Read
[What would falsify this](#what-would-falsify-this) before citing anything here.

---

## The question

A missense variant is usually scored by what it does to the codon: which amino acid goes in,
how conserved the position is, what it does to the fold. The flanking nucleotides are treated
as scenery.

This repo tests whether that scenery carries signal — whether the sequence *around* a variant
helps predict whether the variant is pathogenic, over and above the codon change itself. Framed
loosely: does the region around a cancer-gene mutation have something like a grammar, where the
same substitution means different things in different neighborhoods?

The framing is less exotic than it sounds. Context-dependent mutation is established: trinucleotide
context organizes the mutational signatures found across thousands of cancer genomes
(Alexandrov et al., 2013), and DNA language models are built on the premise that genomic sequence
has learnable, context-dependent structure (Ji et al., 2021). What is *not* established — and what
this pilot probes — is whether that context predicts **pathogenicity** of a variant once it exists,
rather than just the **rate** at which variants arise.

Those two things are easy to confuse, and confusing them is the central risk here. See below.

---

## What was done

**Comparison.** Two feature sets for the same variants, same splits, same classifier:

- `codon` — the codon change alone (wild-type codon, mutant codon, position in codon)
- `context` — the codon change plus the flanking sequence window and its trinucleotide composition

**Data.** 308 missense variants in `data/masterseq_model_ready.parquet`:

| Gene | Variants | Labeled pathogenic |
|---|---:|---:|
| TP53 | 220 | 81 |
| EGFR | 41 | 16 |
| PIK3CA | 29 | 23 |
| KRAS | 18 | 15 |

Labels come from two sources (`label_source`): ClinVar oncogenicity assertions (127) and existing
hotspot annotations (181). Sequence windows are ~120–121 nt centered on the variant, shorter where
an exon boundary truncates them (65–119 nt for 34 of 308).

**Splits.** Grouped leave-one-cluster-out, so the same mutated site never appears in both train and
test: by site (`data/split_manifest_loco_site.csv`) and by gene (`data/split_manifest_loco_gene.csv`).

**Evaluation.** Discrimination (AUROC, average precision), calibration, and decision curve analysis
(Vickers and Elkin, 2006), which asks whether a model's net benefit beats treat-all and treat-none
across clinically plausible thresholds. A model can improve AUROC and still be useless at the
threshold anyone would act on; DCA is there to catch that.

**Mechanism checks.** Per-position trinucleotide enrichment between pathogenic and benign
(`data/motif_enrichment_3mer_long.csv`, `_top.csv`), motif and dinucleotide permutation tests, and
a frame-periodicity null that asks whether apparent context signal is just codon position in
disguise.

---

## What came out

TP53 only (n = 220, 81 positive), context minus codon-only:

| Metric | Δ | 95% CI |
|---|---:|---|
| AUROC | +0.086 | 0.023 – 0.155 |
| Average precision | +0.046 | 0.008 – 0.087 |

- Motif/dinucleotide permutation: **p = 0.002**
- Frame-periodicity null: no codon-position periodicity detected
- 9 codon-only false negatives recovered by context at the Youden-J threshold
- Calibration and net benefit both improved

**On the numbers you will find in the notebooks.** Some cells report deltas as large as +0.241.
Those come from top/bottom extreme slices (`TP53_delta_top.csv`, `TP53_delta_bottom.csv`), not from
the cross-split average, and they are **not** the result. The table above is the one with intervals
attached; use it.

**Scope.** TP53 only. The other three genes are present for context and are too small to support
anything on their own. No tumor-suppressor-versus-oncogene claim is made — that comparison was
explored and is not supported by this data.

---

## What would falsify this

The result is real in the sense that the interval excludes zero. Whether it is *interesting* turns
on one question the pilot does not yet answer.

**The confound.** Hotspot labels derive from recurrence across tumors. Recurrence depends on how
often a site mutates. How often a site mutates depends heavily on trinucleotide context — CpG
sites deaminate, APOBEC targets TpC, and these rates vary further with local GC content
(Jiang and Zhao, 2006). So a context model could predict the labels extremely well while learning
nothing about function at all. It would simply have rediscovered mutability, and mutability wrote
the labels.

The permutation test does not settle this. It shows the signal is not noise; it says nothing about
whether the signal is selection or mutability.

**Three ablations decide it:**

1. **Shuffle the flanks**, preserving composition and destroying order. If the lift survives, the
   model was using composition — which is the mutability story. If it dies, order matters, which
   is the grammar story.
2. **Mask CpG and TpC.** If the lift collapses, it was deamination and APOBEC all along.
3. **External TP53 holdout** with labels from a source not derived from recurrence counts.

Until those run, the honest summary is: *context predicts the labels better than codon alone, and
we do not yet know why.*

**A third possibility worth keeping on the table.** Exonic splicing enhancers are short motifs
inside coding exons, and a missense variant that disrupts one has consequences beyond the amino
acid substitution (Fairbrother et al., 2002). That is a genuine functional mechanism by which
flanking sequence would matter — neither mutability artifact nor anything as grand as a grammar.
Checking the enriched trinucleotides in `motif_enrichment_3mer_top.csv` against known ESE motifs
is cheap and has not been done.

---

## Layout

```
data/        model-ready parquet, split manifests, motif enrichment tables, hotspot list
notebooks/   exploratory work, dated. TP53_paper_08_21_2025.ipynb holds the headline numbers
figures/     calibration, decision curves, ECE by site, residual panels
receipts/    provenance documents for the pilot run (PDF/HTML)
scripts/     see the warning below
literature/  reference papers and the source variant database exports
artifacts/   run outputs (gitignored)
```

### Known issues

- **`scripts/run_tp53_receipts.py` emits demo data, not results.** The dataframe at the top of the
  file is hardcoded placeholder values (ΔAUROC ≈ +0.28), left from scaffolding the receipt format.
  `make receipts` will produce plots and a CSV that look like output and are not. Either wire it to
  the real per-fold table or delete it. Do not quote anything it produces.
- `notebooks/` contains dated snapshots including near-duplicates. The analysis of record is
  `TP53_paper_08_21_2025.ipynb`.
- No pinned environment. No `requirements.txt`, no lockfile. Results are not currently reproducible
  from a clean machine.
- `literature/` carries ~41 MB of exports from the TP53 variant databases (UMD, and R21 prevalence
  and tumor-variant tables). These are redistributed here for convenience; their original terms of
  use apply and have not been reviewed.

---

## Reproducing

Not currently reproducible end to end — see Known issues. The notebooks run against the committed
parquet files and were executed in Google Colab.

```bash
# clone and inspect
git clone https://github.com/christophergaughan/TP-53.git
cd TP-53

# inspect the model-ready dataset
python3 -c "import pandas as pd; d=pd.read_parquet('data/masterseq_model_ready.parquet'); print(d.shape); print(d.columns.tolist())"
```

---

## References

Alexandrov LB, Nik-Zainal S, Wedge DC, Aparicio SAJR, Behjati S, Biankin AV, et al. Signatures of
mutational processes in human cancer. *Nature*. 2013;500(7463):415–421.
doi:10.1038/nature12477. PMID: 23945592.

Fairbrother WG, Yeh RF, Sharp PA, Burge CB. Predictive identification of exonic splicing enhancers
in human genes. *Science*. 2002;297(5583):1007–1013. doi:10.1126/science.1073774. PMID: 12114529.

Ji Y, Zhou Z, Liu H, Davuluri RV. DNABERT: pre-trained Bidirectional Encoder Representations from
Transformers model for DNA-language in genome. *Bioinformatics*. 2021;37(15):2112–2120.
doi:10.1093/bioinformatics/btab083. PMID: 33538820.

Jiang C, Zhao Z. Directionality of point mutation and 5-methylcytosine deamination rates in the
chimpanzee genome. *BMC Genomics*. 2006;7:316. doi:10.1186/1471-2164-7-316. PMID: 17166280.

Vickers AJ, Elkin EB. Decision curve analysis: a novel method for evaluating prediction models.
*Med Decis Making*. 2006;26(6):565–574. doi:10.1177/0272989X06295361. PMID: 17099194.

---

## Author

Christopher L. Gaughan, Ph.D. — AntibodyML Consulting LLC

## License

See `LICENSE`.
