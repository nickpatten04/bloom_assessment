SELECT 
    {{ dbt_utils.star(from=ref('int_organization_segments')) }}
FROM {{ ref('int_organization_segments') }}