PY=python3
RUN_DIR?=artifacts/RUN_$(shell date -u +%Y%m%dT%H%M%SZ)

.PHONY: receipts zip clean

## Generate per-fold metrics CSV, plots, and MathJax HTML into a timestamped RUN_DIR
receipts:
	@mkdir -p $(RUN_DIR)
	$(PY) scripts/run_tp53_receipts.py --out $(RUN_DIR)
	@echo "✅ Receipts written to $(RUN_DIR)"

## Zip the most recent RUN_* into artifacts/receipts/
zip:
	@mkdir -p artifacts/receipts
	@LATEST=$$(ls -1d artifacts/RUN_* 2>/dev/null | sort | tail -n 1); \
	if [ -z "$$LATEST" ]; then echo "No RUN_* found. Run 'make receipts' first."; exit 1; fi; \
	ZIP=artifacts/receipts/tp53_receipts_$$(basename $$LATEST).zip; \
	zip -r $$ZIP $$LATEST >/dev/null; \
	echo "📦 Wrote $$ZIP"

## Clean artifacts (careful: nukes all RUNs)
clean:
	rm -rf artifacts/RUN_* artifacts/receipts/*.zip || true
	@echo "🧹 Cleaned artifacts/"

