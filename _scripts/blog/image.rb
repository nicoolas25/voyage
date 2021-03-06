require "open-uri"

module Blog
  Image = Struct.new(:article, :path, :flickr_id) do

    def self.download(article, name:, url:, flickr_id:)
      raise "Can't do this offline" if Blog.offline
      path = "#{article.image_dir}/#{name}"
      puts "  downloading #{name} from Flickr..."
      File.open(path, "wb") { |f| f.write(open(url).read) }
      new(article, path, flickr_id)
    end

    def sync!
      raise "Can't do this offline" if Blog.offline
      self.flickr_id ||= find_photo || upload_photo
    end

    def add_to_album!
      raise "Can't do this offline" if Blog.offline
      raise "This image has no flickr_id." unless flickr_id
      flickr.photosets.addPhoto(photoset_id: article.album_id, photo_id: flickr_id)
      puts "  adding the #{basename} photo to the article album..."
    rescue FlickRaw::FailedResponse
      raise unless $!.message.end_with?("Photo already in set")
      puts "  adding the #{basename} photo to the article album..."
    end

    def url(size=:url_c)
      if Blog.offline
        "/public/flickr/" + article.basename + "/" + basename
      else
        @info ||= flickr.photos.getInfo(photo_id: flickr_id)
        FlickRaw.__send__(size, @info)
      end
    end

    def basename
      @basename ||= File.basename(path)
    end

    private

    def find_photo
      result = flickr.photos.search(user_id: Blog.user["id"], text: basename).first
      if result
        puts "  using the existing #{basename} photo..."
        result["id"]
      end
    end

    def upload_photo
      puts "  uploading the #{basename} photo..."
      flickr.upload_photo(path, title: basename, is_public: 0)
    end
  end
end
