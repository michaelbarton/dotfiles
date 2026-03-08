# data-audit: specification

A Python package for LLM-powered auditing of data artifacts — dbt models, SQL
scripts, Jupyter notebooks, Quarto documents, and flat data files. Designed to
be run by a single analyst or orchestrated by an autonomous "project manager"
agent that can expand the scope of an audit based on initial findings.

## Problem

Data teams accumulate a mix of dbt models, ad-hoc notebooks, CSV/Parquet
exports, and glue scripts. Quality issues hide at the seams: a notebook reads a
stale CSV export instead of the dbt model, a model silently fans out on a join,
a Quarto report hardcodes a date filter that drifts. Today's tooling audits
each artifact type in isolation — if at all.

## Goals

1. Audit heterogeneous data artifacts (dbt SQL, notebooks, flat files) through
   a unified interface.
2. Support an autonomous orchestration loop where an LLM "project manager" can
   review initial findings and spawn follow-up audits when warranted.
3. Produce structured, machine-readable findings alongside human-readable
   reports so that both people and agents can act on results.
4. Be LLM-backend agnostic — work with direct API calls, local models, or CLI
   wrappers.
5. Ship as an installable Python package (`pip install data-audit`) with a CLI
   entry point.

## Non-goals

- Replacing dbt test or Great Expectations for deterministic, rule-based
  testing. This tool is for exploratory, LLM-driven analysis.
- Real-time or CI-blocking checks. This is an offline review tool.
- Supporting non-Python notebook kernels (R, Julia) in the first version.

---

## Artifact types

### dbt models (.sql within a dbt project)

This is the existing capability. Context gathering includes:

- Compile the model (`dbt compile`)
- Fetch sample rows (`dbt show --output json`)
- Extract lineage — immediate parents and children (`dbt ls`)
- Discover existing tests from `schema.yml` files
- Read the source SQL

Audit focus: join correctness, grain/uniqueness, filter logic, type mismatches,
test coverage gaps, upstream dependency risks. See the existing
`dbt_deep_analysis.md` prompt template for the full checklist.

### dbt schema files (.yml)

Context gathering:

- Parse the YAML
- Cross-reference with the models it describes (do all models have schema
  entries? do all columns exist?)
- Check test coverage across models

Audit focus: missing descriptions, undocumented columns, missing or weak tests,
inconsistent naming conventions, stale entries for deleted models.

### Jupyter notebooks (.ipynb)

Notebooks vary widely. An analyst might be:

- Running SQL queries against a warehouse
- Reading CSV/Parquet/Excel files from disk or S3
- Pulling data from an API
- Doing pandas/polars transformations
- Producing charts or summary statistics

Context gathering:

- Extract all code cells and their outputs (where present)
- Identify data sources: SQL connection strings, file paths
  (`pd.read_csv(...)`, `pd.read_parquet(...)`), API calls
- Extract imported libraries to understand the toolchain
- Note cell execution order and whether outputs are stale (execution count
  gaps, missing outputs)
- If the notebook references dbt models or known tables, cross-reference with
  the dbt project

Audit focus:
- **Data source hygiene**: is the notebook reading raw files that should come
  from a managed source? Are file paths hardcoded or parameterized? Are
  connection strings embedded in code?
- **Reproducibility**: are cells ordered logically? Are there cells that depend
  on execution side effects? Are random seeds set? Are outputs present and
  consistent with the code?
- **Transformation logic**: are there pandas/polars transformations that
  duplicate or contradict dbt model logic? Could this logic be pushed into the
  transformation layer?
- **Data quality in-notebook**: are there silent drops (inner joins, dropna)
  that could hide problems? Are filters reasonable? Are aggregations correct?
- **Staleness**: do outputs reference dates/values that suggest the notebook
  hasn't been re-run recently?

### Quarto documents (.qmd)

Similar to notebooks but with additional structure:

- YAML front matter (params, output format, execution options)
- Mixed prose and code chunks
- Cross-references and callouts

