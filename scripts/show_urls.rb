require_relative "blog"
require_relative "auth"

Blog::USER = Blog.auth("#{Blog::ROOT_DIR}/flickr.yml")
article = Blog::Article.find
article.sync!
puts "Here is the corresponding album URL:"
puts "  #{article.flickr_url}"
puts "Here is the list of the image URLs from flickr:"
article.images.each do |image|
  puts "  #{image.basename}"
  puts "    jpg    - #{image.url}"
  puts "    flickr - #{image.flickr_url}"
end
