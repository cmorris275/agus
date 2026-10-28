---
name: expansion-pacing
description: Calculate marketing expansion pace from Expansion attribution actuals and daily goals, using matching accrued dates capped by the snapshot through-date and available data. Use for monthly or quarterly expansion pace by region, supported subregion, or Renewal/Upsell type.
---

# Expansion pacing

Use the [Expansion attribution skill](../expansion-attribution/SKILL.md) and its [expansion_attribution.sql](../expansion-attribution/expansion_attribution.sql) for actuals, and [daily_goals.csv](daily_goals.csv) for goals. Resolve these resources relative to this folder. This workflow is for **marketing expansion only**.

## Sources and actuals

The dedicated expansion-pacing tables have not been created. [expansion_pacing.sql](expansion_pacing.sql) intentionally remains a placeholder; it is not needed to fetch actuals from the existing Expansion attribution source. Do not invent the future tables or substitute the SAO/PG goals source.

Follow the Expansion attribution skill's source and aggregation rules:

- Source: `dwh_analytics.marketing.expansion_marketing_attribution_detail`.
- Population: `campaign_channel IS NOT NULL`. Preserve the Expansion query's population; do not add a sales-segment exclusion from the SAO/PG pacing workflow.
- Actual metric: **`touch_expansion_arr`**, the alias of `touch_allocated_value`. Sum this allocated measure at the validated attribution grain. Its duplicate alias `touch_allocated_value` is the same measure, not an additional component.
- Date: `closedate`, exposed as `invoice_date`. Use calendar dates and the same reporting timezone for snapshot interpretation when timestamps are involved.
- Region: `COALESCE(region_picklist_clean, 'AMER')`, as in the Expansion query. Subregion is `sub_region_clean`; retain the null-region fallback disclosure where relevant.
- Type: map any `final_type` containing `Upsell`, case-insensitively, to **Upsell**. This includes True Up Upsell and Lock In Upsell. Map Renewal to **Renewal**; surface other or missing types rather than silently assigning them.

Do not sum repeated full invoice amounts as the pacing actual or add `touch_ai_expansion_arr` to the selected measure. Retain the Expansion attribution skill's cautions about invoice/touch grain, nulls, negative values, and units. Avoid `SUM(DISTINCT amount)` as a deduplication shortcut.

A daily execution query may aggregate `touch_allocated_value` by invoice date, region, subregion, and mapped type. Aggregate actuals and goals separately to the same reporting grain before comparing them; never join individual attribution touches to repeated daily goals.

## Daily goals and quarter-specific detail

Use `TARGET` as the daily goal amount and `DATE` as its date. Parse amounts without rounding before summing. `DAY_NUM` is the one-based calendar day within the quarter, not a working-day count or a unique date key. The other dimensions are `REGION`, `SUB_REGION`, and `TYPE`.

The current file contains 6,241 rows covering January 1–December 31, 2026. It combines quarters in one file; select the corresponding quarter's rows by `DATE`. Recheck coverage and grain when it is replaced or when separate quarterly target files are supplied. Do not extrapolate targets into quarters absent from the supplied data.

| Quarter in the current file | Available goal detail |
| --- | --- |
| Q1 and Q2 2026 | Daily region totals; `SUB_REGION` and `TYPE` are blank. |
| Q3 2026 | Daily region and Renewal/Upsell goals; APAC also has subregion detail. |
| Q4 2026 | Daily region and Renewal/Upsell goals; APAC and EMEA also have subregion detail. |

Blank goal subregion/type fields mean that the file provides no split at that level. Roll actuals up to the available goal grain; do not match blanks only to blank actuals, repeat regional goals across subregions/types, or allocate unsplit goals without a supplied rule. Region/global totals sum the available detail once. A type-specific pace is unavailable where the quarter has no type-specific goal.

For subregion comparisons, normalize a matching region prefix such as `APAC: ` from actual labels before matching target labels. Check the remaining names explicitly; do not invent mappings or split legacy combined subregions across new target categories. Preserve unmatched actuals in reconciliation and identify unsupported breakdowns. Normalize region case when needed, retaining the supplied display labels such as Japan.

