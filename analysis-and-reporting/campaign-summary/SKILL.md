---
name: campaign-summary
description: Pull, validate, export, and interpret marketing campaign summaries using the bundled Snowflake query. Use for campaign performance by member first-associated date, including responses, seniority touches, NBMs, MQLs, SAOs, and attributed pipeline. Excludes member-level extracts and standalone MQL or opportunity reports.
---

# Campaign summary

Use [campaign-summary.sql](campaign-summary.sql) as the starting query. Read it before execution; it is the source of truth for the implemented calculations. Apply request-specific dates or filters to an execution copy.

## Scope and inputs

- Identify any user-supplied dates, campaign filters, and the requested deliverable: data, CSV, interpretation, or a combination. Reporting dates are optional; without them, apply no reporting-date restriction and do not invent a default period or ask for dates solely because they are absent.
- Validate supplied dates before using them. Resolve an omitted year from clear context and state the assumption; clarify invalid or ambiguous supplied dates. When both bounds are supplied, require start <= end; when only one is supplied, apply only that bound.
- Default to one row per campaign with activity in the selected member cohort. The SQL groups by campaign attributes as well as ID; investigate multiple rows for one campaign ID rather than silently dropping them.
- Prefer campaign IDs for exact filters. Use name matching when requested, and disclose when a partial name matches several campaigns.
- Resolve the SQL relative to this skill folder. Resolve output paths from the user's project or explicit destination, without hardcoded machine paths.

## Reporting basis

The reporting-date field is `campaign_member_first_associated_date` from the campaign-member source, cast to `DATE`. Treat a conversational reference to “campaign first-associated date” as this field in an established campaign-summary request. It is distinct from `campaign_start_date` and from a campaign's first-ever member association.

The saved SQL still contains a `BETWEEN {{ start_date }} AND {{ end_date }}` predicate, with explicit date casts, inside `campaign_members`. In the execution copy, render it only for a valid supplied range, replace it with the supplied one-sided bound, or remove the entire predicate when dates are absent. Apply cohort filters inside this CTE before aggregation; filtering final campaign minimum/maximum dates is not equivalent. Without date bounds, the cohort spans all available associations, including null association dates if present. Retain response eligibility and relative NBM windows independently of optional reporting dates.

A **valid campaign response** is a campaign-member ID with a non-null `campaign_member_first_responded_date`. A valid response is **required for campaign NBM credit**, but **not required** for MQL, SAO, or PG attribution credit. This is why association date defines the base cohort: retain members with and without response dates, and apply the response-date requirement locally to `responses` and NBM eligibility. Do not filter the base cohort or MQL/opportunity joins to valid responders. A campaign can legitimately have zero valid responses and still receive MQLs or attributed pipeline.

The response date need only be present; it does not have to fall within the association-date reporting range. A report of responses occurring during a period would use a different date basis.

Compare calendar dates explicitly, using the timestamp's stored date representation. Do not substitute implicit timestamp-to-date boundary comparisons: session timezone conversion can admit records from an adjacent date. If a specific reporting timezone is requested, apply that timezone consistently to the filter and all reported association dates.

`first_cm_associated_date` and `last_cm_associated_date` are the earliest and latest non-null member associations in the selected cohort: within supplied bounds when present, otherwise across all available dates that meet the other filters. They remain null for a group with no dated associations. Day, week, month, and year describe the earliest association in that cohort. They are not separate daily groups. The query's week number follows the Snowflake session's week settings; establish a consistent convention before comparing week-based results across sessions.

MQLs, SAOs, pipeline, and closed-won outcomes are linked to those selected members. They are not independently restricted to events occurring during the date range. Closed-won status and other source attributes reflect the data available at extraction, not a historical snapshot at the end date. Label interpretations accordingly. For a request about pipeline generated during a period or campaigns launched during a period, establish that different reporting basis before adapting the query.

## Metrics and current definitions

