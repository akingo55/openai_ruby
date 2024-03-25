require 'notion-ruby-client'

class NotionApi
  def initialize
    @notion_api_token = ENV['NOTION_API_TOKEN']
    @notion_database_id = ENV['NOTION_DATABASE_ID']
  end

  def get_database_pages
    response = client.database_query(database_id: @notion_database_id, filter: empty_title_filter)
    descriptions(response[:results])
  end

  def update_database_pages(page_id, parameters)
    check_parameters(title, category)
    
    properties = build_properties(title, category)
    client.update_page(page_id: page_id, properties: properties)
  end

  private

  def client
    Notion::Client.new(token: @notion_api_token)
  end

  def descriptions(results)
    results.map do |r|
      {page_id: r["id"], description: r["properties"]["Description"]["title"][0]["plain_text"]}
    end
  end

  def empty_title_filter
    {
      'and': [
        {
          'property': 'Title',
          'rich_text': {
            'is_empty': true
          }
        }
      ]
    }
  end

  def check_parameters(title, category)
    raise "[Error] category:#{category} is not valid." unless valid_category?(category)

    raise "[Error] title:#{title} is empty." if title.nil?
  end

  def valid_category?(category)
    categories = ['和食','洋食','中華','韓国']
    categories.include?(category)
  end

  def build_properties(title, category)
    {
      'Title': {
        'rich_text': [
          {
            'type': 'text',
            'text': {
              'content': title
            }
          }
        ]
      },
      'Category': {
        'select': {
          'name': category
        }
      }
    }
  end
end