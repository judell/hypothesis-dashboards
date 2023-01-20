query "groups" {
  sql = <<EOQ
    with groups as (
      select 
        jsonb_array_elements(groups) as group_info
      from 
        hypothesis_profile
    )
    select
      group_info->>'name' as label,
      group_info->>'id' as value
    from 
      groups
  EOQ
}


query "recently_annotated_urls" {
  sql = <<EOQ
    with thread_data as (
      select
        uri,
        title,
        count(*),
        min(created) as first,
        max(created) as last,
        sum(jsonb_array_length(refs)) as refs,
        array_agg(distinct username) as thread_participants
      from 
        hypothesis_search
      where
        query = 'group=' || $1 || '&limit=' || $2::int || '&wildcard_uri=https://' || $3 || '/*'
      group
        by uri, title
      order 
        by max(created) desc
    )
    select
      uri as value,
      title as label,
      json_build_object(
        'annos,replies', '(' || count || ' notes, ' || refs || ' replies)',
        'most_recent', substring(last from 1 for 10)
      ) as tags,
      count,
      refs
    from 
      thread_data
    where
      date(last) - date(first) > 0
      and refs is not null
  EOQ
}

query "top_annotators" {
  sql = <<EOT
    select 
      username, 
      count(*) as annotations
    from 
      hypothesis_search
    where query = 'limit=' || $1::int
      || '&group=' || $2
      || case when $3 = 'all' then '' else '&uri=' || $3 end
    group by 
      username 
    order by 
      annotations desc
    limit 10
  EOT 
}

query "top_domains" {
  sql   = <<EOT
    with domains as (
      select 
        (regexp_matches(uri, '.*://([^/]*)'))[1] as domain
      from 
        hypothesis_search
    where query = 'limit=' || $1::int
      || '&group=' || $2
      || case when $3 = 'all' then '' else '&uri=' || $3 end
    )
    select 
      domain, 
      count(*) as annotations
    from 
      domains
    group by 
      domain
    order by 
      annotations desc
    limit 10
  EOT
}

query "top_tags" {
  sql   = <<EOT
    with tags as (
      select 
        jsonb_array_elements_text(tags) as tag
      from 
        hypothesis_search
      where query = 'limit=' || $1::int
        || '&group=' || $2
        || case when $3 = 'all' then '' else '&uri=' || $3 end
    )
    select 
      tag,
      count(*) as tags
    from tags
    group by tag
    order by tags desc
    limit 10  
  EOT
}

