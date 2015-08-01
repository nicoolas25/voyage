require "yaml"
require "flickraw"

module Blog
  def self.auth(config_filepath)
    flickr_config = YAML.load_file(config_filepath)

    # Application configuration
    FlickRaw.api_key = flickr_config["api_key"]
    FlickRaw.shared_secret = flickr_config["secret"]

    # User authentication
    if flickr_config["access_token"] && flickr_config["access_secret"]
      flickr.access_token = flickr_config["access_token"]
      flickr.access_secret = flickr_config["access_secret"]

      # From here you are logged:
      login = flickr.test.login
      puts "You are now authenticated in Flickr as #{login.username}"
      login
    else
      puts "User's credentials are missing!"
      token = flickr.get_request_token
      auth_url = flickr.get_authorize_url token["oauth_token"], perms: "delete"

      puts "Open this url in your process to complete the authication process : #{auth_url}"
      puts "Copy here the number given when you complete the process."
      verify = gets.strip

      begin
        flickr.get_access_token(token["oauth_token"], token["oauth_token_secret"], verify)
        login = flickr.test.login
        puts "Copy the following lines in your #{config_filepath} file:"
        puts "access_token: #{flickr.access_token}"
        puts "access_secret: #{flickr.access_secret}"
        exit 1
      rescue FlickRaw::FailedResponse => e
        puts "Authentication failed: #{e.msg}"
      end
    end
  end
end
