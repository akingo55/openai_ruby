require 'openai'
require 'retries'

class OpenaiApi
  MAX_RETRY_COUNT = 3
  FUNCTION_NAME = 'recipe_analysis'.freeze

  def initialize(user_text:)
    @model = 'gpt-4-turbo-preview'
    @openai_api_key = ENV['OPENAI_API_KEY']
    @user_text = user_text.strip
  end

  attr_reader :model, :openai_api_key, :user_text

  def extract_structure_data
    category_names = categories.map { |c| c[:name] }
    category_explanation = categories.map { |c| [c[:name], c[:description]].join(':') }.join(',')

    response = with_retries(retry_option) do
      client.chat(
        parameters: {
          model: model,
          temperature: 0,
          messages: build_messages,
          functions: build_functions(category_names, category_explanation),
          function_call: { name: FUNCTION_NAME }
        }
      )
    end

    message = response.dig('choices', 0, 'message')
    return {} unless message['role'] == 'assistant' && message['function_call']

    JSON.parse(message.dig('function_call', 'arguments'), { symbolize_names: true})
  rescue Faraday::Error, JSON::ParserError => e
    puts "error occured: #{e}, input: #{message}"
    {}
  end

  private

  def client
    OpenAI::Client.new(access_token: openai_api_key)
  end

  def retry_option
    {
      max_retries: MAX_RETRY_COUNT,
      rescue: [Faraday::TimeoutError],
      base_sleep_seconds: 1,
      max_sleep_seconds: 5
    }
  end

  def build_messages
    introduction_text = "関数「#{FUNCTION_NAME}」を使って、以下のテキストからレシピの情報を抽出してください。\n"
    [{ role: 'user', content: introduction_text + user_text }]
  end

  def categories
    [
      {
        name: '和食',
        description: '日本の伝統的な食材と調理法を用いた料理。季節の変化を感じさせる味わいが特徴がある。（例：親子丼、うどん、肉じゃがなど）'
      },
      {
        name: '洋食',
        description: 'ヨーロッパの料理を基にした食文化。肉や魚を主に使い、ソースやスパイスで味を引き立てる。（例：ハンバーグ、パスタなど）'
      },
      {
        name: '中華',
        description: '中国の伝統的な調理法を取り入れた料理。（例：麻婆豆腐、坦々麺、エビチリなど）'
      },
      {
        name: '韓国',
        description: '韓国の伝統的な料理。発酵食品や辛味が特徴。（例：キムチ、ビビンバ、サムギョプサルなど）'
      },
      {
        name: 'その他',
        description: '他の国や地域の料理に属さない、独自の味わいや文化を持つ料理。(例：タイ料理、メキシコ料理など)'
      }
    ]
  end

  def build_functions(category_names, category_explanation)
    [
      {
        name: FUNCTION_NAME,
        description: 'この関数は、テキストからレシピ名、レシピカテゴリを推定する処理です。titleにはレシピ名を、categoryには一番レシピに近いカテゴリを選択してください。合致するカテゴリがない場合は「その他」を選択してください。',
        parameters: {
          type: :object,
          properties: {
            title: {
              type: :string,
              description: 'レシピ名'
            },
            category: {
              type: :string,
              enum: category_names,
              description: "一番合致するカテゴリ\n#{category_explanation}"
            }
          },
          require: ['title']
        }
      }
    ]
  end
end
