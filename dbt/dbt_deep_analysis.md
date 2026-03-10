You have access to a duckdb database. You are auditing a dbt model for data quality, correctness, and best practices. Interrogate the database to validate every claim you make — do not speculate without running a query first.

## Audit checklist

Work through each section. For every finding, run a query to confirm it.

### 1. Schema & types
- Are column types appropriate (e.g. dates stored as DATE not VARCHAR, monetary values as DECIMAL not FLOAT)?
- Are there implicit casts in joins or WHERE clauses that could silently drop rows or change values?
- Do any columns contain mixed types or unexpected NULLs?

### 2. Join correctness
- Is every join relationship correct (1:1, 1:N, M:N)? Run a query: does the join **fan out** (produce more rows than the driving table)?
- Are there orphaned rows (LEFT JOIN misses)? What fraction of rows have NULL foreign keys after the join?
- Are join keys unique on the side that should be unique? Query `COUNT(*) vs COUNT(DISTINCT key)`.

### 3. Filters & business logic
- Are there WHERE / HAVING filters that could silently exclude valid records (e.g. filtering on a column that is sometimes NULL)?
- Is there business logic (CASE statements, date arithmetic, aggregations) that could produce wrong results on edge cases?
- Are date boundaries inclusive/exclusive as intended?

### 4. Grain & uniqueness
- What is the intended grain of this model? Verify with `COUNT(*) vs COUNT(DISTINCT <grain_key>)`.
- Could the model produce duplicate rows under any upstream data condition?

### 5. Data quality
- What percentage of each column is NULL? Flag any column where the NULL rate is suspicious.
- Are there unexpected duplicate values, negative numbers, future dates, or empty strings where there shouldn't be?
- Do value distributions look reasonable (run MIN, MAX, AVG, percentiles for numeric columns)?

### 6. Performance & best practices
- Are there SELECT * or unnecessary columns being carried through?
- Could CTEs be simplified or combined?
- Are there window functions that could be replaced with simpler aggregations, or vice versa?
- Is the model incremental where it should be, or full-refresh where incremental would be better?

### 7. Test coverage gaps
{{#if existing_tests}}
The following dbt tests are already defined for this model:
{{existing_tests}}

Identify what is NOT covered by existing tests. Focus recommendations on gaps.
{{/if}}
{{^if existing_tests}}
No dbt tests were found for this model. Recommend the most important tests to add.
{{/if}}

### 8. Upstream dependency risks
{{#if lineage}}
Model lineage (immediate upstream/downstream):
{{lineage}}

Consider: if an upstream model delivers late, delivers duplicates, or changes its grain, how does this model behave? Are there defensive checks?
{{/if}}

## Context

### Compiled SQL
{{compiled_sql}}

### Sample rows
{{sample_rows}}

### Data profile
{{#if data_profile}}
{{data_profile}}
{{/if}}

## Output format

Structure your report as follows:

```
## Executive summary
(2-3 sentences: overall health, most critical finding)

## Critical findings
(Issues that could produce wrong numbers in production)

| # | Finding | Severity | Evidence query | Affected columns |
|---|---------|----------|---------------|-----------------|
| 1 | ...     | ...      | ...           | ...             |

### Finding 1: <title>
**Query:** <the SQL you ran>
**Result:** <what you found>
**Impact:** <what goes wrong downstream>
**Fix:** <specific SQL or config change>

## Warnings
(Issues that aren't wrong today but are fragile)

## Recommendations
(Best-practice improvements, ordered by impact)

## Suggested dbt tests
(Specific test YAML snippets to add)
```
