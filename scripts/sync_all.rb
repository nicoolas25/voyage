require_relative "blog"
require_relative "auth"

Blog::USER = Blog.auth("#{Blog::ROOT_DIR}/flickr.yml")
Blog::Article.all.map(&:sync!)
