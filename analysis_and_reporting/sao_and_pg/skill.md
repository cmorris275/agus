---
name: sao-and-pg
description: Extract and analyze opportunities by pipeline-generation date using the bundled Snowflake query, including SAO counts, payout-based pipeline, attributed MQL classifications, employee bands, and account segment. Use for pipeline-period and opportunity-detail reporting, not campaign-member or MQL cohort reporting.
---

# SAOs and pipeline generation

Read [sao_and_pg.sql](sao_and_pg.sql) before execution. Resolve it relative to this folder and use the fields and attribution rules implemented in that query. SAO means sales-accepted opportunity; PG means pipeline generation. The reporting date is pipeline-generation date; the SELECT imposes no separate stage/status flag.

## Population and time basis

Reporting dates are optional and supplied by the user. Apply valid bounds to `os.pipeline_generation_date` from `fig2_sf_sales_opportunity_source` in an execution copy. Use only supplied bounds; with no dates, apply no reporting-date restriction and do not invent or require a period. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve an omitted year only from clear context and state the assumption. For inclusive calendar dates, check the datatype and requested timezone and compare dates explicitly when the source is a timestamp. Do not substitute opportunity creation, closed-won, MQL, or campaign-member association date.

The saved SELECT contains a `BETWEEN {{ start_date }} AND {{ end_date }}` date predicate. Render it for a valid supplied range, replace it for one-sided bounds, or remove it when dates are absent. It has no separate `pipeline_generation_date IS NOT NULL` restriction; removing the range can therefore retain undated opportunities. For SAO/PG analysis, distinguish pipeline-generating opportunities from undated records instead of automatically calling every unbounded result row an SAO.

The saved query restricts sales segments to SMB, Mid-Market, and Enterprise within its `WHERE` clause. Preserve this commercial-segment scope unless the user requests a different scope. When removing optional date predicates, retain the segment condition as the remaining `WHERE` condition.

There is no marketing-source, MQL-ID, campaign-member-ID, valid-response, or opportunity-deletion requirement. All attribution sources are eligible within the applied segment scope. Report that scope explicitly.

The expected grain is one row per `opp_id`, assuming unique opportunity-source and account IDs. All opportunity-source fields are returned through `os.*`, followed by calendar, classification, and account fields. The schema can therefore expand when the source changes.

## Measures and aggregations

| Measure | Definition |
| --- | --- |
| SAOs in this extract | Distinct `opp_id` with a non-null pipeline-generation date, within any supplied date bounds and the applied segment scope. Report undated opportunities separately in unbounded extracts. Do not silently substitute `is_stage1_sao`, `is_stage2_sao`, or stage dates. |
| PG | Sum of `payout_revenue` once per opportunity in that same SAO population. Do not substitute `amount`, ARR components, or recognized revenue. |
| Won SAOs, if requested | Distinct cohort opportunities with `is_won = TRUE` at extraction. |
| Won pipeline, if requested | Sum of `payout_revenue` for those won cohort opportunities. This is not a closed-won-date-period report. |

Verify one row per opportunity before summing. If joins create duplicates, investigate and reconcile values rather than choosing arbitrary records or using `SUM(DISTINCT payout_revenue)`. Preserve null versus zero. Confirm the payout field's currency/unit before adding a currency label or converting it; the query itself does not perform currency conversion.

Current source attributes and won status reflect extraction time. Selecting an earlier pipeline-generation period does not recreate the pipeline or won status as of that historical end date. Keep this distinction in period comparisons.

## Derived classifications

`attributed_mql_type_mod` applies the following precedence:

1. Scored when `mql_type = 'Scored'`.
2. OWF Product when attributed campaign name matches the product pattern.
3. OWF Website when it matches the website pattern without the credit-purchase pattern.
4. OWF Website AI Credits when both website and credit-purchase patterns match.
5. `RH - Ex-OWF` otherwise.

Unlike the MQL and campaign-member queries, the OWF branches do **not** additionally require `mql_type = 'Raised Hand'`. Null or nonmarketing records can reach the default label. Treat these as implemented reporting labels, not proof that every record is Raised Hand or marketing-sourced. Preserve SQL `ILIKE` pattern semantics, including underscore wildcards, unless a taxonomy change is requested.

Calendar fields derive from pipeline-generation date. `year` is text. `day_number` is the day of the year. Week numbering follows the Snowflake session's week settings; establish a consistent convention for weekly comparisons.

Employee count and `figma_segment` come from the current cleaned Salesforce account joined on `os.account_id = a.id`. This enrichment is not a historical account snapshot and is distinct from opportunity `sales_segment`. Employee bands run from 1–10 through 5,000+; zero and null are Unknown, while other unmatched values remain null. Preserve the exact bands and labels in the SQL.

## Execute and export

Use an authorized Snowflake connection, honoring an explicitly requested platform. Prepare only supplied date bounds as described above, using validated SQL date values or supported bindings. Remove unused placeholders and dangling SQL syntax. Apply request-specific source, region, segment, campaign, or opportunity filters in the execution copy; keep the template reusable.

For a requested CSV, use `raw_data/sao_and_pg_YYYY-MM-DD_to_YYYY-MM-DD.csv` for a supplied range, `raw_data/sao_and_pg_all_dates.csv` without date bounds, or a `from_YYYY-MM-DD`/`through_YYYY-MM-DD` suffix for one-sided bounds. Add a scope suffix when needed. Export all rows/pages and columns with stable opportunity ordering, UTF-8 CSV quoting, ISO dates, unchanged IDs/decimal precision, and empty fields for nulls. Do not overwrite a different extract without a refresh request. Keep metadata and analysis outside the raw CSV.

## Validation and interpretation

Check result completeness, any supplied pipeline-date bounds, null pipeline dates in unbounded extracts, distinct opportunity IDs, and uniqueness of the account join. Reconcile opportunity counts and payout totals to an independent opportunity-source aggregation with the same date/source/segment filters. For changed classifications, inspect scored, product, website, credit-purchase, null, and fallback cases. Read exported CSV back to verify the values and dimensions match the fetched result.

Return a header-only CSV when a successful query has no matches. If execution is unavailable, state the access limitation and do not invent results.

When analysis is requested, explain whether comparisons reflect opportunity volume, payout per opportunity, source/segment mix, or current won status. Distinguish pipeline generated during a period from pipeline attributed to members or MQLs acquired during that period. Label all population restrictions and avoid ROI or causal claims unsupported by cost or experimental data. Deliver the requested file or findings with the applied date scope (or all dates), filters, extraction context, and material source limitations.
