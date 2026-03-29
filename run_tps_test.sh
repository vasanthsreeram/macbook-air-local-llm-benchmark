#!/bin/bash
export PATH=/Users/vas/.lmstudio/bin:$PATH

CTX=128000
PROMPT="Write a Python function that calculates the fibonacci sequence up to n numbers. Include docstring and type hints."

MODELS=(
  "qwen3.5-35b-a3b"
  "qwen3.5-35b-a3b-mlx-5"
  "qwen3.5-9b"
  "qwen3.5-0.8b-mlx"
  "mlx-qwen3.5-4b-claude-4.6-opus-reasoning-distilled-v2"
  "mlx-qwen3.5-0.8b-claude-4.6-opus-reasoning-distilled"
  "zai-org/glm-4.7-flash"
  "openai/gpt-oss-20b"
  "liquid/lfm2-24b-a2b"
  "liquid/lfm2.5-1.2b"
)

echo "Model,Load_Time_s,Completion_Tokens,Time_s,TPS"

for MODEL in "${MODELS[@]}"; do
  # Unload
  lms unload --all 2>/dev/null
  sleep 2

  # Load
  LOAD_START=$(date +%s)
  lms load "$MODEL" -c $CTX -y 2>/dev/null
  LOAD_END=$(date +%s)
  LOAD_TIME=$((LOAD_END - LOAD_START))

  # Verify loaded
  LOADED=$(curl -s http://localhost:1234/api/v0/models | python3 -c "
import sys, json
data = json.load(sys.stdin)['data']
loaded = [x for x in data if x.get('state') == 'loaded']
print('YES' if loaded else 'NO')
" 2>/dev/null)

  if [ "$LOADED" != "YES" ]; then
    echo "$MODEL,$LOAD_TIME,0,0,FAILED_TO_LOAD"
    continue
  fi

  # TPS test - timed request with 500 max tokens
  START=$(python3 -c "import time; print(time.time())")
  RESULT=$(curl -s http://localhost:1234/v1/chat/completions \
    -H "Content-Type: application/json" \
    -d "{\"model\":\"$MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"$PROMPT\"}],\"max_tokens\":500}" 2>&1)
  END=$(python3 -c "import time; print(time.time())")

  # Parse result
  python3 -c "
import json, sys
try:
    r = json.loads('''$RESULT''')
except:
    try:
        r = json.loads(sys.argv[1])
    except:
        print('$MODEL,$LOAD_TIME,0,0,PARSE_ERROR')
        sys.exit(0)

usage = r.get('usage', {})
comp = usage.get('completion_tokens', 0)
elapsed = round($END - $START, 1)
tps = round(comp / elapsed, 1) if elapsed > 0 else 0
print(f'$MODEL,$LOAD_TIME,{comp},{elapsed},{tps}')
" "$RESULT" 2>/dev/null || echo "$MODEL,$LOAD_TIME,0,0,ERROR"

done

lms unload --all 2>/dev/null
echo ""
echo "DONE"
