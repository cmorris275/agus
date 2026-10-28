---
name: campaign-member-analysis
description: Extract and analyze marketing campaign-member detail by first-associated date using the bundled Snowflake query, including valid responses, seniority, MQLs, attributed opportunities, and campaign NBM credit. Use for member-level attribution investigations and detail exports, not campaign-summary or MQL-date reporting.
---

# Campaign member analysis

Read [campaign-member-analysis.sql](campaign-member-analysis.sql) before running it. Resolve this resource relative to the skill folder; do not depend on a machine-specific checkout path.

## Reporting scope and row grain

Reporting dates are optional and supplied by the user. Apply valid bounds directly to the original `cm.campaign_member_first_associated_date` timestamp in an execution copy: `>= {{ start_date }}` and `< {{ end_date }}`. Use the selected start date at midnight inclusively and the beginning midnight of the end date exclusively, matching the campaign-summary query and current Hex notebook. Do not cast the source field to `DATE` or add one day to `end_date`. If only one bound is supplied, use only that bound; if none is supplied, apply no reporting-date restriction and do not invent or require a period. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve an omitted year only from clear context and state the assumption. Use any requested reporting timezone consistently.

The saved SQL has final inclusive-start and exclusive-end timestamp predicates using `{{ start_date }}` and `{{ end_date }}`. Label the end-date input **End date (exclusive)** in dashboards and reports. Inputs `2026-07-01` and `2026-09-30` include July 1 through September 29 and exclude September 30; equal start and end dates define an empty interval. Use the same timestamp datatype and session/reporting timezone conventions as the Hex notebook wherever the campaign cohort is constructed, including old/new queries, dashboards, and reports. Render only the supplied bounds, or remove both date predicates when dates are absent while preserving `WHERE cm.campaign_channel IS NOT NULL`. Without date bounds, null association dates can remain. This optional cohort restriction is separate from response requirements and relative NBM windows, which remain part of the metric logic.

The query excludes members whose `campaign_channel` is null. That filter is absent from the campaign-summary query, so those populations need not reconcile unless their filters are aligned. Do not add a response-date filter to the base population: a member does not need a valid campaign response to receive MQL, SAO, or pipeline attribution credit.

This is a joined detail extract, **not guaranteed to be one row per member**. MQLs and opportunities join independently by campaign-member ID, so one member can produce multiple MQL-by-opportunity combinations. The opportunity on a row is attributed to that member; it is not necessarily linked to the MQL on the same row. Keep that distinction when investigating a specific conversion path.

## Fields and aggregation

| Field or measure | Definition and safe use |
| --- | --- |
| Members | Count distinct `campaign_member_id`, not rows. |
| Valid campaign responses | Count distinct member IDs where `campaign_member_first_responded_date` is non-null. The response need not fall within the association-date range. |
| `director_plus_touch`, `vp_plus_touch` | Member IDs when the joined contact has the specified seniority. Count distinct non-null IDs. These markers do not require a response date. |
| `mql_id` | Attributed MQL identifier; count distinct IDs. Multiple MQLs per member are possible. |
| `sao`, `sao_type` | Opportunity ID/type when pipeline-generation date exists and sales segment is SMB, Mid-Market, or Enterprise. Count distinct `sao`. |
| `pipeline` | The qualifying opportunity's `payout_revenue`, repeated across joined MQL rows when applicable. |
| `closed_won_sao`, `closed_won_pipeline` | The same qualifying opportunities/payouts with `is_won = TRUE`. |
| `nbm` | Member ID receiving campaign NBM credit. Count distinct IDs, not rows or meetings. |

Before summing pipeline, produce one consistent row per qualifying opportunity ID (`sao`), or aggregate opportunities separately in SQL. Verify repeated values agree rather than choosing an arbitrary record. Never sum raw detail rows or use `SUM(DISTINCT pipeline)`: equal payouts can belong to different opportunities. Calculate person counts separately from member counts when needed.

MQL and opportunity outcome dates are not restricted to the reporting range. Attributes and won status reflect source data at extraction, not a historical end-date snapshot. Ratios of attributed MQLs/SAOs to valid responses are not responder-conversion rates because the numerator can include members without responses.

## Campaign NBMs

