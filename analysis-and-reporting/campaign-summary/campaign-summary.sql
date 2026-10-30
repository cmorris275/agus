-- Campaign summary for members first associated within the selected date range.
-- Render the selected dates as midnight boundaries, matching the Hex notebook.
-- Start date is inclusive; End date (exclusive) stops at its beginning midnight.
-- Calendar fields use the first association within this range, not necessarily
-- the campaign's first-ever association.
-- Output grain: one row per distinct combination of campaign ID and selected
-- campaign attributes. Attribute differences can yield multiple rows per ID.
WITH campaign_members AS (
    -- Keep members with and without a response date: MQL and opportunity
    -- attribution credit does not require a valid campaign response.
    SELECT cm.*
    FROM dwh_analytics.marketing.fig2_dim_campaign_member AS cm
    -- Preserve the source timestamp and the notebook's exclusive end boundary.
    WHERE cm.campaign_member_first_associated_date >= {{ start_date }}
        AND cm.campaign_member_first_associated_date < {{ end_date }}
        -- Optional: filter to a specific campaign.
        -- AND cm.campaign_name ILIKE '%{campaign_name_fragment}%'
        -- sales_region and sales_sub_region should be used for filtering in terms of geography/location.
),  

nbm AS (
    -- NBM = New Business Meeting, identified by the Salesforce event type
    -- 'AE - New Business Meeting'. Only non-deleted events with a matching
    -- account are eligible. Use enddate as the meeting date and whoid as the
    -- person to match; the alias below does not read primarycontact__c.
    -- Retain one event per (account__c, whoid, whatid, enddate), preferring
    -- completed, then non-canceled, then non-no-show records, followed by
    -- latest modification and event ID. These are duplicate-selection rules,
    -- not eligibility filters: incomplete/canceled/no-show events can qualify.
    SELECT
        e.whoid AS primary_contact_id,
        e.enddate AS nbm_date
    FROM dwh_cleaned.salesforce.cleaned_salesforce_event AS e
    INNER JOIN dwh_cleaned.salesforce.cleaned_salesforce_account AS a
        ON e.account__c = a.id
    WHERE e.type = 'AE - New Business Meeting'
        AND e.isdeleted = FALSE
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            e.account__c,
            e.whoid,
            e.whatid,
            e.enddate
        ORDER BY
            IFF(e.completed__c, 0, 1),
            IFF(
                COALESCE(e.canceledmeeting__c, FALSE)
                    OR COALESCE(e.meeting_canceled__c, FALSE),
                1,
                0
            ),
            IFF(COALESCE(e.no_show__c, FALSE), 1, 0),
            e.lastmodifieddate DESC,
            e.id
    ) = 1
),

nbm_members AS (
    -- Campaign NBM credit requires a valid campaign response: a non-null
    -- campaign_member_first_responded_date. MQL/SAO/PG credit has no such rule.
    -- Match the member's person_id to the event's whoid and use an inclusive
    -- +/- 30-day window around the member's FIRST response cast to DATE.
    -- Both bounds are midnight, inclusive; later times on day +30 do not qualify.
    -- This intentionally includes meetings before the response. Neither the
    -- response nor meeting date must fall inside the association-date range.
    -- Count each member once even when several meetings match. The same event
    -- can qualify multiple members/campaigns; this is not exclusive attribution
    -- or a count of distinct meeting events.
    SELECT DISTINCT cm.campaign_member_id
    FROM campaign_members AS cm
    INNER JOIN nbm AS n
        ON cm.person_id = n.primary_contact_id
        AND n.nbm_date BETWEEN
            DATEADD(DAY, -30, cm.campaign_member_first_responded_date::DATE)
            AND DATEADD(DAY, 30, cm.campaign_member_first_responded_date::DATE)
    WHERE cm.campaign_member_first_responded_date IS NOT NULL
),

mql_metrics AS (
    -- Aggregate before joining opportunities to prevent row multiplication.
    SELECT
        m.campaign_member_id,
        COUNT(DISTINCT m.mql_id) AS mqls
    FROM dwh_analytics.marketing.fig2_dim_mql AS m
    INNER JOIN campaign_members AS cm
        ON m.campaign_member_id = cm.campaign_member_id
    GROUP BY m.campaign_member_id
),

