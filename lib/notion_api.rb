# frozen_string_literal: true

require 'notion-ruby-client'
require 'json'

class NotionApi
  class NoValidParameterError < StandardError; end

  CATEGORY_CLASSIFICATION_FILE = 'categories.json'

  def initialize
    @notion_api_token = ENV['NOTION_API_TOKEN']
    @notion_database_id = ENV['NOTION_DATABASE_ID']
  end

  attr_reader :notion_api_token, :notion_database_id

  def database_pages
    response = client.database_query(database_id: notion_database_id, filter: empty_title_filter)
    descriptions(response[:results])
  end

  def update_database_pages(page_id, title, category)
    check_parameters(title, category)

    properties = build_properties(title, category)
    client.update_page(page_id: page_id, properties: properties)
  end

  private

  def client
    Notion::Client.new(token: notion_api_token)
  end

  def descriptions(results)
    results.map do |r|
      { id: r['id'], description: r['properties']['Description']['title'][0]['plain_text'] }
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
    raise NoValidParameterError, "[Error] category:#{category} is not valid." unless valid_category?(category)

    raise NoValidParameterError, '[Error] title is empty.' if title.nil?
  end

  def valid_category?(category)
    categories.include?(category)
  end

  def categories
    json = JSON.parse(File.read(CATEGORY_CLASSIFICATION_FILE), symbolize_names: true)
    json.map { |c| c[:name] }
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