Daily targets include nonzero weekend amounts. **Include all calendar dates in the accrued interval**, using the supplied target schedule. Do not remove weekend goals or substitute the Monday–Friday projection from SAO/PG pacing.

## Accrued-period pacing

For each requested month or quarter, use **the same inclusive date interval for actuals and goals**:

```text
Effective through-date = earliest of:
    snapshot through-date
    available actuals through-date
    available daily targets through-date in the corresponding quarter
    reporting period end

Accrued actuals = sum(touch_expansion_arr from period start through effective through-date)
Accrued goal = sum(TARGET from period start through effective through-date)
Expansion pace = Accrued actuals / Accrued goal
```

Use the first day of the month or quarter as period start. For a completed period with complete actuals and targets, this becomes full-period actuals / full-period goal. For partial periods, both sides stop at the effective through-date. **Do not project actuals to period end or divide them by the full-period goal.** Report pace as a percentage, with 100% meaning the accrued goal has been met.

The snapshot through-date is the date the report represents, not automatically today's date or the file's modification time. Use supplied snapshot metadata when available. If no snapshot date is supplied, derive the latest mutually supported cutoff from actuals and targets and state that basis. A maximum invoice date is evidence of observed activity, not proof that every earlier date is complete; prefer source coverage/refresh information when available. Do not shorten a region's coverage solely because its last transaction occurred before the shared snapshot cutoff if that region's data is otherwise complete.

Cap target availability within the matching quarter and requested population. A later quarter's target file does not establish coverage for an earlier quarter. Check missing days and missing dimension groups inside the interval as well as its endpoints. Do not silently discard unmatched dates, fill unknown goals with zero, or call an interval complete when its beginning is missing. Distinguish a complete actuals feed with no activity on a day from an incomplete feed. If the effective through-date is before period start, pace is unavailable for that period.

For a snapshot through **May 4, 2026**, assuming actuals and targets cover that date:

| Report | Actuals and goals included |
| --- | --- |
| Q2 2026 pace | April 1–May 4, inclusive |
| May 2026 pace | May 1–May 4, inclusive |

If either actuals or the Q2 targets end on May 3, both comparisons end on May 3. The May 4 example is an illustration, not a default reporting date.

Calculate regional/global pace from summed actuals divided by summed goals; do not average daily, regional, monthly, or type percentages. A zero or missing accrued goal produces unavailable pace rather than zero or infinity. Preserve negative actuals and goals and explain their source meaning when material.

## Execution and validation

Reporting dates are optional user inputs. Validate supplied dates and apply appropriate bounds in an execution copy; do not invent a default reporting period.

Use an authorized Snowflake connection for actuals and the supplied CSV for goals. When preparing a comparison across available goals without an explicit period, use the target file's observed coverage to identify comparable periods and disclose that scope. The current file supports 2026 comparisons; actuals outside its coverage have no supplied goals.

Before reporting pace, verify target uniqueness at `(DATE, REGION, SUB_REGION, TYPE)`, actual measure additivity, type/region mappings, date coverage, and matching units. Reconcile independently aggregated actual totals with the Expansion attribution source under the same filters. Confirm that no actual or target after the effective through-date entered either sum.

For extracts, fetch every result row/page, compare fetched counts with result metadata, and split execution into date windows if the connector truncates results. Save raw exports or daily aggregates in the project's `raw_data/` folder with descriptive dates, and retain the query, extraction context, and observed date coverage. Label aggregates as aggregates. Distinct invoice counts within daily groups are not necessarily additive across groups. Read saved CSVs back to verify completeness and values.

Deliver the requested report with accrued actuals, accrued goals, pace, period start, effective through-date, and source context. State any earlier cap imposed by actuals or quarterly targets and any unsupported breakdown. Fresh pulls are required for current results; an earlier exported snapshot must be identified as such.
