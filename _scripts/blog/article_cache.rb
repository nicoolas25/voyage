module Blog
  module ArticleCache
    extend self

    def fetch(article_path)
      article = store[article_path]
      return article if article && article.fresh?
      article = Blog::Article.fetch(article_path)
      article.sync!
      store[article_path] = article
    end

    private

    def store
      @store ||= {}
    end
  end
end
