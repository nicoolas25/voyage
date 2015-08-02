require_relative "blog"
require_relative "auth"

Blog::USER = Blog.auth("#{Blog::ROOT_DIR}/_flickr.yml")
article = Blog::Article.find
article.sync!
puts "Here is the corresponding album URL:"
puts "  #{article.flickr_url}"
puts "Here is the list of the image URLs from flickr:"
article.images.each { |image| puts "  #{image.basename} - #{image.url}" }
