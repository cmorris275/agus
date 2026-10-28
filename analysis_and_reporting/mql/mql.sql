-- MQL detail by inclusive MQL date; render parameters as SQL date values.
-- Output can repeat an MQL for multiple linked opportunities. Count distinct
-- MQL IDs for flags and use one row per opportunity when summing pipeline.
-- Activity/outcome windows can extend beyond the requested cohort end date.

WITH opps AS (
    SELECT os.*
    FROM dwh_analytics.marketing.fig2_sf_sales_opportunity_source AS os
    WHERE 
        os.pipeline_generation_date IS NOT NULL
        and os.sales_segment in ('SMB', 'Mid-Market', 'Enterprise')
),

-- Inbound email activity, matched to each MQL below.
responses AS (
    SELECT
        id AS activity_id,
        activitydate,
        whoid,
        type,
        mqldate__c,
        isdeleted,
        subject,
        description,
        REGEXP_SUBSTR(
            subject,
            '^\\s*\\[[^\\]]*\\]\\s*\\[[^\\]]*\\]\\s*\\[([^\\]]*)\\]',
            1, 1, 'e', 1
        ) AS direction
    FROM dwh_cleaned.salesforce.cleaned_salesforce_task
    WHERE type = 'Email'
        AND isdeleted = FALSE
        AND REGEXP_SUBSTR(
            subject,
            '^\\s*\\[[^\\]]*\\]\\s*\\[[^\\]]*\\]\\s*\\[([^\\]]*)\\]',
            1, 1, 'e', 1
        ) = 'In'
        AND activitydate >= {{ start_date }}
),

meetings AS (
    SELECT
        id AS activity_id,
        whoid,
        activitydate,
        activitytype__c AS type
    FROM dwh_cleaned.salesforce.cleaned_salesforce_event
    WHERE activitydate >= {{ start_date }}
),

calls AS (
    SELECT
        id,
        activitydate,
        completeddatetime, -- Selected for context; not an eligibility filter.
        whoid,
        type,
        mqldate__c,
        isdeleted,
        calltype,
        calldisposition,
        call_recording__c,
        subject,
        description
    FROM dwh_cleaned.salesforce.cleaned_salesforce_task
    WHERE activitydate >= {{ start_date }}
        AND type ILIKE '%call%'
        AND (
            description IS NOT NULL
            OR call_recording__c IS NOT NULL
            OR calldurationinseconds > 0
            OR calldisposition ILIKE '%answered%'
            OR calltype = 'Inbound'
        )
),

-- NBM = New Business Meeting. Status ordering selects duplicates; it does
-- not exclude incomplete, canceled, or no-show meetings.
nbm AS (
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
            COALESCE(e.account__c, '') || '|' || COALESCE(e.whoid, '') || '|'
            || COALESCE(e.whatid, '') || '|' || e.enddate::text
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
)

