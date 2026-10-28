-- Campaign-member detail by inclusive first-associated calendar date.
-- Render date parameters as SQL date values. Keep members without responses
-- eligible for MQL/SAO/PG attribution. Rows can repeat per MQL x opportunity;
-- count distinct IDs and deduplicate by opportunity before summing pipeline.

WITH nbm AS (
    SELECT
        e.id AS nbm_id,
        -- One meeting can have several event rows (one per invited rep).
        COALESCE(e.account__c, '') || '|' || COALESCE(e.whoid, '') || '|'
            || COALESCE(e.whatid, '') || '|' || e.enddate::TEXT AS meeting_key,
        e.account__c AS account_id,
        IFF(LEFT(e.whatid, 3) = '006', e.whatid, NULL) AS opportunity_id,
        e.whoid AS primary_contact_id,
        e.enddate AS nbm_date,
        e.activitydate AS nbm_activity_date,
        e.createddate AS nbm_created,
        IFF(e.completed__c, 'Completed', 'Booked') AS status,
        e.canceledmeeting__c AS is_canceled,
        e.no_show__c AS is_no_show,
        e.ownerid AS owner_id,
        a.name AS account_name,
        a.figmasegment__c AS segment,
        h.sales_region AS region,
        a.subregionpicklist__c AS sub_region,
        a.billingcountry AS account_country
    FROM dwh_cleaned.salesforce.cleaned_salesforce_event AS e
    INNER JOIN dwh_cleaned.salesforce.cleaned_salesforce_account AS a
        ON e.account__c = a.id
    LEFT JOIN dwh_analytics.marketing.fig2_sf_sales_hierarchy AS h
        ON a.ownerid = h.rep_id
    WHERE e.type = 'AE - New Business Meeting'
        AND e.isdeleted = FALSE
    -- NBM = New Business Meeting. Retain one event per meeting key.
    -- Prefer completed, non-canceled, non-no-show, then latest modification
    -- and lowest ID. These preferences do not filter out those statuses.
    QUALIFY ROW_NUMBER() OVER (
        PARTITION BY
            COALESCE(e.account__c, '') || '|' || COALESCE(e.whoid, '') || '|'
                || COALESCE(e.whatid, '') || '|' || e.enddate::TEXT
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
    -- Dim Campaign Member Sourced Info
    cm.campaign_member_first_associated_date, -- Reporting cohort date.
    cm.campaign_member_first_responded_date, -- Non-null = valid campaign response.

    -- Region precedence: opportunity, MQL, then member.
    -- The final subregion fallback is currently a region, not a true subregion.
    COALESCE(os.sales_region, m.person_sales_region, cm.sales_region) AS cm_sales_region,
    COALESCE(os.sales_sub_region, m.person_sales_sub_region, cm.sales_region) AS cm_sales_sub_region,

    cm.person_id,
    CASE
        WHEN c.jobseniority__c IN ('Executive', 'C-Level', 'Board Members', 'VP-Level', 'Director')
            THEN cm.campaign_member_id
    END AS director_plus_touch,
    CASE
        WHEN c.jobseniority__c IN ('Executive', 'C-Level', 'Board Members', 'VP-Level')
            THEN cm.campaign_member_id
    END AS vp_plus_touch,
    cm.campaign_channel,
    cm.sales_region,
    cm.campaign_member_id,
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

    -- MQLs
    -- MQL attribution does not require a campaign response date.
    m.mql_id,
    m.mql_type,
    -- MQL channel classification; null when no MQL is attributed.
    CASE
        WHEN m.mql_id IS NULL THEN NULL
        WHEN m.mql_type = 'Scored' THEN 'Scored'
        WHEN m.mql_type = 'Raised Hand'
            AND cm.campaign_name ILIKE '%orgs web form_product%'
            THEN 'RH: OWF - Product'
        WHEN m.mql_type = 'Raised Hand'
            AND cm.campaign_name ILIKE '%orgs web form_website%'
            AND cm.campaign_name NOT ILIKE '%_creditpurchase_%'
            THEN 'RH: OWF - Website'
        WHEN m.mql_type = 'Raised Hand'
            AND cm.campaign_name ILIKE '%orgs web form_website%'
            AND cm.campaign_name ILIKE '%_creditpurchase_%'
            THEN 'RH: OWF - Website - AI Credits'
        ELSE 'RH - Ex-OWF'
    END AS campaign_channel_type,
    m.person_sales_region AS mql_sales_region,
    m.person_sales_sub_region AS mql_sales_sub_region,

    -- Opps
    os.sales_region AS opp_sales_region,
    os.sales_sub_region AS opp_sales_sub_region,

    -- SAOs and Pipeline (PG)
    CASE
        WHEN os.opp_id IS NOT NULL
            AND os.sales_segment IN ('SMB', 'Mid-Market', 'Enterprise')
            AND os.pipeline_generation_date IS NOT NULL
            THEN os.opp_id
    END AS sao,

    CASE
        WHEN os.opp_id IS NOT NULL
            AND os.sales_segment IN ('SMB', 'Mid-Market', 'Enterprise')
            AND os.pipeline_generation_date IS NOT NULL
            THEN os.opp_type
    END AS sao_type,

    CASE
        WHEN os.opp_id IS NOT NULL
            AND os.sales_segment IN ('SMB', 'Mid-Market', 'Enterprise')
            AND os.pipeline_generation_date IS NOT NULL
            THEN os.payout_revenue
    END AS pipeline,

    -- Closed Won SAOs and Pipeline (PG)
    CASE
        WHEN os.opp_id IS NOT NULL
            AND os.sales_segment IN ('SMB', 'Mid-Market', 'Enterprise')
            AND os.pipeline_generation_date IS NOT NULL
            AND os.is_won = TRUE
            THEN os.opp_id
    END AS closed_won_sao,

    CASE
        WHEN os.opp_id IS NOT NULL
            AND os.sales_segment IN ('SMB', 'Mid-Market', 'Enterprise')
            AND os.pipeline_generation_date IS NOT NULL
            AND os.is_won = TRUE
            THEN os.payout_revenue
    END AS closed_won_pipeline,

    -- Campaign NBM credit requires a valid response and a person-matched
    -- meeting within +/- 30 days of the FIRST response, inclusive.
    -- Cast the response to DATE: both bounds are midnight, inclusive.
    -- Later meeting times on day +30 do not qualify.
    -- Return the member ID once per detail row, not the number of meetings.
    CASE
        WHEN cm.campaign_member_first_responded_date IS NOT NULL
            AND EXISTS (
                SELECT 1
                FROM nbm AS n
                WHERE n.primary_contact_id = cm.person_id
                    AND n.nbm_date BETWEEN
                        DATEADD(DAY, -30, cm.campaign_member_first_responded_date::DATE)
                        AND DATEADD(DAY, 30, cm.campaign_member_first_responded_date::DATE)
            )
            THEN cm.campaign_member_id
    END AS nbm
FROM dwh_analytics.marketing.fig2_dim_campaign_member AS cm
LEFT JOIN dwh_analytics.marketing.fig2_dim_mql AS m
    ON cm.campaign_member_id = m.campaign_member_id
LEFT JOIN dwh_analytics.marketing.fig2_sf_sales_opportunity_source AS os
    ON cm.campaign_member_id = os.attributed_marketing_campaign_member_id
LEFT JOIN dwh_cleaned.salesforce.cleaned_salesforce_contact AS c
    ON cm.person_id = c.id
WHERE cm.campaign_channel IS NOT NULL
    AND CAST(cm.campaign_member_first_associated_date AS DATE)
        BETWEEN CAST({{ start_date }} AS DATE) AND CAST({{ end_date }} AS DATE);
