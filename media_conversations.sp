dashboard "MediaConversations" {

  tags = {
    service  = "Hypothesis"
  }

  container {

    text {
      width = 3
      value = <<EOT
[Home](${local.host}/hypothesis.dashboard.Home)
🞄
MediaConversations
      EOT
    }

  }

  input "groups" {
      title = "Hypothesis group"
      width = 3
      sql = <<EOQ
        with groups as (
          select 
            jsonb_array_elements(groups) as group_info
          from 
            hypothesis_profile
        )
        select
          group_info->>'name' as label,
          group_info->>'id' as value,
          json_build_object('id', group_info->>'id') as tags
        from 
          groups
      EOQ
  }   

  input "media_source" {
    title = "media source (select or type another)"
    type = "combo"
    width = 4
    sql = <<EOQ
      with data(label, value) as (
      values
        ('www.nytimes.com', 'www.nytimes.com'),
        ('www.washingtonpost.com', 'www.washingtonpost.com'),
        ('www.theatlantic.com', 'www.theatlantic.com'),
        ('www.latimes.com', 'www.latimes.com'),
        ('en.wikipedia.org', 'en.wikipedia.org'),
        ('www.jstor.org', 'www.jstor.org'),
        ('chem.libretexts.org', 'chem.libretexts.org'),
        ('www.americanyawp.com', 'www.americanyawp.com')
      )
      select * from data
    EOQ
  }

  input "annotated_uris" {
    args = [ 
      self.input.groups.value,
      var.search_limit,
      self.input.media_source.value
    ]
    title = "recently-annotated urls"    
    width = 5
    query = query.recently_annotated_urls
  }


  graph {

    node {
      category = category.person
      args = [  
        self.input.groups.value,
        var.search_limit,
        self.input.annotated_uris.value
      ]
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


    edge {
      args = [  
        self.input.groups.value,
        var.search_limit,
        self.input.annotated_uris.value
      ]
      sql = <<EOQ
        select
          username as from_id,
          ref_user as to_id,
          'replies to' as title,
          jsonb_build_object(
            'ref_id', ref_id
          ) as properties
        from 
          hypothesis_augmented_refs($1, $2, $3)
      EOQ

    }

  }


}





