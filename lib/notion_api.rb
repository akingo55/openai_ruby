# frozen_string_literal: true

require 'notion-ruby-client'
require_relative 'category'

class NotionApi
  class NoValidParameterError < StandardError; end

  def initialize
    @notion_api_token = ENV['NOTION_API_TOKEN']
    @notion_database_id = ENV['NOTION_DATABASE_ID']
  end

  attr_reader :notion_api_token, :notion_database_id

  def database_pages
    response = client.database_query(database_id: notion_database_id, filter: empty_title_filter)
    descriptions(response[:results])
  end

  def update_database_page(page_id, params)
    check_parameters(params)

    properties = build_properties(params)
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
      'or': [
        {
          'property': 'Title',
          'rich_text': {
            'is_empty': true
          }
        },
        {
          'property': 'Category',
          'select': {
            'is_empty': true
          }
        },
        {
          'property': 'Ingredients',
          'multi_select': {
            'is_empty': true
          }
        }
      ]
    }
  end

  def check_parameters(params)
    raise NoValidParameterError, "[Error] one or some of parameters are not valid. params:#{params}" if params.values.any? {|p| p.empty? }

    category = params[:category]
    raise NoValidParameterError, "[Error] category:#{category} is not valid." unless valid_category?(category)
  end

  def valid_category?(category)
    Category.names.include?(category)
  end

  def build_properties(params)
    {
      'Title': {
        'rich_text': [
          {
            'type': 'text',
            'text': {
              'content': params[:title]
            }
          }
        ]
      },
      'Category': {
        'select': {
          'name': params[:category]
        }
      },
      'Ingredients': {
        'multi_select': params[:ingredients].map { |i| { name: i } }
      }
    }
  end
end