| Output | Meaning |
| --- | --- |
| `responses` | Valid campaign responses: distinct campaign-member IDs in the association-date cohort with a non-null first-response date. |
| `director_plus_touches` | Members whose joined contact seniority is Executive, C-Level, Board Members, VP-Level, or Director. |
| `vp_plus_touches` | Members whose joined contact seniority is Executive, C-Level, Board Members, or VP-Level. |
| `nbms` | Distinct valid responding members with at least one qualifying New Business Meeting within 30 days before or after their first response date, inclusive. See the NBM definition below. |
| `mqls` | Distinct MQL IDs linked to the selected members, whether or not those members have a response date. A member may have multiple MQLs. |
| `saos` | Distinct attributed opportunity IDs with a non-null pipeline-generation date and sales segment SMB, Mid-Market, or Enterprise. The attributed member does not need a response date. |
| `pg` | Sum of `payout_revenue` for those SAOs, including attribution to members without a response date. |
| `sao_closed_won` | Those SAOs with `is_won = TRUE`. |
| `pg_closed_won` | Sum of `payout_revenue` for those won SAOs. This is the query's won-opportunity payout measure, not a separate recognized-revenue measure. |

Preserve these definitions unless the user requests a change. Relevant interpretation limits:

- Seniority comes from the contact join. Lead-only or unmatched people contribute no seniority touches. Seniority touches currently include members with and without response dates and represent members, not unique people across campaigns.
- The base population includes all members selected by association date; only `responses` represents valid campaign responses. The query adds no campaign-member, campaign, or opportunity deletion/status filters beyond those explicitly present in the SQL.
- Null campaign language is labeled English. This is a reporting default, not a verified language classification.
- Count metrics return zero when no qualifying records exist. Pipeline sums can be null; preserve null versus zero in exports.

## NBMs: current definition and campaign credit

**NBM means New Business Meeting.** The source definition is a Salesforce event with `type = 'AE - New Business Meeting'`, `isdeleted = FALSE`, and an `account__c` that joins to the cleaned account table. The meeting date is `e.enddate`. The person match uses `e.whoid`, aliased as `primary_contact_id` in the query; it does not use the separate `primarycontact__c` field or expand to all meeting attendees.

A campaign member receives NBM credit only when all three conditions hold:

1. The member belongs to the selected cohort, with first-associated-date bounds only when supplied.
2. The member has a **valid campaign response**, meaning a non-null first-response date. An MQL or attributed opportunity cannot substitute for this requirement.
3. An eligible event matches `cm.person_id = e.whoid`, with its end date between first-response date minus 30 days and first-response date plus 30 days, including both boundaries.

The window is anchored to the **first response**, not association date, MQL date, or a later response. Meetings before the response intentionally qualify. Neither the response nor meeting must occur within the report's association-date range. Missing person matches or missing meeting dates cannot qualify. Keep the response requirement local to NBMs and valid-response counts so members without responses retain MQL, SAO, and PG credit.

Both the campaign-summary and member-detail SQL cast the first-response field to `DATE` before applying ±30 days. The window starts at midnight 30 days before that date and ends at midnight 30 days after it, inclusive. The meeting field is not cast to `DATE`, so meeting timestamps later than midnight on day +30 do not qualify. Use the same reporting timezone consistently when one is requested; check source datatypes and boundary matches when reconciling reports.

**Counting unit:** `nbms` counts distinct campaign-member IDs with at least one matching event. Several events for one member contribute one; a single event can qualify more than one campaign member or campaign if each satisfies the rules. This is a member-level meeting association, not distinct meeting volume or exclusive campaign attribution. For each campaign, `nbms` must be no greater than `responses`; a campaign with zero valid responses must have zero NBMs.

**Duplicate selection and meeting status:** the event CTE retains one record per `(account__c, whoid, whatid, enddate)`. Its ordering prefers completed records first, then records without either cancellation flag, then records without a no-show flag, then the latest modification and event ID. These preferences do **not** require a meeting to be completed, attended, or non-canceled. Status fields are not used as eligibility filters, so the result must not be labeled “held meetings” or “completed meetings.” Add such exclusions only when the business definition changes explicitly.

When reviewing or changing NBM logic, compare campaign counts with an independent member-level existence check over the eligible events. Verify that no credited member lacks a response date, repeated events do not multiply member credit, and the inclusive 30-day boundaries are preserved. Preserve the distinction between this response-dependent metric and response-independent MQL/opportunity attribution.

## Sources and join rules

The bundled query uses:

