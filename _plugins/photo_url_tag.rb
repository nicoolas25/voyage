require_relative "../_scripts/auth"
require_relative "../_scripts/blog"

module Jekyll
  class PhotoUrlTag < Liquid::Tag

    def render(context)
      Blog::USER ||= Blog.auth("#{Blog::ROOT_DIR}/_flickr.yml")

      article_path = context["post"]["path"]
      article = Blog::Article.fetch(article_path)
      article.sync!

      image_name = context["post"]["photo"]
      image = article.images.find do |image|
        image.basename == image_name
      end
      raise "Image '#{image_name}' not found!" unless image

      image.url
    end
  end
end

Liquid::Template.register_tag('photo_url', Jekyll::PhotoUrlTag)
