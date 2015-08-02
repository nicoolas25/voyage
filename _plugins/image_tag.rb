require_relative "../_scripts/auth"
require_relative "../_scripts/blog"

module Jekyll
  class ImageTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @title = text.strip
    end

    def render(context)
      Blog::USER ||= Blog.auth("#{Blog::ROOT_DIR}/_flickr.yml")

      article_path = context["page"]["path"]
      article = Blog::Article.fetch(article_path)
      article.sync!

      image = article.images.find do |image|
        image.basename == @title
      end
      raise "Image '#{@title}' not found!" unless image

      %{<a class="flickr" href="#{article.flickr_url}"><img src="#{image.url}" alt="#{@title}"></a>}
    end
  end
end

Liquid::Template.register_tag('flickr', Jekyll::ImageTag)
