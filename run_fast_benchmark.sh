#!/bin/bash
export PATH=/Users/vas/.opencode/bin:/Users/vas/.lmstudio/bin:$PATH

CTX=128000
BENCHMARK_DIR="/Users/vas/lm-benchmark"
RESULTS_DIR="$BENCHMARK_DIR/results_clean"

PROMPT_PI='Read the file /Users/vas/lm-benchmark/data/sales.csv. Then do all of the following steps: 1) Create a Python script called OUTDIR/analysis.py that uses pandas and matplotlib to: load the CSV, generate a bar chart of total revenue by region (save as OUTDIR/revenue_by_region.png), and a pie chart of units sold by product (save as OUTDIR/units_by_product.png). 2) Run the script with python3. 3) Create a file called OUTDIR/report.md with a markdown report summarizing: total revenue, total profit (revenue minus cost), profit margin percentage, the top performing region by revenue, the top selling product by units, and a monthly trend summary. Do all steps now without asking questions.'

PROMPT_OC='Read the file data/sales.csv. Then do all of the following steps: 1) Create a Python script called OUTDIR/analysis.py that uses pandas and matplotlib to: load data/sales.csv using absolute path /Users/vas/lm-benchmark/data/sales.csv, generate a bar chart of total revenue by region (save as OUTDIR/revenue_by_region.png), and a pie chart of units sold by product (save as OUTDIR/units_by_product.png). 2) Run the script with python3. 3) Create a file called OUTDIR/report.md with a markdown report summarizing: total revenue, total profit (revenue minus cost), profit margin percentage, the top performing region by revenue, the top selling product by units, and a monthly trend summary. Do all steps now without asking questions.'

# Fastest to slowest, >20 TPS, not already tested
MODELS=(
  "qwen3.5-0.8b-mlx|qwen08b|177"
  "liquid/lfm2.5-1.2b|lfm25-1b|90"
  "mlx-qwen3.5-0.8b-claude-4.6-opus-reasoning-distilled|qwen08b-opus|65"
  "liquid/lfm2-24b-a2b|lfm2-24b|50"
  "openai/gpt-oss-20b|gpt-oss-20b|24"
)

echo "=============================================="
echo " FAST MODEL BENCHMARK - $(date)"
echo " Context: $CTX | Models: ${#MODELS[@]}"
echo "=============================================="

