---
name: weave-sao-and-pg
description: Extract and analyze Weave opportunities by pipeline-generation date using the bundled Snowflake query. Use for Weave SAO counts, payout-based pipeline, opportunity detail, and OWF source analysis; use the separate SAO/PG workflow for the general opportunity source.
---

# Weave SAOs and pipeline generation

Read [weave_sao_and_pg.sql](weave_sao_and_pg.sql) before execution. Resolve the query relative to this folder and output paths relative to the user's project. This first draft documents the supplied query; source grain, available opportunity fields, and revenue units still require confirmation against the Weave source.

## Population and reporting basis

Use `dwh_analytics.marketing.fig2_sf_sales_weave_opportunity_source`, not the general `fig2_sf_sales_opportunity_source`. Do not infer additional product eligibility from campaign-name patterns or combine the two sources without checking overlap by opportunity ID.

Reporting dates are optional and supplied by the user. The reporting-date field is `os.pipeline_generation_date`. Validate supplied dates, require start <= end for a range, and clarify invalid or ambiguous input. Resolve an omitted year only from clear context and state the assumption. Use only supplied bounds; with no dates, apply no reporting-date restriction and do not invent or require a period. Do not substitute opportunity creation, MQL, campaign-association, or closed-won date.

The saved SQL still contains `os.pipeline_generation_date BETWEEN {{ start_date }} AND {{ end_date }}`. In the execution copy, render it for a valid supplied range, replace it with a one-sided bound when appropriate, or remove the entire `WHERE` when dates are absent. No separate non-null pipeline-date predicate exists, so the unbounded extract can retain undated opportunities. Separate them from pipeline-generating opportunities when reporting SAOs and PG.

Check the source datatype before interpreting calendar-day boundaries. If it is a timestamp, date literals may omit activity after midnight on the end date. For a requested inclusive calendar-date extract, compare explicitly cast dates in an execution copy, applying a requested reporting timezone consistently.

The query adds no sales-segment, attribution-source, campaign-response, deletion, or stage/status restrictions. Any eligibility rules already embedded in the Weave source must be verified upstream. Apply requested filters explicitly rather than borrowing the commercial-only population from campaign reports.

`os.*` returns every source column, so the export schema can change upstream. The intended analytical grain is one opportunity, but verify the source key and uniqueness of both opportunity records and account IDs before treating each result row as an opportunity.

## Measures

- **SAOs:** distinct `opp_id` with a non-null pipeline-generation date, within any supplied date bounds, after confirming that identifier exists and represents the source grain. Report undated records separately in unbounded extracts. SAO means sales-accepted opportunity; this query imposes no separate stage flag.
- **PG:** `payout_revenue` summed once per opportunity in that same SAO population, if that field exists with the intended meaning in the Weave source. Do not substitute `amount` or ARR components without an explicit definition.
- **Won outcomes, when requested:** use cohort opportunities with `is_won = TRUE` if supported by the source. This describes current won status for the pipeline cohort, not wins occurring during the reporting period.

Confirm opportunity fields and payout currency/units before publishing measures. Investigate duplicate IDs and inconsistent values before summing; do not select arbitrary rows or use `SUM(DISTINCT payout_revenue)` to remove duplicates. Preserve null versus zero. Unless the source establishes historical snapshots, treat enrichment and outcome status as extraction-time attributes.

## Classifications and enrichment

The supplied `mql_type_mod` CASE currently returns `Scored` when `os.mql_type = 'Scored'`, and `RH - Ex-OWF` otherwise. Its three OWF branches each require the **campaign name** to equal `Raised Hand` and also match a web-form pattern. Those conditions cannot both hold, so the Weavy Website, Figma Website, and Product branches are unreachable.

The likely intended equality is `os.mql_type = 'Raised Hand'`, but that is an unconfirmed correction. Preserve the supplied query unless a logic change is requested, disclose this limitation when using the classification, and do not interpret zero OWF rows as absence of OWF pipeline. The fallback also includes null or unexpected MQL types and does not prove Raised Hand intent.

If the condition is revised, retain the requested branch precedence: Scored, Weavy Website (`%orgs web form_weavy%`), Figma Website (`%orgs web form_website%`), Product (`%orgs web form_product%`), then fallback. These patterns use SQL underscore wildcards. There is no separate AI-credit classification in this query.

Calendar fields derive from pipeline-generation date. `year` is text, and `day_nubmer` retains the supplied spelling. Week numbering depends on Snowflake session settings; establish a consistent convention for weekly comparisons.

Account enrichment joins `os.account_id = a.id` in `dwh_cleaned.salesforce.cleaned_salesforce_account`. `employee_count` and `figma_segment` describe that account source, not a historical snapshot or necessarily the opportunity's sales segment. Employee bands are 1–10, 11–25, 26–50, 51–100, 101–250, 251–500, 501–1,000, 1,001–5,000, and 5,000+. Zero/null become Unknown; other unmatched values remain null. Unmatched accounts remain in the extract through the left join.

## Execution, validation, and delivery

Use an authorized Snowflake connection and honor an explicitly requested platform. Prepare only supplied date bounds as described above, using validated SQL date literals or supported bindings; remove unused placeholders and the date predicate when dates are absent. Keep request-specific scope changes in an execution copy unless editing the reusable template is requested.

For CSV requests, use `raw_data/weave_sao_and_pg_YYYY-MM-DD_to_YYYY-MM-DD.csv` for a supplied range, `raw_data/weave_sao_and_pg_all_dates.csv` without date bounds, or a `from_YYYY-MM-DD`/`through_YYYY-MM-DD` suffix for one-sided bounds. Add a descriptive scope suffix when useful. Fetch all rows/pages, preserve all returned columns, identifiers, decimal precision, and source text, and use UTF-8 CSV quoting, ISO dates, and empty fields for SQL nulls. Use stable opportunity ordering and avoid overwriting a different extract without a refresh request.

Validate any supplied date bounds, null pipeline dates in unbounded extracts, result completeness, source opportunity grain, and account-join uniqueness. Reconcile distinct opportunity counts and payout totals against the Weave source with identical filters. If classification logic changes, check Scored, each OWF pattern, null, and fallback cases. Read the saved CSV back to confirm its dimensions and values match the fetched result.

Deliver the requested file or findings with the applied date scope (or all dates), filters, extraction context, and material definition limits. Distinguish opportunity volume, payout per opportunity, source mix, and current won status. Return a header-only CSV for a successful empty result; if execution is unavailable, identify that limitation rather than presenting an existing extract as fresh.
