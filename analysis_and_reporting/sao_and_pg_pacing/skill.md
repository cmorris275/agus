---
name: sao-and-pg-pacing
description: Calculate monthly or quarterly pace for MQL, SAO, PG, and derived ASP, grouped first by attributed source (Marketing versus Sales). Project MQL, SAO, and PG for partial periods using working days; ASP pace always compares actual ASP with goal ASP. Support region or segment breakdowns.
---

# SAO and PG pacing

Read [sao_and_pg_pacing.sql](sao_and_pg_pacing.sql) before execution. Resolve the query relative to this folder and output paths relative to the user's project. The source is `DWH_ANALYTICS.MARKETING.GOALS_ACTUALS_COMBINED`. The pacing and ASP definitions below are the user's business rules. Inspect the source for goal/actual labels, upstream metric definitions, and refresh timing.

## Reporting scope

The saved query has **no date filter**. It excludes `sales_segment = 'Other'` and includes only `metric_name` values `MQL`, `SAO`, and `PG`. All available monthly periods, including earlier years and future goal months, can be present. Do not describe it as a 2026-only, since-2026, or year-to-date extract without applying user-supplied bounds.

Reporting dates are optional. Add only valid user-supplied lower and/or upper bounds on `by_month` in an execution copy. Without dates, leave the reporting period unrestricted rather than inventing or requiring a period. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve an omitted year only from clear context and state the assumption. Null month keys can remain in the unbounded extract; surface them separately from dated performance.

The `NOT IN ('Other')` predicate also excludes null sales segments. Other segment values, all attributed sources, and all regions remain eligible. Preserve these filters unless a different scope is requested. Apply request-specific dates and dimension filters in an execution copy; keep the reusable query intact unless editing it is part of the task.

Use `by_month` as the reporting period. Verify its datatype, whether it is a month-start key, and its calendar or fiscal convention before filtering partial months or grouping quarters. For a bounded monthly report, an inclusive start-month and exclusive next-month boundary is useful once the month-key convention is confirmed. If supplied dates cover only part of a month, make the whole-month bucket interpretation explicit; this source cannot produce daily actuals merely by filtering its month key. Do not substitute MQL date or pipeline-generation date from other reports for this source's period definition.

## Fields and grain

| Field | Use |
| --- | --- |
| `attributed_source` | Highest-level reporting dimension: Marketing versus Sales. Calculate each source separately; inspect unexpected or missing labels before mapping them. |
| `by_month` | Monthly reporting period, subject to source convention. |
| `sales_region`, `sales_segment` | Reporting dimensions; preserve unknown values and distinguish source totals from detail categories. |
| `metric_type` | Identifies the kind of measure, such as a goal or actual. Inspect distinct values and confirm their definitions before assigning roles. |
| `metric_name` | MQL, SAO, or PG. Analyze each separately. |
| `metric_value` | Numeric value for the given metric and type; confirm datatype, units, and additivity. |

The candidate key is `(attributed_source, by_month, sales_region, sales_segment, metric_type, metric_name)`. The query performs no aggregation or deduplication. Check whether that key is unique and whether the source contains totals, overlapping categories, multiple versions, or additional grain not exposed in the SELECT. Investigate repeated keys before summing them; neither arbitrary row selection nor `SUM(DISTINCT metric_value)` establishes a valid total.

MQL conventionally means marketing-qualified lead, SAO sales-accepted opportunity, and PG pipeline generation. Their exact eligibility, attribution, date basis, and PG revenue measure must come from this source's definitions. Do not assume they match the separate detail SQL files, or label PG as a particular currency, ARR, or payout revenue without confirmation.

## Comparing goals and actuals

Default to one result per attributed source (Marketing or Sales), metric, and requested month or quarter. Aggregate across the included sales regions and segments before calculating ratios. Add region or segment breakdowns when requested, retaining the source grouping. Do not combine Marketing and Sales into a single pace figure by default or invent a missing source/metric combination.

Inspect `metric_type` values and identify the applicable goal and actual series. If there are multiple goal versions, forecasts, or scenarios, establish which one the request uses rather than combining them.

Align goals and actuals on the same month, metric, source, region, and segment. Retain unmatched combinations so missing goals or actuals remain visible. A missing row or null value is unknown, not automatically zero. If goals are stored at a coarser grain than actuals, aggregate actuals to that grain; do not repeat a shared goal across detail rows or allocate it without a defined rule.

After validating additivity, sum values over the requested dimensions and calculate:

- **Attainment:** actuals accrued / goal, expressed as a percentage. This is also pace for a completed period; partial-period pace uses projected full-period actuals as described below.
- **Gap to goal:** goal - actual; a positive value is a shortfall and a negative value is above goal.
- **Remaining to goal:** `max(goal - actual, 0)` when the user asks how much is still needed.

For rolled-up attainment or pace, aggregate actuals and goals at the requested reporting level before calculating the ratio; do not average percentages. Keep MQL, SAO, and PG separate; do not add lead counts, opportunity counts, and pipeline amounts together. Zero, missing, or negative goals require explicit interpretation; do not report an ordinary attainment or pace percentage for them.

## Monthly and quarterly pace

The base definition is **Pace = Actuals / Goal**, expressed as a percentage. Apply it separately to **MQL, SAO, and PG (pipeline generation)** for each attributed source and reporting period.

For a **completed month or quarter**, use the full period's actuals divided by its full goal directly. No working-day projection or working-day counts are needed. Pace and final attainment are the same.