TOTAL=${#MODELS[@]}
IDX=0

for entry in "${MODELS[@]}"; do
  IFS='|' read -r MODEL_ID SHORT_NAME TPS <<< "$entry"
  IDX=$((IDX + 1))

  PI_DIR="$RESULTS_DIR/${SHORT_NAME}_pi"
  OC_DIR="$RESULTS_DIR/${SHORT_NAME}_oc"
  rm -rf "$PI_DIR" "$OC_DIR"
  mkdir -p "$PI_DIR" "$OC_DIR"

  echo ""
  echo "=============================================="
  echo " [$IDX/$TOTAL] $MODEL_ID (~${TPS} tps)"
  echo "=============================================="

  # Unload everything
  lms unload --all 2>/dev/null
  sleep 2

  # Load
  echo "Loading with ctx=$CTX..."
  LOAD_START=$(date +%s)
  lms load "$MODEL_ID" -c $CTX -y 2>/dev/null
  LOAD_END=$(date +%s)
  LOAD_TIME=$((LOAD_END - LOAD_START))

  # Verify
  LOADED_CTX=$(curl -s http://localhost:1234/api/v0/models | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
loaded = [x for x in data if x.get('state') == 'loaded']
if loaded:
    print(loaded[0].get('loaded_context_length', 'unknown'))
else:
    print('FAILED')
" 2>/dev/null)
  echo "Load: ${LOAD_TIME}s | Context: $LOADED_CTX"

  if [ "$LOADED_CTX" = "FAILED" ]; then
    echo "SKIP: Model failed to load"
    echo "FAILED TO LOAD" > "$PI_DIR/output.txt"
    echo "FAILED TO LOAD" > "$OC_DIR/output.txt"
    continue
  fi

  # --- PI TEST ---
  echo ""
  echo "  [PI] Running..."
  PI_PROMPT="${PROMPT_PI//OUTDIR/$PI_DIR}"
  PI_START=$(date +%s)
  pi --provider lmstudio --model "$MODEL_ID" --tools read,bash,edit,write -p "$PI_PROMPT" 2>&1 | cat > "$PI_DIR/output.txt"
  PI_END=$(date +%s)
  PI_TIME=$((PI_END - PI_START))

  PI_SCRIPT=$([ -f "$PI_DIR/analysis.py" ] && echo "YES" || echo "NO")
  PI_CHART1=$([ -f "$PI_DIR/revenue_by_region.png" ] && echo "YES" || echo "NO")
  PI_CHART2=$([ -f "$PI_DIR/units_by_product.png" ] && echo "YES" || echo "NO")
  PI_REPORT=$([ -f "$PI_DIR/report.md" ] && echo "YES" || echo "NO")
  echo "  [PI] ${PI_TIME}s | Script:$PI_SCRIPT Charts:$PI_CHART1/$PI_CHART2 Report:$PI_REPORT"

  cat > "$PI_DIR/meta.json" << METAEOF
{
  "model": "$MODEL_ID",
  "agent": "pi",
  "context_length": $LOADED_CTX,
  "time_seconds": $PI_TIME,
  "load_time_seconds": $LOAD_TIME,
  "tps": $TPS,
  "has_script": "$PI_SCRIPT",
  "has_chart_revenue": "$PI_CHART1",
  "has_chart_units": "$PI_CHART2",
  "has_report": "$PI_REPORT"
}
METAEOF

  # --- OPENCODE TEST ---
  echo ""
  echo "  [OC] Running..."
  OC_PROMPT="${PROMPT_OC//OUTDIR/$OC_DIR}"
  OC_START=$(date +%s)
  cd "$BENCHMARK_DIR"
  opencode run -m "lms-local/$MODEL_ID" "$OC_PROMPT" 2>&1 | cat > "$OC_DIR/output.txt"
  OC_END=$(date +%s)
  OC_TIME=$((OC_END - OC_START))

  OC_SCRIPT=$([ -f "$OC_DIR/analysis.py" ] && echo "YES" || echo "NO")
  OC_CHART1=$([ -f "$OC_DIR/revenue_by_region.png" ] && echo "YES" || echo "NO")
  OC_CHART2=$([ -f "$OC_DIR/units_by_product.png" ] && echo "YES" || echo "NO")
  OC_REPORT=$([ -f "$OC_DIR/report.md" ] && echo "YES" || echo "NO")
  echo "  [OC] ${OC_TIME}s | Script:$OC_SCRIPT Charts:$OC_CHART1/$OC_CHART2 Report:$OC_REPORT"

  cat > "$OC_DIR/meta.json" << METAEOF
{
  "model": "$MODEL_ID",
  "agent": "opencode",
  "context_length": $LOADED_CTX,
  "time_seconds": $OC_TIME,
  "load_time_seconds": $LOAD_TIME,
  "tps": $TPS,
  "has_script": "$OC_SCRIPT",
  "has_chart_revenue": "$OC_CHART1",
  "has_chart_units": "$OC_CHART2",
  "has_report": "$OC_REPORT"
}
METAEOF

  # Unload
  echo ""
  echo "  Unloading..."
  lms unload --all 2>/dev/null
  sleep 3
done

# --- FULL SUMMARY ---
echo ""
echo "=============================================="
echo " FULL SUMMARY (all results)"
echo "=============================================="

python3 << 'PYEOF'
import json, os, glob

results_dir = "/Users/vas/lm-benchmark/results_clean"
rows = []

for meta_file in sorted(glob.glob(os.path.join(results_dir, "*/meta.json"))):
    with open(meta_file) as f:
        m = json.load(f)

    steps = 0
    if m["has_script"] == "YES": steps += 1
    if m["has_chart_revenue"] == "YES" and m["has_chart_units"] == "YES": steps += 1
    if m["has_report"] == "YES": steps += 1

    rows.append({
        "model": m["model"],
        "agent": m["agent"],
        "time": m["time_seconds"],
        "tps": m.get("tps", "?"),
        "script": m["has_script"],
        "charts": "YES" if m["has_chart_revenue"] == "YES" and m["has_chart_units"] == "YES" else "NO",
        "report": m["has_report"],
        "steps": steps,
        "score": round(steps / 3 * 10, 1)
    })

print()
print("{:<55} {:<10} {:>5} {:>6} {:>8} {:>8} {:>8} {:>6} {:>6}".format(
    "Model", "Agent", "TPS", "Time", "Script", "Charts", "Report", "Steps", "Score"))
print("-" * 122)

for r in sorted(rows, key=lambda x: (-x["steps"], x["time"])):
    print("{:<55} {:<10} {:>5} {:>5}s {:>8} {:>8} {:>8} {:>5}/3 {:>5}".format(
        r["model"], r["agent"], r["tps"], r["time"],
        r["script"], r["charts"], r["report"], r["steps"], r["score"]))

with open(os.path.join(results_dir, "summary.json"), "w") as f:
    json.dump(rows, f, indent=2)

print()
print("Summary saved to {}/summary.json".format(results_dir))
PYEOF

echo ""
echo "===== BENCHMARK COMPLETE ====="