Context gathering:

- Parse YAML front matter for parameters and execution options
- Extract code chunks (```{python} blocks)
- Identify data sources same as notebooks
- Note `freeze: true` or other execution-control settings

Audit focus: same as notebooks, plus parameter handling (are params used
consistently? are defaults reasonable?), and whether `freeze` settings mean
outputs could be stale.

### Flat data files (.csv, .parquet, .json, .xlsx)

Not code artifacts — these are data. An analyst might ask "audit this export"
or "check this CSV for issues." The PM agent might also flag a file referenced
by a notebook for closer inspection.

Context gathering:

- Read schema/column names and types
- Compute basic profiling: row count, null rates, cardinality, min/max/mean
  for numerics, sample values for categoricals, date ranges for timestamps
- For Parquet: extract embedded schema metadata
- For CSV: detect delimiter, encoding, quoting issues
- If the file is referenced by a notebook or dbt model, note that relationship

Audit focus:
- **Schema issues**: mixed types in columns, inconsistent date formats,
  encoding problems
- **Completeness**: unexpected nulls, empty columns, truncated rows
- **Distribution anomalies**: outliers, impossible values (negative ages,
  future dates), suspicious cardinality (a "country" column with 3 values)
- **Staleness**: if file metadata includes a timestamp, flag if it's old
  relative to the project

---

## Architecture

### Core data model

```
Finding
  id: str                  # unique within an audit run
  artifact: str            # path or identifier of the audited artifact
  artifact_type: str       # "dbt_model", "notebook", "data_file", etc.
  category: str            # "join_correctness", "data_quality", "reproducibility", etc.
  severity: Severity       # critical | warning | info
  title: str               # one-line summary
  description: str         # full explanation
  evidence: str | None     # query, code snippet, or data sample that demonstrates the issue
  suggested_fix: str | None
  downstream_impact: list[str]  # artifact IDs affected if this isn't fixed
  metadata: dict           # arbitrary extra context (column names, line numbers, etc.)

AuditResult
  artifact: str
  artifact_type: str
  findings: list[Finding]
  context_summary: str     # what context was gathered (for traceability)
  llm_model: str           # which LLM produced this result
  duration_seconds: float
  raw_report: str          # the full markdown report as returned by the LLM

AuditPlan
  tasks: list[AuditTask]   # the full set of tasks (initial + follow-ups)

AuditTask
  artifact: str
  artifact_type: str
  prompt_template: str     # which prompt to use
  reason: str              # why this task exists ("initial scan" or "follow-up: NULL propagation from stg_orders")
  priority: int
  parent_task_id: str | None  # if this is a follow-up, which task spawned it
  status: pending | running | completed | failed
```

### Auditor interface

Each artifact type has an auditor that implements:

```python
class Auditor(Protocol):
    """Gathers context for an artifact and produces an LLM-ready prompt."""

    artifact_type: str

    def can_handle(self, path: Path) -> bool:
        """Return True if this auditor knows how to handle the given path."""
        ...

    def gather_context(self, path: Path, config: AuditConfig) -> AuditContext:
        """Read the artifact and its surroundings, return structured context."""
        ...

    def render_prompt(self, context: AuditContext, template: str) -> str:
        """Fill the prompt template with gathered context."""
        ...

    def parse_findings(self, raw_response: str, context: AuditContext) -> list[Finding]:
        """Extract structured findings from the LLM's raw response."""
        ...
```

Concrete implementations:

- `DbtModelAuditor` — wraps the existing compile/show/lineage/test-discovery logic
- `DbtSchemaAuditor` — parses YAML, cross-references models
- `NotebookAuditor` — extracts cells, identifies data sources, checks reproducibility
- `QuartoAuditor` — extends NotebookAuditor with front-matter parsing
- `DataFileAuditor` — profiles CSVs, Parquet, JSON, Excel files

### LLM backend interface

```python
class LLMBackend(Protocol):
    """Send a prompt to an LLM and get a response."""

    def complete(self, prompt: str, system: str | None = None) -> str:
        ...

    def list_models(self) -> list[str]:
        ...
```

Concrete implementations:

- `CursorAgentBackend` — wraps the current `cursor-agent` CLI (preserves
  existing workflow)
- `AnthropicBackend` — direct Claude API calls via the Anthropic SDK
- `LiteLLMBackend` — any model supported by litellm (OpenAI, local, etc.)

### Orchestrator (the "project manager")

The orchestrator is the key new capability. It operates in a loop:

```
1. Build initial AuditPlan from user-provided paths
2. While there are pending tasks and budget remains:
   a. Pick next task(s) by priority
   b. Run auditor(s) in parallel → collect AuditResults
   c. Pass results to PM agent with the question:
      "Given these findings, should we investigate anything further?"
   d. PM agent returns zero or more follow-up AuditTasks
      (e.g., "audit downstream model X", "profile data file Y referenced
       in notebook Z", "do a deeper join analysis on model W")
   e. Add follow-up tasks to the plan
3. Synthesize all AuditResults into a final report
```

**Budget controls** — the orchestrator enforces limits to prevent runaway
analysis:

- `max_depth`: how many rounds of follow-ups (default: 2)
- `max_tasks`: total task cap across all rounds (default: 20)
- `max_wall_clock`: overall time limit (default: 30 minutes)
- `max_tokens`: approximate token budget across all LLM calls

The PM agent prompt instructs it to be conservative — only spawn follow-up
tasks when there's concrete evidence that a finding has broader implications,
not speculatively.

### Task graph

Tasks form a tree (not a DAG — a follow-up task has exactly one parent). The
graph is used for:

- Tracing why an audit was run ("this file was audited because the PM agent
  identified it as a downstream consumer of a model with a join fan-out")
- Reporting: the final synthesis groups findings by their provenance
- Budget tracking: depth = longest path from root to leaf

### Prompt templates

Ship as package data under `data_audit/prompts/`:

```
dbt_model_deep.md       # existing dbt_deep_analysis.md
dbt_model_quick.md      # existing dbt_quick_analysis.md
dbt_schema.md           # schema.yml audit
notebook.md             # Jupyter/Quarto notebook audit
data_file.md            # flat file profiling + audit
orchestrator.md         # PM agent system prompt
synthesis.md            # final report synthesis prompt
```

The existing Handlebars-style template engine (`{{var}}`, `{{#if var}}`,
`{{^if var}}`) is retained. It's simple and sufficient.

---

## CLI

```
data-audit [OPTIONS] PATHS...
```

**Arguments:**

- `PATHS` — files, directories, or globs. The tool auto-detects artifact type
  by extension (`.sql` in a dbt project → dbt model, `.ipynb` → notebook,
  `.csv`/`.parquet` → data file, etc.). Directories are walked recursively.

**Options:**

| Flag | Default | Description |
|------|---------|-------------|
| `--llm` | (required, repeatable) | LLM model to use for audits |
| `--backend` | `anthropic` | LLM backend: `anthropic`, `cursor-agent`, `litellm` |
| `--dbt-root` | auto-detect | Path to dbt project root (for dbt artifacts) |
| `--prompt` | built-in | Override the prompt template |
| `--output-dir` | `./audit_reports` | Where to write reports |
| `--output-format` | `markdown` | `markdown`, `json`, or `both` |
| `--limit` | `20` | Row limit for dbt show / data file sampling |
| `--synthesis-model` | same as `--llm` | LLM for synthesis step |
| `--orchestrate` | `false` | Enable the PM orchestration loop |
| `--max-depth` | `2` | Max follow-up rounds (requires `--orchestrate`) |
| `--max-tasks` | `20` | Max total audit tasks (requires `--orchestrate`) |
| `--concurrency` | `3` | Max parallel LLM calls |
| `--timeout` | `900` | Per-task timeout in seconds |
| `--verbose` | `false` | Show detailed progress |

**Examples:**

```bash
# Audit a few dbt models (current behavior, just packaged)
data-audit models/stg_orders.sql models/int_revenue.sql \
  --llm claude-sonnet-4-6 --dbt-root .

# Audit a notebook
data-audit analysis/revenue_deep_dive.ipynb --llm claude-sonnet-4-6

# Audit an export file
data-audit exports/monthly_summary.csv --llm claude-sonnet-4-6

# Audit an entire directory with PM orchestration
data-audit models/ notebooks/ exports/ \
  --llm claude-sonnet-4-6 \
  --orchestrate --max-depth 2 --max-tasks 15

# JSON output for programmatic consumption
data-audit models/stg_orders.sql --llm claude-sonnet-4-6 --output-format json
```

---

## Programmatic API

```python
from data_audit import audit, AuditConfig
from data_audit.backends import AnthropicBackend

config = AuditConfig(
    llm="claude-sonnet-4-6",
    backend=AnthropicBackend(),
    concurrency=3,
    orchestrate=True,
    max_depth=2,
)

# Audit specific files
results = audit(["models/stg_orders.sql", "analysis/deep_dive.ipynb"], config)

for finding in results.all_findings():
    print(f"[{finding.severity}] {finding.artifact}: {finding.title}")

# Access the structured data
results.to_json("audit_output.json")
results.to_markdown("audit_report.md")
```

---

## Package structure

```
data-audit/
  pyproject.toml
  src/data_audit/
    __init__.py             # public API: audit(), AuditConfig
    cli.py                  # click CLI entry point

    # Core data model
    models.py               # Finding, AuditResult, AuditTask, AuditPlan

    # Auditors — one per artifact type
    auditors/
      __init__.py
      base.py               # Auditor protocol
      dbt_model.py          # compile, show, lineage, test discovery
      dbt_schema.py         # schema.yml cross-referencing
      notebook.py           # .ipynb extraction and analysis
      quarto.py             # .qmd front-matter + code chunks
      data_file.py          # CSV, Parquet, JSON, Excel profiling
      registry.py           # maps file extensions/patterns → auditors

    # Context gathering utilities
    context/
      __init__.py
      dbt.py                # dbt compile/show/ls wrappers
      notebook_parser.py    # cell extraction, data source detection
      file_profiler.py      # column stats, null rates, distributions
      template.py           # Handlebars-style template rendering

    # LLM backends
    backends/
      __init__.py
      base.py               # LLMBackend protocol
      anthropic.py          # direct Anthropic API
      cursor_agent.py       # subprocess wrapper for cursor-agent CLI
      litellm.py            # litellm pass-through

    # Orchestration
    orchestrator/
      __init__.py
      pm_agent.py           # project manager LLM logic
      task_graph.py         # task tree, budget tracking
      executor.py           # parallel task execution
      synthesizer.py        # final report generation

    # Shipped prompt templates
    prompts/
      dbt_model_deep.md
      dbt_model_quick.md
      dbt_schema.md
      notebook.md
      quarto.md
      data_file.md
      orchestrator.md
      synthesis.md
```

---

## Migration path from current code

The existing scripts (`dbt_batch_audit.py`, `dbt_analyse.py`) become thin
wrappers or are replaced entirely by the package CLI. Mapping:

| Current | Package equivalent |
|---------|--------------------|
| `dbt_batch_audit.py` | `data-audit models/*.sql --llm ... --dbt-root .` |
| `dbt_analyse.py` (interactive tmux) | `data-audit --interactive models/stg_orders.sql` (or keep as a separate nvim-specific script that calls the package API) |
| `dbt_deep_analysis.md` | `src/data_audit/prompts/dbt_model_deep.md` |
| `dbt_quick_analysis.md` | `src/data_audit/prompts/dbt_model_quick.md` |
| `render_template()` | `src/data_audit/context/template.py` |
| `compile_model()`, `get_sample_rows()`, etc. | `src/data_audit/context/dbt.py` |
| `run_audit()` | `src/data_audit/orchestrator/executor.py` |
| `synthesize_reports()` | `src/data_audit/orchestrator/synthesizer.py` |
| cursor-agent hardcoding | `src/data_audit/backends/cursor_agent.py` (one of N backends) |

The nvim integration (`nvim/lua/config/dbt.lua`) continues to work — it just
calls `data-audit` instead of the raw Python scripts.

---

## Dependencies

**Required:**

- `click` — CLI framework
- `pyyaml` — YAML parsing (dbt schema files, Quarto front matter)

**Optional (extras):**

- `anthropic` — for the Anthropic backend (`pip install data-audit[anthropic]`)
- `litellm` — for the litellm backend (`pip install data-audit[litellm]`)
- `mdformat` — for markdown formatting of output reports
- `nbformat` — for robust Jupyter notebook parsing (fallback: raw JSON parsing)
- `pyarrow` or `polars` — for Parquet file profiling
- `openpyxl` — for Excel file profiling

---

## Implementation phases

### Phase 1: Extract and package

Move the existing dbt model audit logic into the package structure. Get
`data-audit models/*.sql --llm ... --dbt-root .` working identically to the
current `dbt_batch_audit.py`. Ship the Auditor protocol, the dbt model auditor,
the cursor-agent backend, and the existing prompt templates. No new
capabilities — just packaging.

### Phase 2: LLM backends + structured output

Add the Anthropic and litellm backends. Implement the `Finding` data model and
`parse_findings()` so that results are available as structured data (JSON
output). This unblocks the orchestrator since the PM agent needs machine-readable
findings to reason over.

### Phase 3: Notebook and data file auditors

Implement `NotebookAuditor`, `QuartoAuditor`, and `DataFileAuditor` with their
context gatherers and prompt templates. At this point `data-audit` can audit
any artifact type, but only in a flat batch (no orchestration loop).

### Phase 4: Orchestrator

Implement the PM agent loop: initial plan → audit → review findings → spawn
follow-ups → synthesize. This is the most architecturally complex phase and
benefits from phases 2-3 being stable first.

### Phase 5: Cross-artifact analysis

Teach the orchestrator to reason across artifact types: "this notebook reads
the same table that dbt model X writes to — flag if findings in X affect the
notebook's conclusions." This requires a lightweight project graph (dbt lineage
+ notebook data source detection + file references).

---

## Open questions

1. **Package name**: `data-audit` is clean but generic. Alternatives:
   `llm-data-audit`, `data-artifact-audit`, `dbt-audit-llm`. The scope beyond
   dbt suggests avoiding `dbt-` as a prefix.

2. **Structured finding extraction**: should the LLM be asked to return JSON
   directly (fragile), or should we post-process the markdown response with a
   second LLM call or regex-based parser? A hybrid approach (ask for markdown
   with a machine-readable YAML block at the end) may be most robust.

3. **Database access for data file profiling**: profiling flat files requires
   reading them. For large files, should the tool spin up a temporary DuckDB
   instance to run profiling queries, or rely on pandas/polars sampling? DuckDB
   is likely the right answer since it handles CSV/Parquet/JSON natively and
   the audit prompts already assume SQL-based evidence queries.

4. **Interactive mode**: the current `dbt_analyse.py` launches an interactive
   agent session in tmux. Should the package support this, or should it remain
   a thin wrapper in the dotfiles that calls the package API? Leaning toward
   the latter — interactive UX is editor-specific and doesn't belong in the
   package.

5. **Notebook output handling**: should the auditor include cell outputs
   (which can be large — images, dataframes, tracebacks) in the LLM context?
   Probably: include text outputs and truncated dataframe representations,
   skip images unless the LLM supports vision, always note when outputs are
   missing.
