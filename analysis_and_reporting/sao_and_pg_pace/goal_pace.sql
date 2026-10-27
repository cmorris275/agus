select
    attributed_source,
    by_month,
    sales_region,
    sales_segment,
    metric_type,
    metric_name,
    metric_value
from DWH_ANALYTICS.MARKETING.GOALS_ACTUALS_COMBINED
where 
    sales_segment not in ('Other')
    and metric_name in ('MQL', 'SAO', 'PG')
