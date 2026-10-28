---
name: weave-mql-analysis
description: Extract and analyze Weave MQL cohorts using the bundled Snowflake query, including Weavy and Figma web-form classifications, pickup, follow-up activity, NBMs, ownership, and linked opportunities. Use for Weave MQL-date reporting rather than general MQL, campaign-association, or pipeline-generation-date reports.
---

# Weave MQL analysis

Read [weave-mql-analysis.sql](weave-mql-analysis.sql) before execution. Resolve it relative to this folder. This first draft documents the supplied query; the upstream definition of a Weave MQL is not established by this SELECT.

The `responses` and `nbm` CTEs and their output expressions are aligned with [mql-analysis.sql](../mql-analysis/mql-analysis.sql). When updating these shared definitions, compare both the activity source and the per-MQL matching expression. Retain the Weave source, campaign classifications, and opportunity scope when synchronizing these sections.

## Population, dates, and grain

Use `dwh_analytics.marketing.fig2_dim_weave_mql`, not the general `fig2_dim_mql` source. Reporting dates are optional and supplied by the user. The saved query has no final MQL-date filter. For valid supplied bounds, add a predicate on `dim.mql_date` before the final `GROUP BY ALL` in an execution copy. Use only the supplied lower and/or upper bound; with no dates, leave the MQL cohort unrestricted rather than inventing or requiring a period. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve omitted years only from clear context and state the assumption. Check the date datatype and any requested timezone; for inclusive calendar-day bounds on timestamps, compare calendar dates explicitly. Do not substitute campaign association or pipeline-generation date.

The `responses`, `meetings`, and `calls` CTEs still contain `activitydate >= {{ start_date }}` even though the final MQL cohort no longer has a date filter. These predicates restrict activity, not MQL selection, and can suppress flags for older MQLs if left in place by themselves. Retain/render them only when a matching lower MQL-date bound is supplied and they preserve the full activity windows. With no lower bound, remove these predicates from the execution copy, preserving email/call eligibility conditions and valid `WHERE`/`AND` syntax. Do not invent a start date to satisfy the placeholders. Do not cap activity at the supplied cohort end date: preserve the per-MQL 0–28-day matching windows and the independent ±30-day NBM windows.

The base cohort has no campaign-name, MQL-type, sales-segment, response, or deletion filter. Do not restrict it to Weavy website names merely because of the report's name. The opportunity CTE uses the **general** `dwh_analytics.marketing.fig2_sf_sales_opportunity_source`, not the Weave opportunity source used by `weave-sao-and-pg`. It includes all sales segments and requires only a non-null pipeline-generation date; opportunities left join by `mql_id`, preserving MQLs with no matching opportunity. The constant `no_segmentation` is a label, not a filter.

The output contains `dim.*` plus derived and joined fields. The final `GROUP BY ALL` groups identical projected rows; it is not an aggregation to one row per MQL or opportunity. Different opportunity fields still yield multiple rows for one MQL. Do not rely on this clause to make payout sums or MQL-level averages safe. One MQL can repeat for multiple opportunities. Count distinct `mql_id` and evaluate flags and touch-hour averages once per MQL. Before summing `payout_revenue`, verify one consistent row per `opp_id` and investigate repeated or conflicting values; never use `SUM(DISTINCT payout_revenue)` as a deduplication fix. Check uniqueness of source MQL IDs, contact/account IDs, and account snapshots by account ID and snapshot date when investigating join multiplication.

Opportunity dates and follow-up windows can extend beyond the cohort end date. Recent cohorts have less observed follow-up time. Current won status is not a historical end-date snapshot. Unbounded extracts can include null MQL dates; their relative activity/date expressions do not establish a dated cohort.

## Campaign classifications

Preserve the SQL's ordering and labels:

| Field | Implemented rule |
| --- | --- |
| `owf_source` | Product pattern first, then Website pattern, otherwise Other. There is no Weavy branch: a Weavy-only name is Other. Independent of MQL type. |
| `mql_type_mod` | Scored first; then Raised Hand split into Weavy Website, Figma Website, and Product, in that order; otherwise `RH - Ex-OWF`. |
| `mql_type_simple` | OWF when the campaign name matches `%orgs web form%`, otherwise EX-OWF. |

The Weavy branch matches `%orgs web form_weavy%`; the Figma Website branch matches `%orgs web form_website%`. Preserve the supplied Weavy spelling even though the source and folder use Weave. This query does not split AI-credit website campaigns into a separate classification. The fallback `RH - Ex-OWF` can include unexpected or null types and is not proof of Raised Hand intent. Underscores in `ILIKE` patterns are single-character wildcards.

Calendar fields derive from MQL date; `year` is text. `mql_week` uses the supplied shifted `DATE_TRUNC('week', ...)` expression. Week fields depend on Snowflake session settings; establish the convention before weekly comparisons rather than assuming ISO or fiscal weeks.

## Activity and touch measures