NBM means **New Business Meeting**. Eligible Salesforce events have type `AE - New Business Meeting`, are non-deleted, and join to an account through `account__c`. Matching uses `e.whoid = cm.person_id` and the event's `enddate`.

A credited member must have a **valid campaign response** and at least one matching event within 30 days before or after the **first response date**, inclusive. An MQL or opportunity cannot substitute for a missing response date. The response and meeting can fall outside the association-date reporting period; meetings before the response intentionally qualify.

Both the member-detail and campaign-summary SQL cast the first-response field to `DATE` before applying ±30 days. The window starts at midnight 30 days before that date and ends at midnight 30 days after it, inclusive. The meeting field is not cast to `DATE`, so meeting timestamps later than midnight on day +30 do not qualify. Use the same reporting timezone consistently when one is requested; check source datatypes and boundary matches when reconciling reports.

The event CTE deduplicates the account/person/related-record/end-date meeting key, preferring completed, non-canceled, non-no-show events and then latest modification and event ID. These preferences do not exclude incomplete, canceled, or no-show meetings. The source also enriches events with sales hierarchy; the final marker only tests whether a qualifying match exists.

Several events still yield one credited member. One event can credit multiple campaign members or campaigns. For a consistent campaign population, distinct NBM members must not exceed valid responses. Do not describe this measure as unique meetings, held meetings, or exclusive campaign attribution.

## Classification and enrichment

- Region precedence is opportunity, then MQL, then member. `cm_sales_sub_region` currently falls back to `cm.sales_region`, a region rather than a true subregion. Label this limitation in subregion reporting; do not invent a missing member subregion field.
- `campaign_channel_type` is null without an MQL. Otherwise Scored takes priority; Raised Hand records are classified from campaign-name patterns into OWF Product, OWF Website, or OWF Website AI Credits. The fallback is `RH - Ex-OWF`, including unrecognized MQL types. Do not treat that fallback as proof of Raised Hand intent.
- Preserve the supplied `ILIKE` patterns and ordering. Underscores in these patterns are SQL single-character wildcards, not necessarily literal separators.
- Director+ includes Executive, C-Level, Board Members, VP-Level, and Director; VP+ excludes Director. These come from the contact join, so unmatched or lead-only people have no seniority marker.
- Null campaign language defaults to English. This is a reporting convention, not verified language data.

Sources are the marketing campaign-member, MQL, and opportunity-source tables plus cleaned Salesforce contacts, events, accounts, and the marketing sales hierarchy named in the SQL. Preserve their attribution keys and investigate duplicates at their expected source grain before changing joins.

## Execute, validate, and deliver

Use an available authorized Snowflake connection, honoring an explicitly requested platform. Prepare only supplied date bounds using validated SQL date values or supported bindings, and remove unused date predicates and placeholders from the execution copy. Apply campaign filters to an execution copy; leave the reusable template intact unless a query change is requested.

For a requested CSV, use `raw-data/campaign-member-analysis-YYYY-MM-DD-to-YYYY-MM-DD.csv` for a supplied range, `raw-data/campaign-member-analysis-all-dates.csv` without date bounds, or a `from-YYYY-MM-DD`/`before-YYYY-MM-DD` suffix for a one-sided bound. In bounded filenames, the second date is the exclusive end boundary; state that explicitly in the accompanying report or provenance. Export all result pages and columns in UTF-8 with normal CSV quoting, ISO dates, unchanged identifiers/decimal precision, and empty fields for SQL nulls. Do not overwrite a different extract without an explicit refresh request. Read the saved CSV back to confirm it matches the fetched records.

Validate any applied reporting-date bounds and result completeness. Check source timestamps immediately before and exactly at both midnight boundaries against `>= start_date` and `< end_date`; an equal-date range must be empty. With no date restriction, report observed coverage and missing dates. Report both row count and distinct-member count when they differ. Reconcile distinct MQL and SAO counts and opportunity-deduplicated pipeline with source aggregations when changing joins or metric logic. Check that every NBM member has a response date. An empty successful query should produce a header-only export, not invented results.

For interpretation, distinguish valid responses, attribution without responses, and repeated detail rows. Include the channel-null exclusion and subregion fallback when they affect the conclusion. Return the requested artifact or findings with the applied date scope (or all dates), filters, and extraction context.
