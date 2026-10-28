SELECT
    -- Invoice date and calendar fields.
    d.closedate AS invoice_date,
    DATE_TRUNC('month', d.closedate) AS closemonth,
    EXTRACT(DAY FROM d.closedate) AS day_of_month,
    EXTRACT(YEAR FROM d.closedate) AS year,
    DATEDIFF(
        'day',
        DATE_TRUNC('quarter', d.closedate),
        d.closedate
    ) + 1 AS day_of_qtr,
    d.quarter,

    -- Account and sales geography.
    d.sales_segment,
    COALESCE(d.region_picklist_clean, 'AMER') AS region_picklist_clean,
    d.sub_region_clean,
    d.billing_country,
    d.account_id,
    d.actual_amount AS total_invoice_amount,

    -- Campaign attribution and record links.
    d.campaign_channel,
    d.campaign_name,
    d.campaign_member_id AS mktg_touch,
    d.campaign_member_id,
    d.final_type,
    d.account_name,
    d.account_link,
    d.campaign_link,
    d.person_id,
    CONCAT(d.invoice_id, '-', d.actual_amount) AS invoice_id,

    -- Touch-allocated expansion values.
    d.touch_allocated_value AS touch_expansion_arr,
    d.touch_allocated_value,
    d.touch_allocated_ai_credit_revenue AS touch_ai_expansion_arr,

    -- Campaign and person attributes.
    d.campaign_type,
    d.campaign_theme,
    d.is_abm,
    d.campaign_product,
    d.job_title,
    d.job_seniority,
    CASE
        WHEN d.function ILIKE '%prod%' THEN 'prod_eng'
        WHEN d.function ILIKE '%eng%' THEN 'prod_eng'
        WHEN d.function ILIKE '%dev%' THEN 'prod_eng'
    END AS prod_eng,
    d.director_plus_mktg_touch,
    d.vp_plus_mktg_touch,
    d.ai_credit_invoice
FROM dwh_analytics.marketing.expansion_marketing_attribution_detail AS d
WHERE d.campaign_channel IS NOT NULL
