module Blog
  ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  def self.offline=(offline)
    @offline = offline
  end

  def self.offline
    !!@offline
  end

  def self.user
    @user
  end

  def self.user=(user)
    @user = user
  end

  begin
    Net::HTTP.get('www.google.com', '/')
  rescue SocketError
    self.offline = true
  end

  require_relative "blog/article"
  require_relative "blog/image"
end
