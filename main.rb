# frozen_string_literal: true

require_relative 'lib/openai_api'
require_relative 'lib/notion_api'

class RecipeAnalysis
  def self.run
    puts '[start] RecipeAnalysis.run'
    notion_api = NotionApi.new
    pages = notion_api.database_pages
    pages.each do |page|
      openai_response = OpenaiApi.new(user_text: page[:description]).extract_structure_data
      next if openai_response.empty?

      notion_api.update_database_pages(page[:id], openai_response[:title], openai_response[:category])
    end
    puts '[end] RecipeAnalysis.run'
  end
end

RecipeAnalysis.run
