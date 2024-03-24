require_relative 'lib/openai_api'

text = '夫が「今まで食べた麻婆豆腐で一番好き」と言ってくれた私の定番レシピ、ふわふわ鶏塩麻婆豆腐。調味料は塩&料理酒&豆板醤の３つだけ！豆腐の水切り不要、なんとオイルも使いません。調理時間10分でここまで美味しくなるんです。山椒&ラー油をトッピングするとさらに本格的。騙されたと思ってぜひ…！'
res = OpenaiApi.new(user_text: text).get_chat_results
puts res