require_relative "../_scripts/auth"
require_relative "../_scripts/blog"

module Jekyll
  class ImageTag < Liquid::Tag

    def initialize(tag_name, text, tokens)
      super
      @title = text.strip
    end

    def render(context)
      article_path = context["page"]["path"]
      Blog::USER ||= Blog.auth("#{Blog::ROOT_DIR}/_flickr.yml")
      article = Blog::ArticleCache.fetch(article_path)

      image = article.images.find do |image|
        image.basename == @title
      end
      raise "Image '#{@title}' not found!" unless image

      %{<a class="flickr" target="_blank" href="#{article.flickr_url}"><img src="#{image.url}" alt="#{@title}"></a>}
    end
  end
end

Liquid::Template.register_tag('flickr', Jekyll::ImageTag)