- `dwh_analytics.marketing.fig2_dim_campaign_member`: member cohort and campaign attributes.
- `dwh_analytics.marketing.fig2_dim_mql`: MQLs linked by `campaign_member_id`.
- `dwh_analytics.marketing.fig2_sf_sales_opportunity_source`: opportunities linked through `attributed_marketing_campaign_member_id`.
- `dwh_cleaned.salesforce.cleaned_salesforce_contact`: seniority linked by `person_id = id`.
- `dwh_cleaned.salesforce.cleaned_salesforce_event` and `cleaned_salesforce_account` in the same schema: NBM events and account eligibility.

The calculations assume unique campaign-member IDs, MQL IDs, opportunity IDs, and contact IDs in their respective sources. Verify these assumptions when first using a new environment or investigating unexplained totals.

Keep MQL and opportunity aggregation separate before joining to members. Joining both detail tables directly multiplies rows and can inflate pipeline. Never use `SUM(DISTINCT payout_revenue)` as a deduplication fix: different opportunities can have equal values. Reduce meeting matches to distinct member IDs before the final join.

## Execution and export

Use an available authorized SQL connection to Snowflake. Honor an explicitly requested platform such as Hex, but check its actual capabilities: project search or analysis-thread tools do not by themselves establish exact SQL execution or full-result CSV export. If the requested route cannot deliver the extract, explain the limitation before choosing an alternative. Do not claim that a query ran in Hex when it ran through a direct Snowflake connector.

Prepare optional date predicates as described above, using supported bindings or validated ISO date literals. Do not leave unresolved placeholders or an empty `WHERE`/dangling `AND` in the execution copy. Safely bind or escape campaign filters. Do not change business logic simply to accommodate a connector.

For a requested CSV:

- Use the user's destination. In this project, use `raw-data/campaign-summary-YYYY-MM-DD-to-YYYY-MM-DD.csv` for a supplied range, `campaign-summary-all-dates.csv` without date bounds, or a `from-YYYY-MM-DD`/`through-YYYY-MM-DD` suffix for one-sided bounds. Resolve all names under `raw-data/`. Add a meaningful scope suffix for a filtered extract when useful.
- Export every returned column and row, including all result pages or partitions. A preview is not a complete extract.
- Use UTF-8, a header row, ISO calendar dates, and standard CSV quoting for embedded commas, quotes, and newlines. Preserve identifiers, decimal precision, and source text. Write SQL nulls as empty fields and retain numeric zeros.
- Keep exports reproducible with a stable order such as campaign ID. Avoid overwriting a different extract; replace an existing file when the user asks to refresh it, otherwise use a distinguishing suffix.
- Do not add summary rows or explanatory prose to a raw CSV. Report the date basis, filters, extraction time, and source query in the delivery message or an existing provenance mechanism.

## Validation and delivery

Before delivering an extract, reconcile the fetched row count with result metadata, verify column widths, check campaign-ID uniqueness, and confirm association-date outputs satisfy any supplied bounds. Without date bounds, report observed coverage and missing dates instead of claiming a requested period. Read the saved CSV back and compare its parsed values with the fetched result, accounting for nulls becoming empty fields.

For a first run or a change to joins or metric logic, reconcile valid-response, MQL, and opportunity totals against independent source aggregations for a bounded period. Check that nonresponding members retain their MQL and opportunity attribution and that valid responses do not exceed the cohort's member count. Validate NBM counts separately when their logic changes, using the same date and eligibility rules. Investigate discrepancies before claiming correctness. An empty result is valid if the query succeeded; produce a header-only CSV and state that no records matched.

When execution is unavailable, provide the prepared query and identify the access limitation. Do not invent data or present a prior extract as a fresh run.

For an export-only request, return the file link, row count, applied date scope (or all dates), and any material qualification. When interpretation is requested, distinguish valid responses, seniority reach, MQLs, and attributed pipeline. State denominators for rates: MQLs and opportunities can be attributed to members outside the valid-response population, and a member can have multiple MQLs or opportunities. Dividing all attributed outcomes by valid responses is not a responder-conversion rate. Avoid causal claims, ROI claims without cost data, and comparisons between cohorts with materially different time to mature without explaining that difference.
