require 'json'

module Categories
  CATEGORY_CLASSIFICATION_FILE = 'categories.json'

  private

  def categories
    JSON.parse(File.read(CATEGORY_CLASSIFICATION_FILE), symbolize_names: true)
  end

  def category_names
    categories.map { |c| c[:name] }    
  end

  def category_description
    categories.map { |c| [c[:name], c[:description]].join(':') }.join(',')
  end
end
