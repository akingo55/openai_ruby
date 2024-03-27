# recipe-extractor-ruby
This tool estimates recipe titles and categories with OpenAI, which gets recipe descriptions from the particular notion database, and then estimates the title and category, and updates the notion pages.
## Install
```bash
rbenv install $(cat .ruby-version)
bundle install
```
## Configuration
```bash
export OPENAI_APY_KEY=xxx
export NOTION_API_TOKEN=xxx
export NOTION_DATABASE_ID=xxx
export OPENAI_MODEL_NAME=gpt-4-turbo-preview
```
You need to create Notion's integration to get `NOTION_API_TOKEN`.
## How to run
```bash
ruby main.rb
```
## Result
You can see like this:

![image](https://github.com/akingo55/openai_ruby/assets/43959158/95242723-6452-4bab-b98b-76b6c78bb1af)

