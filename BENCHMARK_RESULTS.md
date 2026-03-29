# MacBook Air Local LLM Agentic Coding Benchmark

> Testing local LLMs on a MacBook Air M5 (32GB RAM) for real-world agentic coding tasks using [Pi](https://github.com/badlogic/pi-mono) and [OpenCode](https://opencode.ai) as coding agents, with [LM Studio](https://lmstudio.ai) as the local inference backend.

## Setup

- **Hardware:** MacBook Air (Mac17,3), Apple M5 chip, 32GB unified memory
- **OS:** macOS Darwin 25.3.0
- **Inference:** LM Studio (MLX backend), all models loaded at 128k context
- **Agents:** Pi CLI v0.63.1, OpenCode v1.3.3
- **Date:** 2026-03-29

## The Task

A multi-step agentic coding task that tests tool orchestration, code generation, execution, and report writing:

1. **Read** a CSV sales dataset (24 rows, 6 columns: date, region, product, units_sold, revenue, cost)
2. **Create and run** a Python script using pandas + matplotlib that generates a bar chart of total revenue by region and a pie chart of units sold by product
3. **Write** a markdown report summarizing: total revenue, profit, margin %, top region, top product, monthly trends

**Scoring:** 3 steps — script created (1pt), charts generated via execution (1pt), report written (1pt). Max 3/3.

## TPS Results (Tokens Per Second)

Raw inference speed measured with 500 max token generation at 128k context:

| Model | Params | Architecture | Quant | TPS |
|-------|--------|-------------|-------|----:|
| qwen3.5-0.8b-mlx | 0.8B | Dense | 4bit | 177.1 |
| liquid/lfm2.5-1.2b | 1.2B | Dense | 8bit | 90.0 |
| qwen3.5-0.8b-opus-reasoning | 0.8B | Dense | bf16 | 64.8 |
| liquid/lfm2-24b-a2b | 24B | MoE | 4bit | 50.4 |
| qwen3.5-35b-a3b | 35B | MoE | 4bit | 46.5 |
| qwen3.5-35b-a3b-mlx-5 | 35B | MoE | 5bit | 26.9 |
| openai/gpt-oss-20b | 20B | Dense | MXFP4 | 24.3 |
| zai-org/glm-4.7-flash | 30B | MoE | 6bit | 14.6 |
| qwen3.5-9b | 9B | Dense | 8bit | 14.4 |
| qwen3.5-4b-opus-reasoning-v2 | 4B | Dense | bf16 | 13.0 |

**Key finding:** MoE models punch well above their weight. The 35B MoE (qwen3.5-35b-a3b) runs at 46.5 tps — faster than a dense 9B model at 14.4 tps — because MoE only activates ~3B parameters per token.

## Agentic Benchmark Results

Sorted by score, then by time:

| Model | Params | TPS | Agent | Time | Script | Charts | Report | Score |
|-------|--------|----:|-------|-----:|:------:|:------:|:------:|:-----:|
| **openai/gpt-oss-20b** | 20B | 24 | pi | 64s | Yes | Yes | Yes | **3/3** |
| **openai/gpt-oss-20b** | 20B | 24 | opencode | 203s | Yes | Yes | Yes | **3/3** |
| **qwen3.5-35b-a3b** | 35B MoE | 47 | opencode | 223s | Yes | Yes | Yes | **3/3** |
| **qwen3.5-35b-a3b-mlx-5** | 35B MoE | 27 | pi | 100s | Yes | Yes | Yes | **3/3** |
| qwen3.5-0.8b-mlx | 0.8B | 177 | pi | 585s | Yes | Yes | Yes | **3/3** |
| qwen3.5-35b-a3b | 35B MoE | 47 | pi | 32s | Yes | No | No | 1/3 |
| qwen3.5-0.8b-mlx | 0.8B | 177 | opencode | 41s | Yes | No | No | 1/3 |
| qwen3.5-0.8b-opus-reasoning | 0.8B | 65 | opencode | 999s+ | Yes | No | No | 1/3 |
| liquid/lfm2.5-1.2b | 1.2B | 90 | pi | 7s | No | No | Yes | 1/3 |
| liquid/lfm2-24b-a2b | 24B MoE | 50 | pi | 16s | No | No | Yes | 1/3 |
| qwen3.5-0.8b-opus-reasoning | 0.8B | 65 | pi | 281s | No | No | No | 0/3 |
| qwen3.5-35b-a3b-mlx-5 | 35B MoE | 27 | opencode | 10s | Crash | - | - | 0/3 |
| liquid/lfm2.5-1.2b | 1.2B | 90 | opencode | 7s | No | No | No | 0/3 |
| liquid/lfm2-24b-a2b | 24B MoE | 50 | opencode | 51s | No | No | No | 0/3 |

## Analysis

### Best Overall: GPT-OSS 20B

The only model to score 3/3 on **both** agents. At 24 tps it's not the fastest, but it consistently completes multi-step agentic tasks. 64 seconds on pi is the fastest full completion.

### Best on Pi: Qwen3.5 35B MoE (5-bit)

Completed all 3 steps in 100 seconds. The 5-bit quantization gives better quality than the 4-bit version (which only scored 1/3 on pi) at the cost of slower inference (27 vs 47 tps).

### Best on OpenCode: Qwen3.5 35B MoE (4-bit)

Completed all 3 steps in 223 seconds. OpenCode's tool orchestration helped this model succeed where pi couldn't get it past step 1.

### Speed vs Intelligence

High TPS does not equal fast task completion:

- **qwen3.5-0.8b-mlx** (177 tps) took **585 seconds** to complete — fast tokens but needed many rounds of attempts
- **gpt-oss-20b** (24 tps) completed in **64 seconds** — slower tokens but got it right with fewer rounds
- **Liquid LFM2** models (50-90 tps) couldn't use tools correctly despite being fast

### Agent Comparison: Pi vs OpenCode

- **Pi** has a smaller system prompt, so models load faster and have more context budget for the task
- **OpenCode** has better tool orchestration — it helped qwen3.5-35b-a3b (4-bit) complete all steps where pi couldn't
- OpenCode crashed on the 5-bit 35B model due to memory pressure (22GB model + 128k context + OpenCode overhead on 32GB RAM)
- **LFM2 models failed on both agents** — they cannot produce valid tool calls for either framework

### Models That Can't Do Agentic Tasks

- **Liquid LFM2** (both sizes) — cannot produce valid tool-calling format
- **Qwen3.5 0.8B Opus Reasoning** — gets stuck in debug loops, writing broken code and endlessly retrying
- **Dense models >9B at bf16** — too slow to be practical on 32GB MacBook Air

## Models Excluded

| Model | Reason |
|-------|--------|
| qwen3.5-27b-claude-4.6-opus-distilled-mlx | Dense 27B — took 22 min on pi due to low tps |
| qwen3.5-9b | Dense 9B at 8bit, only 14.4 tps |
| qwen3.5-4b-opus-reasoning-v2 | bf16, only 13 tps |
| zai-org/glm-4.7-flash | 30B MoE but only 14.6 tps |
| mistralai/devstral-small-2-2512 | Too slow to even complete TPS test |

## Recommendations

For **agentic coding on a MacBook Air M5 32GB**:

1. **Best quality:** `openai/gpt-oss-20b` — works on both agents, fast completions
2. **Best speed/quality trade-off:** `qwen3.5-35b-a3b` (4-bit MoE) on OpenCode — 47 tps, reliable
3. **Best on Pi:** `qwen3.5-35b-a3b-mlx-5` (5-bit MoE) — 100s full completion
4. **Avoid:** LFM2 models (broken tool use), bf16 models (too slow), dense models >9B (low tps)

## Reproducing

1. Install [LM Studio](https://lmstudio.ai), [Pi](https://github.com/badlogic/pi-mono), and [OpenCode](https://opencode.ai)
2. Download models in LM Studio
3. Configure Pi: edit `~/.pi/agent/models.json` ([setup guide](https://github.com/vasanthsreeram/pi-lmstudio-guide))
4. Configure OpenCode: edit `opencode.json` in your project root
5. Run `bash run_tps_test.sh` for TPS benchmarks
6. Run `bash run_clean_benchmark.sh` for agentic benchmarks
