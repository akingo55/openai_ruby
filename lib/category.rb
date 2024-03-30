require 'json'

class Category
  CATEGORY_CLASSIFICATION_FILE = 'categories.json'

  def self.names
    categories.map { |c| c[:name] }    
  end

  def self.description
    categories.map { |c| "#{c[:name]}:#{c[:description]}" }.join(',')
  end

  def self.categories
    JSON.parse(File.read(CATEGORY_CLASSIFICATION_FILE), symbolize_names: true)
  end

  private_class_method :categories
end
