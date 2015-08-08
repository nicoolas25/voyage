require "pstore"
require_relative "article_cache"

module Blog
  class Article
    class << self
      def all
        candidates.map { |path| fetch(path) }
      end

      def find
        puts "Select the index of the article you're looking for:"
        candidates.each_with_index { |path, i| puts "%3i - %s" % [i, path] }
        selected_index = gets.chomp.to_i
        selected_path = candidates[selected_index]
        fetch(selected_path)
      end

      def fetch(path)
        basename = File.basename(path, ".markdown")
        spath = store_path(basename)
        if File.exist?(spath)
          store = PStore.new(spath)
          store.transaction(true) { store[:article] }.tap(&:refresh!)
        else
          new(path)
        end
      end

      def store(instance)
        spath = store_path(instance.basename)
        store = PStore.new(spath)
        store.transaction { store[:article] = instance }
        FileUtils.touch(spath)
      end

      def store_path(basename)
        "#{ROOT_DIR}/public/_flickr/#{basename}/_article.pstore"
      end

      private

      def candidates
        @candidates ||= Dir["#{ROOT_DIR}/_posts/*.markdown"]
      end
    end

    attr_reader :path, :images, :album_id

    def initialize(path)
      @path = path
      @images = image_paths.map { |f| Image.new(self, f) }
      @stored = false
    end

    def sync!
      return if @stored || !File.directory?(image_dir)
      puts "Syncing #{basename} article..."
      @album_id ||= find_album
      import_remote_images
      @images.map(&:sync!)
      @album_id ||= create_album
      @images.map(&:add_to_album!)
      flickr_url
      store!
    end

    def refresh!
      import_remote_images
      export_locally_new_images
      store!
    end

    def store!
      @stored = true
      self.class.store(self)
    end

    def flickr_url
      return unless @album_id
      args = { set: @album_id, is_private: 1, is_family: 1, is_friend: 1 }
      @flickr_url ||= flickr.call("flickr.sharing.createGuestpass", args)["url"]
    end

    def basename
      @basename ||= File.basename(@path, ".markdown")
    end

    def image_dir
      "#{ROOT_DIR}/public/_flickr/#{basename}"
    end

    def fresh?
      spath = self.class.store_path(basename)
      last_image_at = image_paths.map { |path| File.ctime(path) }.max
      File.ctime(spath) > last_image_at
    end

    private

    def image_paths
      Dir["#{image_dir}/*.{jpg,JPG}"]
    end

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

    def import_remote_images
      return unless @album_id
      photos = flickr.photosets.getPhotos(photoset_id: @album_id, extras: "url_o")
      existing_image_names = image_paths.map { |path| File.basename(path) }
      new_photos = photos["photo"].reject { |photo| existing_image_names.include?(photo["title"]) }
      new_photos.each do |photo|
        @images << Image.download(self,
          flickr_id: photo["id"],
          name: photo["title"],
          url: photo["url_o"])
      end
    end

    def export_locally_new_images
      new_paths = image_paths.reject do |path|
        @images.find { |image| image.basename == File.basename(path) }
      end
      new_paths.each do |path|
        @images << Image.new(self, path).tap do |image|
          image.sync!
          image.add_to_album!
        end
      end
    end
  end
end
