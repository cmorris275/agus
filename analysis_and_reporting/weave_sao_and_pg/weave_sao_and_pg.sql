select
    os.*,
    extract(dayofyear from os.pipeline_generation_date) as day_nubmer,
    extract(weekofyear from os.pipeline_generation_date) as week_number,
    extract(month from os.pipeline_generation_date) as month_number,
    to_varchar(extract(year from os.pipeline_generation_date)) as year,
    case
        when os.mql_type = 'Scored' then 'Scored'
        when os.attributed_marketing_campaign_name = 'Raised Hand' and os.attributed_marketing_campaign_name ilike '%orgs web form_weavy%' then 'RH: OWF - Weavy Website'
        when os.attributed_marketing_campaign_name = 'Raised Hand' and os.attributed_marketing_campaign_name ilike '%orgs web form_website%' then 'RH: OWF - Figma Website'
        when os.attributed_marketing_campaign_name = 'Raised Hand' and os.attributed_marketing_campaign_name ilike '%orgs web form_product%' then 'RH: OWF - Product'
        else 'RH - Ex-OWF'
    end as mql_type_mod,
    a.employeecount__c as employee_count,
    case
        when a.employeecount__c between 1 and 10 then '1-10'
        when a.employeecount__c between 11 and 25 then '11-25'
        when a.employeecount__c between 26 and 50 then '26-50'
        when a.employeecount__c between 51 and 100 then '51-100'
        when a.employeecount__c between 101 and 250 then '101-250'
        when a.employeecount__c between 251 and 500 then '251-500'
        when a.employeecount__c between 501 and 1000 then '501-1000'
        when a.employeecount__c between 1001 and 5000 then '1001-5k'
        when a.employeecount__c > 5000 then '5K+'
        when a.employeecount__c = 0 then 'Unknown'
        when a.employeecount__c is null then 'Unknown'
    end as employee_range,
    a.figmasegment__c as figma_segment
from dwh_analytics.marketing.fig2_sf_sales_weave_opportunity_source os
left join dwh_cleaned.salesforce.cleaned_salesforce_account a on os.account_id = a.id
where
    os.pipeline_generation_date between {{ start_date }} and {{ end_date }}
