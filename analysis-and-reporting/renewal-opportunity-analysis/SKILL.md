---
name: renewal-opportunity-analysis
description: Provide supporting Salesforce renewal opportunity context for Expansion Attribution using the bundled Snowflake query. Use for remaining renewals this quarter, closed opportunity outcomes, next-quarter opportunities, and relative deal magnitude. Do not use to measure or estimate Expansion Revenue, marketing-attributed or otherwise.
---

# Renewal opportunity analysis

This standalone skill supports the broader [Expansion Attribution skill](../expansion-attribution/SKILL.md). Expansion Attribution performs attribution at invoice time with a 90-day lookback window, as specified by the user. This workflow examines raw Salesforce renewal opportunities, primarily to monitor what is expected to close in the future and secondarily to evaluate closed outcomes and the relative magnitude of deals flowing through the system. Renewals are a substantial component of expansion, not all expansion.

Salesforce opportunity data is available before close. Use it only as supporting opportunity information for Expansion Attribution. It must never substitute for, measure, or estimate Expansion Revenue of any kind, including marketing-attributed and total Expansion Revenue. Answer revenue questions using the appropriate invoice-based revenue or attribution source; this query cannot fill a gap in those results. Do not apply the invoice attribution lookback window to this opportunity query.

## Source and definitions

Read [renewal-opportunity-analysis.sql](renewal-opportunity-analysis.sql) before execution. The user-supplied query reads `dwh_cleaned.salesforce.cleaned_salesforce_opportunity` and left joins `dwh_cleaned.salesforce.cleaned_salesforce_account` on `o.accountid = a.id`. Resolve the query relative to this skill folder and outputs relative to the user's project.

The saved population requires:

- `o.type = 'Renewal'`.
- `o.forecastcategory != 'Omitted'`.
- A non-null `o.accountbookid__c`.
- `o.opportunityownerrole__c != 'Ops'`.
- A positive grouped `SUM(o.payoutrevenueusd__c)`.

The two inequality predicates also exclude null values under SQL null semantics. The query has no explicit deletion filter. Its open-only predicate is commented out, so it includes both open and closed records that satisfy the other filters, without a separate won/lost restriction. Preserve this behavior unless the user requests a different population.

`net_arr` is the sum of `payoutrevenueusd__c`, not the full opportunity Amount. Per the user's business definition, it generally represents the amount on which invoice attribution will eventually be performed. It is a Salesforce value and is not expected to match its invoice counterpart. Use it to compare relative deal magnitude, inspect expected opportunity closes, and evaluate closed opportunity outcomes. Label it Salesforce opportunity net ARR. It is supporting deal context, not Expansion Revenue or a revenue forecast, including for closed-won opportunities. An exact invoice tie-out is not an acceptance criterion. Preserve this measure without adding probability weighting or an invented expansion formula. No campaign joins, marketing eligibility, or touch allocation are implemented in this query.

The output contains `closedate`, account ID/name, `region`, `sub_region`, opportunity ID/name, `net_arr`, stage, `is_closed`, and `iswon`. `region` maps account `regionpicklist__c = 'NA'` to `AMER` and otherwise preserves the source value, including null. `sub_region` passes through account `subregionpicklist__c` unchanged. These are account geography fields, not opportunity geography or historical snapshots. Use them for requested regional breakdowns, retaining missing geography as unknown rather than assigning it to AMER. The query has no segment or forecast category output. A failed account join leaves account fields null; do not treat that as proof the source opportunity has no account.

## Scope and time basis

The saved query uses `{start_date}` and `{end_date}` placeholders for an inclusive `o.closedate` range. Resolve dates from the user's request or clear conversation context and state the bounds; ask for a period if none can be established. The supplied example covers October 1 through December 31, 2026, rather than defining a permanent default. Replace placeholders in an execution copy using supported bindings or safely rendered date literals; do not execute unresolved placeholders. Validate supplied dates and use only the requested bounds; remove the date restriction only for an explicitly requested all-dates extract.

Use opportunity `closedate` as the reporting date, not invoice date or opportunity creation date. For open opportunities it represents the expected close date; preserve the distinction from closed outcomes. The range predicate excludes null close dates. Check the source datatype and reporting timezone if timestamp boundary behavior matters. Do not restrict results to already closed opportunities merely because Expansion Attribution uses invoice dates.

Keep open and closed opportunity amounts distinct from invoice-based revenue and attribution results. A won opportunity does not establish invoiced Expansion Revenue. Report the extraction time and source refresh time when available. Current Salesforce values do not reconstruct a historical pipeline snapshot; a historical as-of request requires snapshot or history data.