For a **partial period**, such as the current month or current quarter, first project accrued actuals to the full period using working days, then divide by the full period goal:

```text
Projected period actual = (Actuals accrued / Working days accrued) × Total working days in period
Partial-period pace = Projected period actual / Period goal
```

For completed periods, 100% means actuals met goal; for partial periods, 100% means projected actuals meet goal. Above/below 100% indicates above/below goal on the applicable basis. If showing both partial-period attainment and pace, label attainment as accrued actuals / goal and pace as projected full-period actuals / goal. Do not apply the working-day projection to every period by default.

- **Partial month:** use actuals accrued from the start of the month through the actuals cutoff, working days accrued over that same interval, total working days in the full month, and the full monthly goal.
- **Partial quarter:** sum accrued actuals across the quarter's months and sum goals for the full quarter, including future months within that quarter. Use working days accrued since the quarter started and total working days in the full quarter. Do not average monthly pace percentages or sum monthly projections to produce quarterly pace. For a completed quarter, simply divide total actuals across its months by total quarterly goal.

For partial-period projections, **working days mean Monday–Friday only**, as confirmed by the user; do not exclude company or regional holidays. Count elapsed weekdays through the actuals cutoff and total weekdays in the full period, using the same cutoff for actuals and elapsed days. Do not substitute calendar days or count a partially observed day as complete without making that assumption explicit. Confirm the calendar/fiscal quarter convention before grouping months. The bundled SELECT supplies monthly metric values, not working-day counts or an actuals-through timestamp, so establish the actuals cutoff from source data or reporting context. Do not assume extraction time equals the cutoff or invent accrued actuals from a complete-month or forecast value.

For partial periods, working days accrued must be positive and no greater than total working days in the period. With zero accrued working days or an unknown actuals cutoff, the projection is unavailable; report supported actuals and attainment instead. Zero/missing goals prevent a pace ratio for any period, and negative goals require interpretation. Future periods with no accrued actuals have goals but no pace. Do not require working-day inputs to calculate completed-period pace.

## ASP (average selling price)

ASP is derived from the query's PG and SAO rows; it is not a separate `metric_name` returned by the SQL. **ASP pace is always actual ASP divided by goal ASP**, for both completed and partial periods:

```text
Actual ASP = PG actuals accrued / SAO actuals accrued
Goal ASP = PG period goal / SAO period goal
ASP pace = Actual ASP / Goal ASP
```

Calculate both ASP values for the same attributed source, month or quarter, and filters, with a common actuals cutoff for PG and SAOs. Sum PG and SAOs to the reporting level before dividing; do not average regional, segment, or monthly ASPs. If actual SAOs are zero or missing, actual ASP is unavailable; if goal SAOs are zero or missing, goal ASP is unavailable. A zero or missing goal ASP prevents an ASP pace ratio. Treat negative inputs as requiring interpretation. Display ASP in PG units per SAO and ASP pace as a percentage.

PG and SAO inputs follow the completed-versus-partial-period rules above. For a partial period, both receive the same projection factor `f = total working days / working days accrued`. Their ratio is unchanged: `(PG actuals × f) / (SAO actuals × f) = PG actuals / SAO actuals`. Therefore ASP pace always uses actual ASP / goal ASP, with **no additional working-day adjustment to ASP or its pace**. This cancellation requires matching scope and cutoff; do not mix independently timed or scoped PG and SAO inputs. The saved SQL already provides the PG and SAO inputs, so deriving ASP and its pace does not require adding ASP to the SQL metric filter.

## Execute, validate, and deliver

Use an authorized Snowflake connection, honoring an explicitly requested platform. Validate or bind request-specific filters. For CSV requests, use `raw_data/sao_and_pg_pacing_YYYY-MM_to_YYYY-MM.csv` for a bounded monthly scope, or `raw_data/sao_and_pg_pacing_all_dates.csv` without date bounds. Use `from_YYYY-MM`/`through_YYYY-MM` suffixes for one-sided monthly bounds. Add a scope suffix when needed and avoid overwriting a different extract without a refresh request.

Export all result rows and the seven selected columns using UTF-8 CSV quoting, ISO dates, preserved numeric precision, and empty fields for SQL nulls. Use stable ordering by the reporting dimensions. Keep calculated summaries outside the raw extract unless the requested deliverable calls for them.

Validate any supplied date bounds and the segment filter, observed month coverage and null month keys, metric/type values, candidate-key uniqueness, missing goal/actual pairs, and result completeness. Reconcile Marketing and Sales totals separately to the source with identical filters. Identify each reporting period as completed, partial, or future before choosing the calculation. For quarterly pace, confirm all quarter goal months are included. Use full-period actuals directly for completed periods; for partial periods, check Monday–Friday counts against the actuals cutoff before projecting accrued actuals. Calculate ASP from aggregated PG and SAOs without projecting it. Read the CSV back to verify dimensions and values. A successful empty query produces a header-only export; unavailable execution must not be presented as a fresh result.

Deliver the requested file or analysis grouped first by Marketing versus Sales, with the applied date scope (or all dates), filters, goal/actual mapping, extraction context, and actuals cutoff. Identify MQL, SAO, and PG pace as actual-based for completed periods or projected for partial periods, including working-day counts only when a projection is used. ASP pace always compares actual ASP with goal ASP directly. Label attainment, gap, pace, and ASP values clearly. Explain material population or time-basis differences before reconciling this report with MQL, SAO/PG, campaign, or Weave extracts.
