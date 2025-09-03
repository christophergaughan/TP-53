#!/usr/bin/env python3
import argparse
import pathlib as p
import pandas as pd
import matplotlib.pyplot as plt
import base64

ap = argparse.ArgumentParser()
ap.add_argument("--out", required=True, help="Output RUN directory")
args = ap.parse_args()
OUT = p.Path(args.out)
OUT.mkdir(parents=True, exist_ok=True)

# --- Demo data (swap with your real CSV later) ---
df = pd.DataFrame(
    {
        "fold": [0, 1, 2, 4],
        "auroc_codon": [0.62, 0.65, 0.60, 0.63],
        "auroc_context": [0.89, 0.93, 0.91, 0.91],
        "pr_codon": [0.58, 0.55, 0.57, 0.54],
        "pr_context": [0.84, 0.87, 0.85, 0.83],
    }
)
df["delta_auroc"] = (df.auroc_context - df.auroc_codon).round(3)
df["delta_pr"] = (df.pr_context - df.pr_codon).round(3)
csv_path = OUT / "tp53_per_fold_metrics.csv"
df.to_csv(csv_path, index=False)

# --- Plots (no custom colors per your prefs) ---
plt.figure()
plt.bar(df.fold.astype(str), df.delta_auroc)
plt.xlabel("Fold")
plt.ylabel("ΔAUROC (context − codon)")
plt.title("TP53 LOCO-site: ΔAUROC by Fold")
plt.tight_layout()
plt.savefig(OUT / "delta_auroc_by_fold.png", dpi=200)
plt.close()

plt.figure()
plt.bar(df.fold.astype(str), df.delta_pr)
plt.xlabel("Fold")
plt.ylabel("ΔPR (context − codon)")
plt.title("TP53 LOCO-site: ΔPR by Fold")
plt.tight_layout()
plt.savefig(OUT / "delta_pr_by_fold.png", dpi=200)
plt.close()


# --- MathJax HTML (crisp equations, print to PDF from browser) ---
def b64(path):
    return base64.b64encode(open(path, "rb").read()).decode("utf-8")


html = f"""<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>TP53 Receipts (MathJax)</title>
<script>
window.MathJax = {{ tex: {{ inlineMath: [['$','$'], ['\\\\(','\\\\)']] }}, svg: {{ fontCache: 'global' }} }};
</script>
<script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-svg.js"></script>
<style>
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; margin: 24px; }}
.card {{ border:1px solid #ddd; border-radius:12px; padding:16px; margin:14px 0; }}
table {{ border-collapse: collapse; width:100%; }}
th,td {{ border:1px solid #ddd; padding:6px; text-align:center; }}
th {{ background:#f5f5f5; }}
.imgbox img {{ width:100%; max-width:700px; display:block; margin:auto; }}
@media print {{ .card {{ page-break-inside: avoid; }} }}
</style>
</head>
<body>
  <h1>TP53 Pilot — Receipts</h1>

  <div class="card">
    <h2>Per-Fold Metrics</h2>
    <table>
      <thead><tr><th>fold</th><th>AUROC (codon)</th><th>AUROC (context)</th><th>ΔAUROC</th><th>PR (codon)</th><th>PR (context)</th><th>ΔPR</th></tr></thead>
      <tbody>
        {''.join([f"<tr><td>{int(r.fold)}</td><td>{r.auroc_codon:.2f}</td><td>{r.auroc_context:.2f}</td><td><b>{r.delta_auroc:.2f}</b></td><td>{r.pr_codon:.2f}</td><td>{r.pr_context:.2f}</td><td><b>{r.delta_pr:.2f}</b></td></tr>" for _,r in df.iterrows()])}
      </tbody>
    </table>
    <p style="color:#555">Δ = context − codon.</p>
  </div>

  <div class="card">
    <h2>Figures</h2>
    <div class="imgbox"><h3>ΔAUROC by Fold</h3><img src="data:image/png;base64,{b64(OUT/'delta_auroc_by_fold.png')}" /></div>
    <div class="imgbox"><h3>ΔPR by Fold</h3><img src="data:image/png;base64,{b64(OUT/'delta_pr_by_fold.png')}" /></div>
  </div>

  <div class="card">
    <h2>Key Equations</h2>
    <div>$$\\text{{Precision}}=\\frac{{TP}}{{TP+FP}},\\quad \\text{{Recall}}=\\frac{{TP}}{{TP+FN}}$$</div>
    <div>$$\\mathrm{{AP}}=\\sum_k P(k)\\,\\Delta R(k)$$</div>
    <div>$$\\mathrm{{AUROC}}=\\int_0^1 \\mathrm{{TPR}}(\\mathrm{{FPR}})\\,d\\,\\mathrm{{FPR}}$$</div>
    <div>$$W^+ = \\sum_{{i: d_i>0}} \\mathrm{{rank}}(|d_i|),\\quad d_i=x_i-y_i$$</div>
  </div>

  <div class="card"><p>Tip: Open this HTML in a browser → <b>Print → Save as PDF</b> for vector math.</p></div>
</body>
</html>
"""
html_path = OUT / "tp53_receipts_mathjax.html"
open(html_path, "w", encoding="utf-8").write(html)

print(
    f"Wrote:\n- {csv_path}\n- {OUT/'delta_auroc_by_fold.png'}\n- {OUT/'delta_pr_by_fold.png'}\n- {html_path}"
)
