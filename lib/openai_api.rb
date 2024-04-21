# frozen_string_literal: true

require 'openai'
require 'retries'
require_relative 'category'

class OpenaiApi
  MAX_RETRY_COUNT = 3
  FUNCTION_NAME = 'recipe_analysis'
  FUNCTION_DESCRIPTION = <<~TEXT
    この関数は、入力されたテキストからレシピ名、レシピのカテゴリを推定し、レシピにで使われる食材を抽出する処理です。
    以下のルールに従ってください。
    # ルール
    - titleには入力テキストからレシピ名を推定する
    - categoryはレシピに最も一致するカテゴリを1つ選択し、合致するカテゴリがない場合は「その他」を選択する
    - ingredientsはレシピで使われている主要な食材（肉、野菜、魚介）を最大3つ抽出する
    - ingredientsに醤油、酒、砂糖、塩、水などの調味料を含めてはいけない
  TEXT

  def initialize(user_text:)
    @model = ENV['OPENAI_MODEL_NAME']
    @openai_api_key = ENV['OPENAI_API_KEY']
    @user_text = user_text.strip
  end

  attr_reader :model, :openai_api_key, :user_text

  def extract_structure_data
    response = with_retries(retry_options) do
      client.chat(
        parameters: {
          model: model,
          temperature: 0,
          messages: build_messages,
          functions: build_functions,
          function_call: { name: FUNCTION_NAME }
        }
      )
    end

    message = response.dig('choices', 0, 'message')
    return {} unless message['role'] == 'assistant' && message['function_call']

    JSON.parse(message.dig('function_call', 'arguments'), { symbolize_names: true })
  rescue Faraday::Error, JSON::ParserError => e
    puts "error occured: #{e}, input: #{message}"
    {}
  end

  private

  def client
    OpenAI::Client.new(access_token: openai_api_key)
  end

  def retry_options
    {
      max_retries: MAX_RETRY_COUNT,
      rescue: [Faraday::TimeoutError],
      base_sleep_seconds: 1,
      max_sleep_seconds: 5
    }
  end

  def build_messages
    introduction_text = "関数「#{FUNCTION_NAME}」を使って、テキストからレシピの情報を抽出してください。"
    [
      { role: 'system', content: introduction_text },
      { role: 'user', content: user_text }
    ]
  end

  def build_functions
    [
      {
        name: FUNCTION_NAME,
        description: FUNCTION_DESCRIPTION,
        parameters: {
          type: :object,
          properties: {
            title: {
              type: :string,
              description: 'レシピ名'
            },
            category: {
              type: :string,
              enum: Category.names,
              description: "一番合致するカテゴリ\n#{Category.description}"
            },
          ingredients: {
            type: :array,
            description: 'レシピで使われているメインの食材を最大3つ抽出する',
            items: {
              type: :string
            }
          }
          },
          require: ['title', 'category', 'ingredients']
        }
      }
    ]
  end
end
