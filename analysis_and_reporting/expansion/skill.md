---
name: expansion
description: Extract and analyze marketing-attributed expansion invoice detail using the bundled Snowflake query, including campaign touches, allocated expansion values, AI-credit revenue, account geography, and audience attributes. Use for expansion attribution reporting and exports, not new-business pipeline or MQL cohort reporting.
---

# Expansion attribution

Read [expansion.sql](expansion.sql) before execution. Its source is `dwh_analytics.marketing.expansion_marketing_attribution_detail`. Resolve the SQL relative to this skill folder and output paths relative to the user's project, without hardcoded machine paths.

This first draft documents what the query implements. The underlying allocation model, row uniqueness, and revenue units are not established by the SELECT alone. Verify those details when a requested calculation depends on them; do not invent attribution windows, allocation weights, or annualization rules.

## Reporting scope

The bundled SQL has **no date filter, row limit, or ordering**. Its header still describes a 10-row preview, but the executable query no longer contains `LIMIT 10`. A full extract must fetch every result row/page. Add a limit in an execution copy only for a requested preview and label that output as a preview. Preserve the reusable source unless changing the saved query is part of the task.

Reporting dates are optional and supplied by the user. Use `d.closedate`, exposed as `invoice_date`, when date filtering is requested. With no dates, apply no reporting-date restriction and do not invent or require a period; null invoice dates can remain. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve an omitted year only from clear context and state the assumption. Use only the supplied lower and/or upper bound. For an inclusive calendar-date range, append a validated predicate to the existing channel filter in an execution copy, for example:

```sql
AND CAST(d.closedate AS DATE)
    BETWEEN CAST({{ start_date }} AS DATE) AND CAST({{ end_date }} AS DATE)
```

Check the source datatype and any requested reporting timezone before applying timestamp conversions. Do not substitute campaign association date, response date, MQL date, or pipeline-generation date.

`closemonth`, `day_of_month`, and `year` derive from `closedate`. `day_of_qtr` is one-based within the calendar quarter. The separate `quarter` column comes directly from the source; confirm its convention before treating it as identical to the derived calendar quarter or using it for fiscal pacing.

## Population and row grain

The query includes rows with a non-null `campaign_channel`. It applies no explicit sales-segment, `final_type`, AI-credit, response-date, deletion, or status filter. Do not infer those restrictions from the folder name or transfer campaign-response requirements from other skills. Eligibility and allocation rules may already be implemented upstream and must be checked at their source when needed.

Treat the output as **attribution detail**, not one row per invoice, account, person, or campaign member. Establish the actual source grain before aggregating. A single invoice may be represented by several attributed touches; the same member may appear against multiple invoices. Repeated invoice/member IDs alone do not establish duplicate records.

The output `invoice_id` is constructed as `CONCAT(d.invoice_id, '-', d.actual_amount)`. It is not the unmodified invoice identifier or a proven unique row key. For invoice reconciliation or deduplication, retain the raw source invoice ID alongside the display key in the execution copy and inspect the source grain. An amount-dependent key can change when the amount changes.

## Measures and aggregation

| Output | Meaning and handling |
| --- | --- |
| `total_invoice_amount` | Source `actual_amount`. It may repeat across attribution rows; do not sum it across touches as though each row were a separate invoice. |
| `mktg_touch` | Alias of `campaign_member_id`, not a numeric count or unique invoice-touch key. Count distinct members for member reach; establish the appropriate key for invoice-touch counts. |
| `touch_expansion_arr` | Alias of `touch_allocated_value`. Use the source's allocated measure at its verified attribution grain. |
| `touch_allocated_value` | The same value as `touch_expansion_arr`, included under its original name. Do not add these two columns together. |
| `touch_ai_expansion_arr` | Alias of `touch_allocated_ai_credit_revenue`. Confirm whether it overlaps with `touch_allocated_value` before combining them. |
| `director_plus_mktg_touch`, `vp_plus_mktg_touch` | Source-provided seniority-touch fields. Check their datatypes and upstream definitions before treating them as IDs, flags, or counts. |
| `ai_credit_invoice` | Source-provided AI-credit classification. Inspect its values and definition before filtering or interpreting it as a Boolean. |

For marketing contribution, prefer the relevant touch-allocated measure over repeating the full invoice amount for every campaign. Sum only after confirming row uniqueness and measure additivity. Never use `SUM(DISTINCT amount)` to remove repeated invoice values: separate invoices can share the same amount.

The aliases containing `arr` do not prove annual recurring revenue units, particularly for AI-credit revenue. Confirm currency, annualization, and inclusion rules before labeling totals as ARR, recognized revenue, or a combined expansion measure. Preserve nulls, zeros, and negative amounts rather than interpreting or excluding them without source context.

Allocation totals need not equal full invoice amounts in this extract: the channel filter may exclude other attribution rows, and the upstream model may allocate only a portion. Reconcile against documented allocation rules and the same population, not an assumed 100% allocation.

## Classification and enrichment

- Null `region_picklist_clean` is labeled AMER. This is a reporting fallback, not verified geography. `sub_region_clean` and `billing_country` pass through unchanged.
- `prod_eng` is `prod_eng` when the source `function` contains `prod`, `eng`, or `dev`, case-insensitively; otherwise it is null. This is a substring classification, not a validated job-function taxonomy.
- Campaign name/channel/type/theme/product, ABM classification, job title/seniority, sales segment, and `final_type` pass through from the source. Do not infer their allowed values or historical snapshot timing from this query.
- Account and campaign links are supplied reference fields. Preserve them in exports; their presence does not establish attribution causality.

## Execute, validate, and deliver

Use an available authorized Snowflake connection and honor an explicitly requested platform. Apply only supplied valid dates and requested campaign/account/segment filters to the execution copy with supported bindings or safely rendered values. Do not claim a query was run when only the SQL was prepared.

For a requested CSV, use `raw_data/expansion_YYYY-MM-DD_to_YYYY-MM-DD.csv` for a supplied range, `raw_data/expansion_all_dates.csv` without date bounds, or a `from_YYYY-MM-DD`/`through_YYYY-MM-DD` suffix for one-sided bounds. Use a descriptive scope suffix when useful and label previews as previews. Fetch every result page, preserve columns, identifiers, numeric precision, and source text, and use UTF-8 with standard CSV quoting and empty fields for nulls. Avoid overwriting a different extract without a refresh request.

Before reporting totals, verify that the execution copy is not limited to a preview, any supplied date bounds and the channel filter match the request, and the fetched row count matches result metadata. Without date bounds, report observed coverage and null invoice dates. Check source grain and reconcile allocated totals against a source aggregation using identical filters. Compare distinct raw invoices, accounts, and members when relevant rather than calling all rows “invoices.” Read the saved CSV back to verify that its values and dimensions match the fetched data.

Return a header-only CSV for a successful empty result. If access or source definitions prevent a requested calculation, state the specific limitation and complete the parts that are supported.

For interpretation, distinguish invoice volume, full invoice amounts, touch-allocated expansion, and AI-credit allocation. Explain material differences in population or time basis before comparing this report with campaign, MQL, SAO/PG, or goal reports. Deliver the requested file or findings with the applied date scope (or all dates), filters, extraction context, and any unresolved definition that affects the conclusion.
