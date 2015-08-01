module Blog
  ROOT_DIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

  class Article
    attr_reader :path, :images, :album_id

    def self.all
      Dir["#{ROOT_DIR}/_posts/*"].select { |f| File.directory?(f) }.map { |f| new(f) }
    end

    def self.find
      candidates = all
      puts "Select the index of the article you're looking for:"
      candidates.each_with_index { |a, i| puts "%3i - %s" % [i, a.path] }
      selected_index = gets.chomp.to_i
      candidates[selected_index]
    end

    def initialize(path)
      @path = path
      @images = Dir["#{ROOT_DIR}/public/flickr/#{basename}/*.jpg"].map { |f| Image.new(self, f) }
    end

    def sync!
      return if @images.empty?
      puts "Syncing #{basename} article..."
      @images.map(&:sync!)
      @album_id ||= find_album || create_album
      @images.map(&:add_to_album!)
    end

    def flickr_url
      "https://www.flickr.com/photos/%s/sets/%s" % [
        Blog::USER["id"],
        @album_id
      ]
    end

    private

    def find_album
      result = flickr.photosets.getList.find { |album| album["title"] == basename }
      if result
        puts "  using the existing #{basename} album..."
        result["id"]
      end
    end

    def create_album
      puts "  creating the #{basename} album..."
      result = flickr.photosets.create(title: basename, primary_photo_id: @images.first.flickr_id)
      result["id"]
    end

    def basename
      @basename ||= File.basename(@path)
    end
  end

  Image = Struct.new(:article, :path, :flickr_id) do
    def sync!
      self.flickr_id ||= find_photo || upload_photo
    end

    def add_to_album!
      raise "This image has no flickr_id." unless flickr_id
      flickr.photosets.addPhoto(photoset_id: article.album_id, photo_id: flickr_id)
      puts "  adding the #{basename} photo to the article album..."
    rescue FlickRaw::FailedResponse
      raise unless $!.message.end_with?("Photo already in set")
      puts "  adding the #{basename} photo to the article album..."
    end

    def flickr_url
      "https://www.flickr.com/photos/%s/%s/in/album-%s/" % [
        Blog::USER["id"],
        flickr_id,
        article.album_id
      ]
    end

    def url(size=:url_c)
      @info ||= flickr.photos.getInfo(photo_id: flickr_id)
      FlickRaw.__send__(size, @info)
    end

    def basename
      @basename ||= File.basename(path)
    end

    private

    def find_photo
      result = flickr.photos.search(user_id: Blog::USER["id"], text: basename).first
      if result
        puts "  using the existing #{basename} photo..."
        result["id"]
      end
    end

    def upload_photo
      puts "  uploading the #{basename} photo..."
      flickr.upload_photo(path, title: basename)
    end
  end

end
