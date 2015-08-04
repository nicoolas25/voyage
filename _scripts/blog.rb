module Blog
  ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  require_relative "blog/article"
  require_relative "blog/image"
end
