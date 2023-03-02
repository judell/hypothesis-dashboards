dashboard "Home" {

  tags = {
    service  = "Hypothesis"
  }

  container {

    text {
      width = 3
      value = <<EOT
Home
🞄
[Media_Conversations](${local.host}/hypothesis.dashboard.MediaConversations)
      EOT
    }

  }

  with "hypothesis_search" {
    sql = <<EOQ
      create or replace function public.hypothesis_search(groupid text, max int, url text)
        returns setof hypothesis_search as $$
          select 
            * 
          from 
            hypothesis_search
          where 
            query = 'group=' || groupid || '&limit=' || max::int || '&uri=' || url
      $$ language sql;
    EOQ
  }

  container {

    input "groups" {
      query = query.groups
      title = "Hypothesis group"
      width = 3
    }

    input "annotated_uris" {
      title = "Search all, or choose URL"
      width = 8
      args = [ 
        self.input.groups.value,
        var.search_limit
      ]
      sql = <<EOQ
        with anno_counts_by_uri as (
          select 
            count(*),
            uri,
            title,
            group_id
          from
            hypothesis_search
          where
            query = 'group=' || $1 || '&limit=' || $2::int
          group by
            uri, title, group_id
          order by 
            count desc
        )
        select
          $2::int as count,
          'all' as value,
          'all' as label,
          jsonb_build_object('group','all') as tags
        union
        select
          count,
          uri as value,
          count || ' | ' || title || ' | ' || uri as label,
          jsonb_build_object('group', group_id) as tags
        from 
          anno_counts_by_uri
        order by
          count desc
      EOQ
    }

  }

  container {

    table {
      width = 4
      args = [
        self.input.annotated_uris.value
      ]
      sql = <<EOQ
      select 
        $1 as "document url"
      EOQ
      column "url" {
        href = "{{.'url'}}"
        wrap = "all"
      }
    }

    table {
      width = 4
      args = [
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      sql = <<EOQ
        select
          title as "document title"
        from
          hypothesis_search($1, 1, $2)
      EOQ
    }

    table {
      width = 4
      args = [
      var.search_limit,
      self.input.groups.value,
      self.input.annotated_uris.value
      ]
      sql = <<EOQ
      select 
        'limit=' || $1::int
        || '&group=' || $2
        || case when $3 = 'all' then '' else '&uri=' || $3 end
      as "api query"
      EOQ
      column "api query" {
        wrap = "all"
      }
      column "document url" {
        wrap = "all"
      }
    }


  }

  container {
    width = 12

    card {
      args = [
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      width = 3
      sql   = <<EOQ
        select count(*) as "matching annos"
      from
        hypothesis_search
      where query = 'limit=' || $1::int
        || '&group=' || $2
        || case when $3 = 'all' then '' else '&uri=' || $3 end
      EOQ
    }

    card {
      args = [
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      width = 3
      sql   = <<EOQ
        select count( distinct username) as "annotators"
      from
        hypothesis_search
      where query = 'limit=' || $1::int
        || '&group=' || $2
        || case when $3 = 'all' then '' else '&uri=' || $3 end
      EOQ
    }

    card {
      args = [
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      width = 3
      sql   = <<EOQ
        select substring(min(created) from 1 for 10) as "oldest anno"
      from
        hypothesis_search
      where query = 'limit=' || $1::int
        || '&group=' || $2
        || case when $3 = 'all' then '' else '&uri=' || $3 end
      EOQ
    }

    card {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      width = 3
      sql   = <<EOQ
        select substring(max(created) from 1 for 10) as "newest anno"
      from
        hypothesis_search
      where query = 'limit=' || $1::int
        || '&group=' || $2
        || case when $3 = 'all' then '' else '&uri=' || $3 end
      EOQ
    }
  }

  container {
    
    graph {

      title = "conversations"

      node {
        args = [  
          self.input.groups.value,
          var.search_limit,
          self.input.annotated_uris.value
        ]
        base = node.people
      }

      edge {
        args = [  
          self.input.groups.value,
          var.search_limit,
          self.input.annotated_uris.value
        ]
        base = edge.conversation
      }    

    }
  
  }

  container {
    table {
      args = [ 
        self.input.groups.value,
        100, 
        self.input.annotated_uris.value
      ]
      sql = <<EOQ
        select
          username,
          substring(updated from 1 for 10) as date,
          substring(exact from 1 for 100) as quote,
          text,
          'https://hypothes.is/a/' || id as url
        from
          hypothesis_search($1, $2, $3)
        order by updated desc
      EOQ
      column "text" {
        wrap = "all"
      }
      column "quote" {
        wrap = "all"
      }

    }
  }

  container {
    width = 12

    chart {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      title = "top annotators"
      type  = "donut"
      width = 4
      query = query.top_annotators
    }

    chart {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      title = "top domains"
      type  = "donut"
      width = 4
      query = query.top_domains
    }

    chart {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      type  = "donut"
      title = "top tags"
      width = 4
      query = query.top_tags
    }
  }

  container {
    width = 12

    table {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      title = "top annotators"
      type  = "donut"
      width = 4
      query = query.top_annotators
    }

    table {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      title = "top domains"
      type  = "donut"
      width = 4
      query = query.top_domains
    }

    table {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      type  = "donut"
      title = "top tags"
      width = 4
      query = query.top_tags
    }
  }

  container {
    width = 12

    table {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      title = "top urls"
      width = 12
      sql   = <<EOT
        select 
          count(*) as notes,
          title,
          uri
        from 
            hypothesis_search
        where query = 'limit=' || $1::int
          || '&group=' || $2
          || case when $3 = 'all' then '' else '&uri=' || $3 end
        group by 
          uri, title
        order by
          notes desc
        limit 10
      EOT
      column "uri" {
        wrap = "all"
      }
      column "title" {
        wrap = "all"
      }
    }

    chart {
      args = [ 
        var.search_limit,
        self.input.groups.value,
        self.input.annotated_uris.value
      ]
      type = "table"
      title = "top tags and taggers"
      width = 12
      sql   = <<EOT
        with user_tag as (
          select username, jsonb_array_elements_text(tags) as tag
          from 
            hypothesis_search
          where query = 'limit=' || $1::int
            || '&group=' || $2
            || case when $3 = 'all' then '' else '&uri=' || $3 end
        ),
        top_tags as (
          select 
            tag,
            count(*) as tags
        from user_tag
        group by tag
        order by tags desc
        limit 10
        )
        select 
          tag, tags as occurrences, array_to_string(array_agg(distinct username), ', ') as taggers
        from top_tags t join user_tag u using (tag)
        group by t.tag, t.tags
        order by tags desc
      EOT
    }

  }

}


node "people" {
  category = category.person
  sql = <<EOQ
    select
      username as id,
      username as title,
      jsonb_build_object(
        'username', username,
        'id', id,
        'text', text,
        'updated', substring(updated from 1 for 10)
      ) as properties
    from 
      hypothesis_search($1, $2, $3)
  EOQ
}


edge "conversation" {
  sql = <<EOQ
    with refs as (
      select
        username,
        id,
        jsonb_array_elements_text(refs) as ref_id
      from
        hypothesis_search($1, $2, $3)
    ),
    augmented_refs as (
      select
        r.username,
        r.id,
        r.ref_id,
        ( select s.username as ref_user from hypothesis_search($1, $2, $3) s where s.id = r.ref_id )
      from 
        refs r
    )
    select
      a.username as from_id,
      a.ref_user as to_id,
      'replies to' as title,
      jsonb_build_object(
        'ref_id', a.ref_id
      ) as properties
    from 
      augmented_refs a
  EOQ
}

