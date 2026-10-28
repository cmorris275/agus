---
name: mql-analysis
description: Extract and analyze MQL cohorts using the bundled Snowflake query, including OWF classifications, pickup and touch timing, inbound email and meeting/call activity, NBMs, ownership, and linked opportunities. Use for MQL-date reporting and follow-up analysis, not campaign-association or pipeline-generation-date reports.
---

# MQL analysis

Read [mql-analysis.sql](mql-analysis.sql) before execution. Resolve it relative to this folder. Use its implemented rules as the starting point, distinguishing business definitions from classifications inferred from campaign names or activity metadata.

## Cohort, dates, and row grain

Use `dwh_analytics.marketing.fig2_dim_mql` as the base source. Reporting dates are optional and supplied by the user. The saved query has no final MQL-date filter. For valid supplied bounds, add a predicate on `dim.mql_date` before the final `GROUP BY ALL` in an execution copy. Use only the supplied lower and/or upper bound; with no dates, leave the MQL cohort unrestricted rather than inventing or requiring a period. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve omitted years only from clear context and state the assumption. Check the date datatype and any requested timezone; for inclusive calendar-day bounds on timestamps, compare calendar dates explicitly. Do not substitute campaign association or pipeline-generation date.

The `responses`, `meetings`, and `calls` CTEs still contain `activitydate >= {{ start_date }}` even though the final MQL cohort no longer has a date filter. These predicates restrict activity, not MQL selection, and can suppress flags for older MQLs if left in place by themselves. Retain/render them only when a matching lower MQL-date bound is supplied and they preserve the full activity windows. With no lower bound, remove these predicates from the execution copy, preserving email/call eligibility conditions and valid `WHERE`/`AND` syntax. Do not invent a start date to satisfy the placeholders. Do not cap activity at the supplied cohort end date: preserve the per-MQL 0–28-day matching windows and the independent ±30-day NBM windows.

The query returns all MQL-source columns plus derived fields, contact/account enrichment, the prior-day account snapshot, and pipeline-generating opportunities linked by `mql_id`. The base MQL population has no sales-segment filter, but the opportunity CTE actively restricts linked opportunities to SMB, Mid-Market, and Enterprise and requires a non-null pipeline-generation date. This is a left join, so MQLs without a qualifying opportunity remain. A campaign response is not required.

The final `GROUP BY ALL` groups identical projected rows; it is not an aggregation to one row per MQL or opportunity. Different opportunity fields still yield multiple rows for one MQL. Do not rely on this clause to make payout sums or MQL-level averages safe.

An MQL can repeat for multiple linked opportunities. Count distinct MQL IDs, not rows, and evaluate MQL-level flags once per MQL when calculating rates or averages. Sum opportunity payouts once per `opp_id` after checking the joins' uniqueness. Do not use `SUM(DISTINCT payout_revenue)` as a deduplication shortcut. Snapshot rows should be unique by account ID and snapshot date; verify this if joins unexpectedly multiply records.

Opportunity outcome dates can be outside the MQL cohort range. Activity windows also extend past the end date. Recent MQLs have less observed follow-up time, and current won status is not a snapshot as of the report end. Account/contact attributes are current except for the explicit prior-day snapshot fields.

## MQL classifications

| Output | Current rule |
| --- | --- |
| `owf_source` | Product or Website when the campaign name matches the corresponding orgs-web-form pattern; otherwise Other. Independent of MQL type. |
| `mql_type_mod` | Scored first; then Raised Hand split into OWF Product, OWF Website, and OWF Website AI Credits; otherwise `RH - Ex-OWF`. |
| `mql_type_simple` | OWF versus EX-OWF from the broad campaign-name pattern. |
| `automation` | Automation when `is_outreach_automation = TRUE`; otherwise No Automation, including null values. |

Preserve the campaign-name pattern precedence. The fallback `RH - Ex-OWF` can include null or unexpected types; it does not establish Raised Hand intent. SQL underscores in `ILIKE` patterns are single-character wildcards. Do not replace these labels with a claimed authoritative taxonomy without validating the underlying field values.

Calendar fields use `mql_date`. `mql_week` shifts the week boundary with `DATEADD`/`DATE_TRUNC`; its meaning and `week_number` depend on Snowflake week settings. Establish the intended convention before comparing weekly results across sessions. Do not assume ISO or fiscal periods from these fields.

## Follow-up, pickup, and touch

Activity is matched by `whoid = person_id`. The window is MQL date through MQL date plus 28 days, inclusive of day 0 and day 28. It is not capped at the selected end date. The same activity can match multiple MQLs for a person when their windows overlap; these are activity-association indicators, not exclusive attribution.