Activity matches `whoid = dim.person_id` from MQL date through day 28, inclusive. It is not capped at the reporting end date. One person's activity can match several overlapping MQL windows; these are association flags, not exclusive attribution. Selected activity `mqldate__c` fields are not used for matching.

| Field | Definition |
| --- | --- |
| `response` | 1 when a non-deleted Email task has exactly `In` in the third leading bracketed subject token within the activity window; otherwise 0. This is inbound email, not a campaign response. |
| `meeting` | 1 when any event or qualifying call task matches the activity window; otherwise 0. Includes calls and is broader than NBM. |
| `pickup` | MQL ID for Scored touch hours 0–24 or Raised Hand touch hours 0–4, inclusive; otherwise null. |
| `pickup_touch_hrs` | Touch hours for those same pickup-eligible MQLs. |
| `touch` | MQL ID when touch hours are nonnegative. Does not additionally test a valid-touch flag. |
| `automation` | Automation when `is_outreach_automation = TRUE`; otherwise No Automation, including nulls. |

The general event CTE has no type, deletion, completion, or cancellation filter. Calls match `%call%` and require at least one of: non-null description, non-null recording, positive duration, disposition matching `%answered%`, or inbound call type. Calls are not filtered by deletion or completion. Empty descriptions can qualify, and `%answered%` can match “unanswered.” Do not describe this indicator as held meetings or confirmed conversations. The email regex depends on the supplied subject format and case-sensitive `In`; missing or differently formatted subjects will not qualify.

## New Business Meetings

`nbm` returns the MQL ID when the person has an eligible Salesforce event within 30 days before or after MQL date, inclusive. It does not require a campaign response. Use event `whoid` for person matching and `enddate` for the meeting date. Eligible events have type `AE - New Business Meeting`, are non-deleted, and join an account through `account__c`.

The event CTE deduplicates the concatenated account/person/related-record/end-date key, preferring completed, non-canceled, non-no-show records, then latest modification and event ID. These are selection preferences, not eligibility filters. Incomplete, canceled, or no-show meetings can qualify. Count distinct non-null `nbm` as associated MQLs, not unique or held meetings. One event can credit multiple MQLs. Keep this +/-30-day measure separate from the forward 28-day `meeting` flag.

## Enrichment and outcomes

- Contact seniority supplies Director+ and VP+ MQL-ID markers. Director+ includes Executive, C-Level, Board Members, VP-Level, and Director; VP+ excludes Director. Lead-only or unmatched people have no contact seniority marker. These markers do not require a logged sales touch.
- Current account attributes join through the contact's `accountid`; the prior-day ownership snapshot joins through `dim.account_id`. These account paths may differ.
- Employee bands use the supplied SQL labels. Zero and null are Unknown; other unmatched values remain null. `figma_segment` is the current account field, not necessarily opportunity sales segment.
- Ownership is Unowned for snapshot role Ops, Marketing, or null. Missing snapshots also become Unowned; this does not prove historical lack of ownership.
- Opportunity fields reflect current source data. `days_to_sao` is MQL-to-pipeline date difference and can be negative. Pipeline is `payout_revenue`; confirm units before applying currency labels. Won-opportunity payout is not recognized revenue.

## Execute, validate, and deliver

Use an authorized Snowflake connection and honor an explicitly requested platform. Prepare optional cohort and activity predicates together as described above, using validated SQL date values or supported bindings. The saved activity CTEs reference only `start_date`; there is no saved final start/end cohort predicate to render. Remove unused placeholders and avoid a standalone activity cutoff on an unrestricted cohort. Keep request-specific filters in an execution copy unless a template change is requested. Do not claim execution or fresh results when access is unavailable.

For CSV requests, use `raw-data/weave-mql-analysis-YYYY-MM-DD-to-YYYY-MM-DD.csv` for a supplied range, `raw-data/weave-mql-analysis-all-dates.csv` without date bounds, or a `from-YYYY-MM-DD`/`through-YYYY-MM-DD` suffix for one-sided bounds. Add a scope suffix when useful. Export every row/page and column with UTF-8 CSV quoting, ISO dates, unchanged identifiers and numeric precision, and empty fields for nulls. Avoid overwriting a different extract unless a refresh is requested. Keep reporting metadata outside the raw CSV and read the saved file back to verify it matches the fetched result. A successful empty result should produce a header-only file.

Validate any supplied date bounds, observed coverage and null dates when unbounded, result completeness, distinct MQL counts against the Weave source, and opportunity uniqueness before pipeline sums. For changed logic, reconcile flags at MQL grain and check date/hour boundaries, overlapping activity, missing joins, and classification precedence, including Weavy, Figma website, Product, Scored, and fallback cases. Do not transfer the general MQL query's commercial-opportunity restriction to this query.

Report the applied date scope (or all dates), filters, extraction context, row count versus distinct MQL count when different, and denominators for rates. Distinguish pickup, inbound response, meeting-or-call activity, NBM association, and opportunity outcomes. Explain cohort maturity and material data limitations when comparing performance.
