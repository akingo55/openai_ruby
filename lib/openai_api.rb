require 'openai'
require 'retries'

MAX_RETRY_COUNT = 3
FUNCTION_NAME = 'recipe_analysis'.freeze

class OpenaiApi
  def initialize(user_text:)
    @model = 'gpt-3.5-turbo'
    @openai_api_key = ENV['OPENAI_API_KEY']
    @user_text = user_text.strip
  end

  def get_chat_results
    response = with_retries(retry_option) do
      client.chat(
        parameters: {
          model: @model,
          temperature: 0,
          messages: build_messages,
          functions: build_functions,
          function_call: { name: 'recipe_analysis' }
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
    OpenAI::Client.new(access_token: @openai_api_key)
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
    [{ role: 'user', content: introduction_text + @user_text }]
  end

  def categories
    [
      {
        name: '和食',
        description: '日本発祥の料理（例：親子丼、うどん、肉じゃがなど）'
      },
      {
        name: '洋食',
        description: '日本、中国、韓国以外の国発祥の料理（例：ハンバーグ、パスタなど）'
      },
      {
        name: '中華',
        description: '中国発祥の料理（例：麻婆豆腐、坦々麺、エビチリなど）'
      },
      {
        name: '韓国',
        description: '韓国発祥の料理（例：キムチ、ビビンバ、サムギョプサルなど）'
      }
    ]
  end

  def build_functions
    category_names = categories.map { |c| c[:name] }
    category_explanation = categories.map { |c| [c[:name], c[:description]].join(':') }.join(',')
    [
      {
        name: FUNCTION_NAME,
        description: 'この関数は、テキストからレシピ名、レシピカテゴリを推定する処理です。titleにはレシピ名を、categoryには一番類似するカテゴリを選択してください。',
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
