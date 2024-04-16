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

<img width="958" alt="image" src="https://github.com/akingo55/recipe-extractor-ruby/assets/43959158/4a46e055-d3d0-4e8e-abcd-7004f609e08b">


