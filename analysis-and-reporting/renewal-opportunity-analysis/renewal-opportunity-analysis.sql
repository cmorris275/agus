SELECT
    o.closedate,
    a.id AS account_id,
    a.name AS account_name,
    CASE
        WHEN a.regionpicklist__c = 'NA' THEN 'AMER'
        ELSE a.regionpicklist__c
    END AS region,
    a.subregionpicklist__c AS sub_region,
    o.id AS opp_id,
    o.name AS opportunity_name,
    SUM(o.payoutrevenueusd__c) AS net_arr,
    o.stagename AS stage,
    o.isclosed AS is_closed, -- flag can be used to break open vs closed opportunities
    o.iswon
FROM dwh_cleaned.salesforce.cleaned_salesforce_opportunity AS o
LEFT JOIN dwh_cleaned.salesforce.cleaned_salesforce_account AS a
    ON o.accountid = a.id
WHERE
    o.type = 'Renewal'
    AND o.forecastcategory != 'Omitted'
    AND o.accountbookid__c IS NOT NULL
    AND o.opportunityownerrole__c != 'Ops'
    AND o.closedate BETWEEN {start_date} AND {end_date} -- this is the date range for the analysis
GROUP BY ALL
HAVING SUM(o.payoutrevenueusd__c) > 0 -- this should never be 0 or negative b/c attribution will be moot as a result
