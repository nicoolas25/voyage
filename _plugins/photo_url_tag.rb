require_relative "../_scripts/auth"
require_relative "../_scripts/blog"

module Jekyll
  class PhotoUrlTag < Liquid::Tag

    def render(context)
      article_path = context["post"]["path"]
      Blog::USER ||= Blog.auth("#{Blog::ROOT_DIR}/_flickr.yml")
      article = Blog::ArticleCache.fetch(article_path)

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
