# MacBook Air Local LLM Agentic Coding Benchmark

> Testing local LLMs on a MacBook Air M5 (32GB RAM) for real-world agentic coding tasks using [Pi](https://github.com/badlogic/pi-mono) and [OpenCode](https://opencode.ai) as coding agents, with [LM Studio](https://lmstudio.ai) as the local inference backend.

## Setup

- **Hardware:** MacBook Air (Mac17,3), Apple M5 chip, 32GB unified memory
- **OS:** macOS Darwin 25.3.0
- **Inference:** LM Studio (MLX + GGUF backends), all models loaded at 128k context
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

| Model | Params | Architecture | Quant | Backend | TPS |
|-------|--------|-------------|-------|---------|----:|
| qwen3.5-0.8b-mlx | 0.8B | Dense | 4bit | MLX | 177.1 |
| liquid/lfm2.5-1.2b | 1.2B | Dense | 8bit | MLX | 90.0 |
| qwen3.5-0.8b-opus-reasoning | 0.8B | Dense | bf16 | MLX | 64.8 |
| liquid/lfm2-24b-a2b | 24B | MoE | 4bit | MLX | 50.4 |
| qwen3.5-35b-a3b | 35B | MoE | 4bit | MLX | 46.5 |
| qwen/qwen3.5-35b-a3b | 35B | MoE | Q4_K_M | **GGUF** | 31.4 |
| qwen3.5-35b-a3b-mlx-5 | 35B | MoE | 5bit | MLX | 26.9 |
| qwen3.5-4b-opus-reasoning-v2 (8bit) | 4B | Dense | 8bit | MLX | 26.1 |
| qwen3.5-4b-mlx | 4B | Dense | 8bit | MLX | 25.6 |
| openai/gpt-oss-20b | 20B | Dense | MXFP4 | MLX | 24.3 |
| zai-org/glm-4.7-flash | 30B | MoE | 6bit | MLX | 14.6 |
| qwen3.5-9b | 9B | Dense | 8bit | MLX | 14.4 |
| qwen3.5-4b-opus-reasoning-v2 (bf16) | 4B | Dense | bf16 | MLX | 13.0 |

**Key finding:** MoE models punch well above their weight. The 35B MoE (qwen3.5-35b-a3b) runs at 46.5 tps — faster than a dense 9B model at 14.4 tps — because MoE only activates ~3B parameters per token.

## Agentic Benchmark Results

Sorted by score, then by time:

| Model | Params | TPS | Backend | Agent | Time | Script | Charts | Report | Score |
|-------|--------|----:|---------|-------|-----:|:------:|:------:|:------:|:-----:|
| **openai/gpt-oss-20b** | 20B | 24 | MLX | pi | 64s | Yes | Yes | Yes | **3/3** |
| **qwen3.5-4b-opus-v2 (8bit)** | 4B | 26 | MLX | pi | 67s | Yes | Yes | Yes | **3/3** |
| **qwen/qwen3.5-35b-a3b** | 35B MoE | 31 | **GGUF** | pi | 73s | Yes | Yes | Yes | **3/3** |
| **qwen3.5-35b-a3b-mlx-5** | 35B MoE | 27 | MLX | pi | 100s | Yes | Yes | Yes | **3/3** |
| **qwen3.5-4b-opus-v2 (8bit)** | 4B | 26 | MLX | pi | 118s | Yes | Yes | Yes | **3/3** |
| **qwen/qwen3.5-35b-a3b** | 35B MoE | 31 | **GGUF** | opencode | 160s | Yes | Yes | Yes | **3/3** |
| **openai/gpt-oss-20b** | 20B | 24 | MLX | opencode | 203s | Yes | Yes | Yes | **3/3** |
| **qwen3.5-35b-a3b (MLX 4bit)** | 35B MoE | 47 | MLX | opencode | 223s | Yes | Yes | Yes | **3/3** |
| qwen3.5-0.8b-mlx | 0.8B | 177 | MLX | pi | 585s | Yes | Yes | Yes | **3/3** |
| qwen3.5-4b-opus-v2 (8bit) | 4B | 26 | MLX | opencode | stuck | Yes | Yes | No | 2/3 |
| qwen3.5-35b-a3b (MLX 4bit) | 35B MoE | 47 | MLX | pi | 32s | Yes | No | No | 1/3 |
| qwen3.5-0.8b-mlx | 0.8B | 177 | MLX | opencode | 41s | Yes | No | No | 1/3 |
| qwen3.5-0.8b-opus-reasoning | 0.8B | 65 | MLX | opencode | 999s+ | Yes | No | No | 1/3 |
| liquid/lfm2.5-1.2b | 1.2B | 90 | MLX | pi | 7s | No | No | Yes | 1/3 |
| liquid/lfm2-24b-a2b | 24B MoE | 50 | MLX | pi | 16s | No | No | Yes | 1/3 |
| qwen3.5-4b-mlx (base) | 4B | 26 | MLX | pi | 12m+ | No | No | No | 0/3 |
| qwen3.5-0.8b-opus-reasoning | 0.8B | 65 | MLX | pi | 281s | No | No | No | 0/3 |
| qwen3.5-35b-a3b-mlx-5 | 35B MoE | 27 | MLX | opencode | 10s | Crash | - | - | 0/3 |
| liquid/lfm2.5-1.2b | 1.2B | 90 | MLX | opencode | 7s | No | No | No | 0/3 |
| liquid/lfm2-24b-a2b | 24B MoE | 50 | MLX | opencode | 51s | No | No | No | 0/3 |
| qwen3.5-4b-mlx (base) | 4B | 26 | MLX | opencode | 1s | No | No | No | 0/3 |

## Analysis

### Top 3 Models

#### 1. qwen/qwen3.5-35b-a3b (GGUF Q4_K_M) — Best Overall

The only model besides GPT-OSS 20B to score **3/3 on both agents**. At 31 tps it's faster than GPT-OSS (24 tps), completed pi in 73s, and opencode in 160s. The GGUF Q4_K_M quantization outperforms its MLX equivalents on agentic tasks.

#### 2. openai/gpt-oss-20b — Most Reliable

3/3 on both agents. Fastest pi completion at 64s. Consistent and predictable, uses only 11GB RAM.

#### 3. qwen3.5-4b-opus-reasoning-v2 (8bit) — Best Efficiency

A tiny **4B model** scoring 3/3 on pi in 67s — matching GPT-OSS 20B while using **5x less RAM** (~4GB vs 11GB). Claude Opus distillation makes this punching far above its weight class. Struggled on opencode (2/3, got stuck on report generation).

### GGUF vs MLX: A Clear Winner

The same model (qwen3.5-35b-a3b) was tested in three quantization formats:

| Format | Backend | TPS | Pi Score | Pi Time | OC Score | OC Time |
|--------|---------|----:|:--------:|--------:|:--------:|--------:|
| **Q4_K_M** | **GGUF** | 31 | **3/3** | **73s** | **3/3** | **160s** |
| 4-bit | MLX | 47 | 1/3 | 32s | 3/3 | 223s |
| 5-bit | MLX | 27 | 3/3 | 100s | 0/3 | crash |

**The GGUF Q4_K_M version is the clear winner.** Despite being slightly slower in raw TPS than MLX 4-bit, it produces significantly better tool-calling output. The MLX 4-bit version is fast but unreliable (1/3 on pi), and the MLX 5-bit crashes on opencode due to memory pressure.

This suggests that **quantization quality matters more than speed for agentic tasks**. GGUF's Q4_K_M uses mixed precision (important layers get higher precision), while MLX's 4-bit is uniform — and that difference shows up in tool-calling reliability.

### Claude Opus Distillation: Remarkable Results

| Model | Base | Distilled | Improvement |
|-------|------|-----------|-------------|
| Qwen3.5 4B (pi) | 0/3 (stuck) | **3/3 (67s)** | Broken to perfect |
| Qwen3.5 0.8B (pi) | 3/3 (585s) | 0/3 (281s) | Worse (reasoning overhead) |

The 4B Opus distill is a standout — the base 4B model can't even produce valid tool calls, while the Opus distilled version completes the full task in 67 seconds. However, at 0.8B the distillation adds reasoning overhead without enough capacity to benefit from it.

### Speed vs Intelligence

High TPS does not equal fast task completion:

- **qwen3.5-0.8b-mlx** (177 tps) took **585 seconds** to complete — fast tokens but needed many rounds of attempts
- **gpt-oss-20b** (24 tps) completed in **64 seconds** — slower tokens but got it right with fewer rounds
- **Liquid LFM2** models (50-90 tps) couldn't use tools correctly despite being fast

### Agent Comparison: Pi vs OpenCode

- **Pi** is faster and lighter — smaller system prompt means more context budget for the task
- **OpenCode** has better tool orchestration — it helped the MLX 4-bit model complete all steps where pi couldn't
- OpenCode's larger system prompt can cause memory crashes with big models (22GB+ at 128k context)
- **LFM2 models failed on both agents** — they cannot produce valid tool calls for either framework

### Models That Can't Do Agentic Tasks

- **Liquid LFM2** (both sizes) — cannot produce valid tool-calling format
- **Qwen3.5 0.8B Opus Reasoning** — gets stuck in debug loops, writing broken code and endlessly retrying
- **Qwen3.5 4B base (MLX)** — cannot produce valid tool calls (the Opus distilled version can)
- **Dense models >9B at bf16** — too slow to be practical on 32GB MacBook Air

## Models Excluded from Agentic Test

| Model | Reason |
|-------|--------|
| qwen3.5-27b-claude-4.6-opus-distilled-mlx | Dense 27B — took 22 min on pi due to low tps |
| qwen3.5-9b | Dense 9B at 8bit, only 14.4 tps |
| qwen3.5-4b-opus-reasoning-v2 (bf16) | bf16 quantization, only 13 tps (use 8bit version instead) |
| zai-org/glm-4.7-flash | 30B MoE but only 14.6 tps |
| mistralai/devstral-small-2-2512 | Too slow to complete TPS test |

## Recommendations

For **agentic coding on a MacBook Air M5 32GB**:

1. **Best overall:** `qwen/qwen3.5-35b-a3b` (GGUF Q4_K_M) — 3/3 on both agents, 31 tps, reliable
2. **Best reliability:** `openai/gpt-oss-20b` — 3/3 on both agents, only 11GB RAM
3. **Best efficiency:** `qwen3.5-4b-opus-reasoning-distilled-v2` (8bit) — 3/3 on pi, only ~4GB RAM
4. **Use GGUF over MLX** for the same model when agentic quality matters
5. **Avoid:** LFM2 models (broken tool use), bf16 models (too slow), base models <9B (can't do tool calling)

## Reproducing

1. Install [LM Studio](https://lmstudio.ai), [Pi](https://github.com/badlogic/pi-mono), and [OpenCode](https://opencode.ai)
2. Download models in LM Studio
3. Configure Pi: edit `~/.pi/agent/models.json` ([setup guide](https://github.com/vasanthsreeram/pi-lmstudio-guide))
4. Configure OpenCode: edit `opencode.json` in your project root
5. Run `bash run_tps_test.sh` for TPS benchmarks
6. Run `bash run_clean_benchmark.sh` for agentic benchmarks