SELECT
    dim.*,
    DATE_TRUNC('QUARTER', dim.mql_date) AS mql_quarter_mod,
    EXTRACT(DAYOFYEAR FROM dim.mql_date) AS day_number,
    EXTRACT(WEEKOFYEAR FROM dim.mql_date) AS week_number,
    EXTRACT(MONTH FROM dim.mql_date) AS month_number,
    TO_VARCHAR(EXTRACT(YEAR FROM dim.mql_date)) AS year,

    -- DIM MQL Additions
    CASE
        WHEN dim.mql_campaign_name ILIKE '%orgs web form_product%' THEN 'Product'
        WHEN dim.mql_campaign_name ILIKE '%orgs web form_website%' THEN 'Website'
        ELSE 'Other'
    END AS owf_source,
    CASE
        WHEN dim.mql_type = 'Scored' THEN 'Scored'
        WHEN dim.mql_type = 'Raised Hand'
            AND dim.mql_campaign_name ILIKE '%orgs web form_product%'
            THEN 'RH: OWF - Product'
        WHEN dim.mql_type = 'Raised Hand'
            AND dim.mql_campaign_name ILIKE '%orgs web form_website%'
            AND dim.mql_campaign_name NOT ILIKE '%_creditpurchase_%'
            THEN 'RH: OWF - Website'
        WHEN dim.mql_type = 'Raised Hand'
            AND dim.mql_campaign_name ILIKE '%orgs web form_website%'
            AND dim.mql_campaign_name ILIKE '%_creditpurchase_%'
            THEN 'RH: OWF - Website - AI Credits'
        ELSE 'RH - Ex-OWF'
    END AS mql_type_mod,
    CASE
        WHEN dim.mql_campaign_name ILIKE '%orgs web form%' THEN 'OWF'
        ELSE 'EX-OWF'
    END AS mql_type_simple,

    -- MQL Date Manipulation
    DATEADD(DAY, -1, DATE_TRUNC('week', DATEADD(DAY, 1, dim.mql_date))) AS mql_week,

    EXTRACT(DAY FROM dim.mql_date) AS mql_day_num,
    EXTRACT(MONTH FROM dim.mql_date) AS mql_month_num,
    EXTRACT(YEAR FROM dim.mql_date) AS mql_year_num,

    -- Person-level activity during MQL date through day 28, inclusive.
    -- response = inbound email; meeting = any event OR a qualifying call.
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM responses AS r
            WHERE r.whoid = dim.person_id
                AND r.activitydate BETWEEN dim.mql_date AND DATEADD(DAY, 28, dim.mql_date)
        ) THEN 1
        ELSE 0
    END AS response,
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM meetings AS mt
            WHERE mt.whoid = dim.person_id
                AND mt.activitydate BETWEEN dim.mql_date AND DATEADD(DAY, 28, dim.mql_date)
        ) OR EXISTS (
            SELECT 1
            FROM calls AS cl
            WHERE cl.whoid = dim.person_id
                AND cl.activitydate BETWEEN dim.mql_date AND DATEADD(DAY, 28, dim.mql_date)
        ) THEN 1
        ELSE 0
    END AS meeting,

    -- Pickup
    CASE
        WHEN dim.mql_type = 'Scored' AND dim.mql_touch_hrs BETWEEN 0 AND 24
            THEN dim.mql_id
        WHEN dim.mql_type = 'Raised Hand' AND dim.mql_touch_hrs BETWEEN 0 AND 4
            THEN dim.mql_id
    END AS pickup,
    CASE
        WHEN dim.mql_type = 'Scored' AND dim.mql_touch_hrs BETWEEN 0 AND 24
            THEN dim.mql_touch_hrs
        WHEN dim.mql_type = 'Raised Hand' AND dim.mql_touch_hrs BETWEEN 0 AND 4
            THEN dim.mql_touch_hrs
    END AS pickup_touch_hrs,

    -- Touch Data
    CASE
        WHEN dim.mql_touch_hrs >= 0
            THEN dim.mql_id
    END AS touch,

    -- Automation
    CASE
        WHEN dim.is_outreach_automation = TRUE
            THEN 'Automation'
        ELSE 'No Automation'
    END AS automation,

    -- SFDC Contact Data
    c.jobseniority__c AS job_seniority,
    CASE
        WHEN c.jobseniority__c IN ('Executive', 'C-Level', 'Board Members', 'VP-Level', 'Director')
            THEN dim.mql_id
    END AS director_plus_touch,
    CASE
        WHEN c.jobseniority__c IN ('Executive', 'C-Level', 'Board Members', 'VP-Level')
            THEN dim.mql_id
    END AS vp_plus_touch,

    -- MQL NBM association uses +/- 30 days around MQL date, inclusive.
    -- Unlike campaign NBM credit, this does not require a campaign response.
    CASE
        WHEN EXISTS (
            SELECT 1
            FROM nbm AS n
            WHERE n.primary_contact_id = dim.person_id
                AND n.nbm_date BETWEEN
                    DATEADD(DAY, -30, dim.mql_date::DATE)
                    AND DATEADD(DAY, 30, dim.mql_date::DATE)
        )
            THEN dim.mql_id
    END AS nbm,

    -- SFDC Account Data
    a.employeecount__c AS employee_count,
    CASE
        WHEN a.employeecount__c BETWEEN 1 AND 10 THEN '1-10'
        WHEN a.employeecount__c BETWEEN 11 AND 25 THEN '11-25'
        WHEN a.employeecount__c BETWEEN 26 AND 50 THEN '26-50'
        WHEN a.employeecount__c BETWEEN 51 AND 100 THEN '51-100'
        WHEN a.employeecount__c BETWEEN 101 AND 250 THEN '101-250'
        WHEN a.employeecount__c BETWEEN 251 AND 500 THEN '251-500'
        WHEN a.employeecount__c BETWEEN 501 AND 1000 THEN '501-1000'
        WHEN a.employeecount__c BETWEEN 1001 AND 5000 THEN '1001-5k'
        WHEN a.employeecount__c > 5000 THEN '5K+'
        WHEN a.employeecount__c = 0 THEN 'Unknown'
        WHEN a.employeecount__c IS NULL THEN 'Unknown'
    END AS employee_range,
    a.figmasegment__c AS figma_segment,

    -- Account Snapshot Data
    snap.accountownerrole__c AS owner_prior_to_mql,
    CASE
        WHEN (snap.accountownerrole__c IN ('Ops', 'Marketing') OR snap.accountownerrole__c IS NULL)
            THEN 'Unowned'
        ELSE 'Owned'
    END AS mql_ownership,

    -- Opportunity Data
    o.opp_id,
    o.pipeline_generation_date,
    o.opp_type,
    o.is_closed,
    o.is_won,
    o.closed_won_date,
    o.payout_revenue,
    DATEDIFF(DAY, dim.mql_date, o.pipeline_generation_date) AS days_to_sao,
    'No segmentation' AS no_segmentation
FROM dwh_analytics.marketing.fig2_dim_mql AS dim
LEFT JOIN dwh_cleaned.salesforce.cleaned_salesforce_contact AS c
    ON dim.person_id = c.id
LEFT JOIN dwh_cleaned.salesforce.cleaned_salesforce_account AS a
    ON c.accountid = a.id
LEFT JOIN dwh_core.salesforce.salesforce_daily_account AS snap
    ON dim.account_id = snap.id
        AND DATEADD(DAY, -1, dim.mql_date) = snap.snapshot_date
LEFT JOIN opps AS o
    ON dim.mql_id = o.mql_id
group by all;
