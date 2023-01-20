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
    query = query.groups
    title = "Hypothesis group"
    width = 3
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