| Field | Meaning |
| --- | --- |
| `response` | 1 if a non-deleted Salesforce task has type Email and its subject's third leading bracketed token is exactly `In` within the activity window; otherwise 0. This is an inbound-email indicator, **not** a valid campaign response. |
| `meeting` | 1 if any Salesforce event or a qualifying call task matches within the window; otherwise 0. This includes calls and is broader than an NBM. |
| `pickup` | MQL ID when touch hours are 0–24 for Scored or 0–4 for Raised Hand, inclusive. Otherwise null. |
| `pickup_touch_hrs` | The touch hours for the same pickup-eligible MQLs. |
| `touch` | MQL ID when touch hours are nonnegative. Otherwise null. This does not additionally test `mql_valid_touch_flag`. |

The general event CTE currently imposes no event-type, deletion, completion, or cancellation filter. A call task has a type matching `%call%` and at least one of: non-null description, non-null recording, positive duration, disposition matching `%answered%`, or inbound call type. Calls are not filtered by deletion or completion. An empty description can qualify because the test is non-null, and `%answered%` can match wording such as “unanswered.” Preserve these rules unless asked to refine them; do not label the combined indicator “held meetings” or “confirmed conversations.”

The inbound-email regex assumes a specific subject format and case-sensitive `In`. Missing, redacted, or differently formatted subjects will not match. Investigate zero email matches before concluding that no replies occurred. Preserve SQL string escaping when editing this expression; [Snowflake documents the required backslash escaping](https://docs.snowflake.com/en/sql-reference/functions-regexp).

## MQL NBMs

NBM means **New Business Meeting**, sourced from non-deleted Salesforce events with type `AE - New Business Meeting` and a matching account. Use event `whoid` to match the MQL's person and event `enddate` within **±30 days of MQL date**, inclusive. A matching MQL returns its `mql_id` in `nbm`; count distinct IDs, not events.

This query's NBM measure does **not** require a valid campaign response. That differs intentionally from campaign-member/summary NBM credit, whose window is anchored to first response and requires that date. Do not transfer the campaign-response requirement to this MQL measure without an explicit definition change.

The event CTE deduplicates the account/person/related-record/end-date meeting key. Completed, non-canceled, and non-no-show statuses are preferences when selecting duplicates, not eligibility filters. Meetings before MQL date qualify, and one meeting can match several MQLs. Keep the MQL NBM measure distinct from the 28-day `meeting` activity flag.

## Enrichment and outcomes

- Contact seniority supplies job seniority and MQL-ID markers for Director+ and VP+. Lead-only/unmatched people receive no contact seniority classification. These markers do not depend on a logged sales touch.
- Current employee count and segment join through the contact's `accountid`. The ownership snapshot instead joins through `dim.account_id` on the day before MQL date; these account paths may differ.
- Employee bands are 1–10, 11–25, 26–50, 51–100, 101–250, 251–500, 501–1,000, 1,001–5,000, and 5,000+. Zero/null become Unknown; other unmatched values remain null.
- `mql_ownership` is Unowned for snapshot roles Ops, Marketing, or null, otherwise Owned. A missing snapshot also becomes Unowned; do not interpret that fallback as verified historical ownership.
- Joined opportunities must have a pipeline-generation date and sales segment SMB, Mid-Market, or Enterprise. `days_to_sao` is the date difference from MQL to pipeline generation and can be negative. Won/closed fields and `payout_revenue` describe current opportunity-source data. `no_segmentation` is a constant label, not a filter.

## Execution and validation

Use an authorized Snowflake connection and honor an explicitly requested platform. Prepare the optional cohort and activity predicates together as described above, using validated SQL dates or supported bindings. Remove unused date placeholders; do not leave a standalone activity cutoff on an unrestricted cohort. Keep requested filters in the execution copy unless editing the reusable query is part of the task.

When CSV is requested, use `raw-data/mql-analysis-YYYY-MM-DD-to-YYYY-MM-DD.csv` for a supplied range, `raw-data/mql-analysis-all-dates.csv` without date bounds, or a `from-YYYY-MM-DD`/`through-YYYY-MM-DD` suffix for one-sided bounds. Fetch all rows/pages, preserve the source columns and existing aliases, use standard UTF-8 CSV quoting, retain numeric precision and identifiers, and represent SQL nulls as empty fields. Verify the saved file by reading it back. Do not silently replace a different extract.

Check any supplied cohort bounds, observed coverage and null MQL dates when unbounded, distinct-MQL counts versus source, opportunity uniqueness before revenue sums, and join duplication. After activity or pickup changes, test boundary dates/hours, missing values, and multiple events for one person without multiplying MQL counts. Reconcile flags at MQL grain. If no records match, deliver a header-only extract; if execution is unavailable, state that limitation rather than reusing stale data as fresh.

For analysis, distinguish MQL volume, pickup/touch rates, email response, meeting-or-call activity, MQL-associated NBMs, and opportunity outcomes. Use explicit denominators and maturity windows, and report the applied date scope (or all dates). Report unknown ownership and activity-data limitations where they affect the result.
