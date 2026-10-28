SELECT
    os.*,
    EXTRACT(DAYOFYEAR FROM os.pipeline_generation_date) AS day_number,
    EXTRACT(WEEKOFYEAR FROM os.pipeline_generation_date) AS week_number,
    EXTRACT(MONTH FROM os.pipeline_generation_date) AS month_number,
    TO_VARCHAR(EXTRACT(YEAR FROM os.pipeline_generation_date)) AS year,
    CASE
        WHEN os.mql_type = 'Scored' THEN 'Scored'
        WHEN os.attributed_marketing_campaign_name ILIKE '%orgs web form_product%'
            THEN 'RH: OWF - Product'
        WHEN os.attributed_marketing_campaign_name ILIKE '%orgs web form_website%'
            AND os.attributed_marketing_campaign_name NOT ILIKE '%_creditpurchase_%'
            THEN 'RH: OWF - Website'
        WHEN os.attributed_marketing_campaign_name ILIKE '%orgs web form_website%'
            AND os.attributed_marketing_campaign_name ILIKE '%_creditpurchase_%'
            THEN 'RH: OWF - Website - AI Credits'
        ELSE 'RH - Ex-OWF'
    END AS attributed_mql_type_mod,
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
    a.figmasegment__c AS figma_segment
FROM dwh_analytics.marketing.fig2_sf_sales_opportunity_source AS os
LEFT JOIN dwh_cleaned.salesforce.cleaned_salesforce_account AS a
    ON os.account_id = a.id
WHERE 
    os.pipeline_generation_date BETWEEN {{ start_date }} AND {{ end_date }}
    and sales_segment in ('SMB', 'Mid-Market', 'Enterprise');