opportunity_metrics AS (
    -- The opportunity source has one row per opp_id. Aggregate independently
    -- of MQLs so each opportunity's payout_revenue is summed only once.
    SELECT
        os.attributed_marketing_campaign_member_id AS campaign_member_id,
        COUNT(DISTINCT os.opp_id) AS saos,
        SUM(os.payout_revenue) AS pg,
        COUNT(DISTINCT CASE WHEN os.is_won THEN os.opp_id END) AS sao_closed_won,
        SUM(CASE WHEN os.is_won THEN os.payout_revenue END) AS pg_closed_won
    FROM dwh_analytics.marketing.fig2_sf_sales_opportunity_source AS os
    INNER JOIN campaign_members AS cm
        ON os.attributed_marketing_campaign_member_id = cm.campaign_member_id
    WHERE os.pipeline_generation_date IS NOT NULL
        AND os.sales_segment IN ('SMB', 'Mid-Market', 'Enterprise')
    GROUP BY os.attributed_marketing_campaign_member_id
)

SELECT
    cm.campaign_name,
    cm.campaign_id,
    cm.mops_campaign_id,
    cm.campaign_description,
    cm.campaign_start_date,
    cm.campaign_type,
    cm.campaign_channel_source,
    COALESCE(cm.campaign_language, 'English') AS campaign_language,
    cm.campaign_product,
    cm.campaign_subproduct,
    cm.campaign_asset,
    cm.campaign_premise,
    cm.campaign_abm,
    cm.campaign_theme,

    -- Base date for campaign reporting: first member association in range.
    CAST(MIN(cm.campaign_member_first_associated_date) AS DATE) AS first_cm_associated_date,
    EXTRACT(DAYOFYEAR FROM MIN(cm.campaign_member_first_associated_date)) AS day_number,
    EXTRACT(WEEKOFYEAR FROM MIN(cm.campaign_member_first_associated_date)) AS week_number,
    EXTRACT(MONTH FROM MIN(cm.campaign_member_first_associated_date)) AS month_number,
    TO_VARCHAR(EXTRACT(YEAR FROM MIN(cm.campaign_member_first_associated_date))) AS year,
    CAST(MAX(cm.campaign_member_first_associated_date) AS DATE) AS last_cm_associated_date,

    -- Valid campaign responses: members with a first-response date.
    -- Keep this requirement local to responses and NBM eligibility, not the
    -- base cohort used for MQL and opportunity attribution.
    COUNT(DISTINCT CASE
        WHEN cm.campaign_member_first_responded_date IS NOT NULL
            THEN cm.campaign_member_id
    END) AS responses,

    -- Director+ / VP+ touches: members classified by contact job seniority.
    COUNT(DISTINCT CASE
        WHEN c.jobseniority__c IN ('Executive', 'C-Level', 'Board Members', 'VP-Level', 'Director')
            THEN cm.campaign_member_id
    END) AS director_plus_touches,
    COUNT(DISTINCT CASE
        WHEN c.jobseniority__c IN ('Executive', 'C-Level', 'Board Members', 'VP-Level')
            THEN cm.campaign_member_id
    END) AS vp_plus_touches,

    -- Valid responding members with >= 1 qualifying NBM, not meeting volume.
    COUNT(DISTINCT n.campaign_member_id) AS nbms,
    COALESCE(SUM(m.mqls), 0) AS mqls,
    COALESCE(SUM(o.saos), 0) AS saos,
    SUM(o.pg) AS pg,
    COALESCE(SUM(o.sao_closed_won), 0) AS sao_closed_won,
    SUM(o.pg_closed_won) AS pg_closed_won
FROM campaign_members AS cm
LEFT JOIN mql_metrics AS m
    ON cm.campaign_member_id = m.campaign_member_id
LEFT JOIN opportunity_metrics AS o
    ON cm.campaign_member_id = o.campaign_member_id
LEFT JOIN nbm_members AS n
    ON cm.campaign_member_id = n.campaign_member_id
LEFT JOIN dwh_cleaned.salesforce.cleaned_salesforce_contact AS c
    ON cm.person_id = c.id
GROUP BY ALL;