`is_closed` (source `o.isclosed`) is the primary open/closed indicator. Close dates commonly slip or pass while opportunities remain open. Never infer closure from a past close date or use stage text in preference to `is_closed`. An open opportunity with a past close date remains open and belongs in the requested close-date period, with a past-due flag when useful.

Use `iswon` to distinguish won from lost among closed opportunities. An open opportunity with `iswon = FALSE` is not a loss. Null or inconsistent status flags should be reported as unknown or needing investigation rather than silently classified.

## Common marketer questions

Resolve relative periods such as “this quarter” and “next quarter” from the current date and the established reporting calendar, and state the exact bounds. Use those bounds for the execution-copy date parameters. Clarify the quarter convention if fiscal versus calendar timing is unresolved and changes the answer.

| Question | Execution-copy scope and interpretation |
| --- | --- |
| What are the remaining opportunities this quarter? | Filter `closedate` to the full quarter and `o.isclosed = FALSE`. Include open opportunities with close dates earlier in the quarter, even if those dates have passed. Do not add a today-or-later lower bound unless requested. |
| What has closed this quarter? | Filter `closedate` to the quarter and `o.isclosed = TRUE`. Show won and lost separately using `o.iswon`; “closed” does not mean only won. |
| What was won or lost? | Use `o.isclosed = TRUE` with `o.iswon = TRUE` for won or `FALSE` for lost, within the requested close-date period. |
| What about next quarter? | Filter `closedate` to next quarter. In an expected/remaining pipeline conversation, use open opportunities; for an unqualified overview, retain both statuses and show the open/closed split. State which population is shown. |

Preserve the other source filters, including positive grouped net ARR. Closed/lost results therefore describe only the eligible positive-net-ARR population, not all renewal losses or contraction. Change that scope only when requested. A retrospective close-date view uses current Salesforce values; it does not reconstruct an earlier pipeline snapshot.

## Query and validation

Use an authorized Snowflake connection for the bundled SQL and honor an explicitly requested platform. Apply requested filters in an execution copy with supported bindings or safely rendered values. The query has no row limit and sorts by the named `net_arr` output descending. Use the column name rather than a positional sort so adding output columns does not change the ordering. Fetch all pages for a full extract; label any limited result as a preview. Do not claim execution when only SQL was prepared.

`GROUP BY ALL` groups by all ten non-aggregate outputs, including region and sub-region, not only opportunity ID. Verify source opportunity ID uniqueness and account ID uniqueness before treating the output as one row per opportunity: duplicate source rows or account join fanout can inflate the sum, and differing attributes can produce several rows per opportunity. Preserve legitimate detail rows and do not use distinct monetary amounts to deduplicate. If adding campaign touches, line items, or history, prevent repeated opportunity amounts from being summed across those details.

Check opportunity counts, stage coverage, date boundaries, source null amounts, and join fanout. `SUM` ignores null amounts; groups with null, zero, or negative totals fail the saved `HAVING` predicate, although a positive group may contain negative source rows. Reconcile totals against the same filtered source and grouped-positive population. Do not describe this extract as all renewals or use it to quantify contraction without changing the positive-only scope explicitly.

## Output and relationship to Expansion Attribution

Provide the requested findings or extract with applied filters, date basis, extraction context, measure definition, and unresolved limitations. For CSV exports, use a descriptive filename under the user's project `raw-data/` directory, preserve identifiers and numeric precision, and verify the saved file against fetched results.

Label results as supporting Salesforce renewal opportunity information for Expansion Attribution. For marketer summaries, report opportunity counts and Salesforce opportunity net ARR magnitude for the requested period, splitting open, closed-won, and closed-lost when relevant; identify material past-due open opportunities. State that these amounts are opportunity context only and do not represent Expansion Revenue. Do not present them as a revenue proxy, substitute, forecast, revenue actuals, or revenue pacing input.

When providing context alongside invoice-based Expansion Attribution, explain the opportunity close-date versus invoice-date basis, the invoice-time 90-day attribution lookback, and the difference between raw opportunity value and touch-allocated invoice value. Verify any opportunity-to-invoice mapping before linking records. Never add Salesforce opportunity amounts to Expansion Revenue totals or substitute them for missing invoice-based values, even if record overlap can be resolved.

Keep the implementation in a separate skill while limiting its business use to supporting Expansion Attribution. Supporting opportunity questions can be answered without executing the full invoice attribution workflow, but their outputs remain opportunity context only.
