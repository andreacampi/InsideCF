module InsideCF
  class Plugin
    cattr_accessor :directory
    self.directory = File.join(Rails.root, 'plugins')

    cattr_accessor :public_directory
    self.public_directory = File.join(Rails.root, 'public', 'plugin_assets')

    @registered_plugins = {}
    class << self
      attr_reader :registered_plugins
      private :new

      def def_field(*names)
        class_eval do
          names.each do |name|
            define_method(name) do |*args|
              args.empty? ? instance_variable_get("@#{name}") : instance_variable_set("@#{name}", *args)
            end
          end
        end
      end
    end
    def_field :name, :description, :url, :author, :author_url, :version, :settings
    attr_reader :id

    class << self
      def register(id, &block)
        p = new(id)
        p.instance_eval(&block)

        p.name(id.to_s.humanize) if p.name.nil?

        ::I18n.load_path += Dir.glob(File.join(p.directory, 'config', 'locales', '*.yml'))

        view_path = File.join(p.directory, 'app', 'views')
        if File.directory?(view_path)
          ActionController::Base.prepend_view_path(view_path)
        end

        Dir.glob File.expand_path(File.join(p.directory, 'app', '{controllers,helpers,models}')) do |dir|
          ActiveSupport::Dependencies.autoload_paths += [dir]
        end

        overrides_path = File.join(p.directory, 'app', 'overrides')
        if File.directory?(overrides_path)
          Rails.application.paths['app/overrides'] ||= []
          Rails.application.paths['app/overrides'] << overrides_path
        end

        registered_plugins[id] = p
      end

      # Returns an array of all registered plugins
      def all
        registered_plugins.values.sort
      end

      def load
        Dir.glob(File.join(self.directory, '*')).sort.each do |directory|
          if File.directory?(directory)
            lib = File.join(directory, "lib")
            if File.directory?(lib)
              $:.unshift lib
              ActiveSupport::Dependencies.autoload_paths += [lib]
            end
            initializer = File.join(directory, "init.rb")
            if File.file?(initializer)
              require initializer
            end
          end
        end
      end
    end

    def initialize(id)
      @id = id.to_sym
    end

    def directory
      File.join(self.class.directory, id.to_s)
    end

    def public_directory
      File.join(self.class.public_directory, id.to_s)
    end

    def assets_directory
      File.join(directory, 'assets')
    end

    def <=>(plugin)
      self.id.to_s <=> plugin.id.to_s
    end

    def mirror_assets
      source = assets_directory
      destination = public_directory
      return unless File.directory?(source)

      source_files = Dir[source + "/**/*"]
      source_dirs = source_files.select { |d| File.directory?(d) }
      source_files -= source_dirs

      unless source_files.empty?
        base_target_dir = File.join(destination, File.dirname(source_files.first).gsub(source, ''))
        FileUtils.mkdir_p(base_target_dir)
      end

      source_dirs.each do |dir|
        # strip down these paths so we have simple, relative paths we can
        # add to the destination
        target_dir = File.join(destination, dir.gsub(source, ''))
        begin
          FileUtils.mkdir_p(target_dir)
        rescue Exception => e
          raise "Could not create directory #{target_dir}: \n" + e
        end
      end

      source_files.each do |file|
        begin
          target = File.join(destination, file.gsub(source, ''))
          unless File.exist?(target) && FileUtils.identical?(file, target)
            FileUtils.cp(file, target)
          end
        rescue Exception => e
          raise "Could not copy #{file} to #{target}: \n" + e
        end
      end
    end

    # Mirrors assets from one or all plugins to public/plugin_assets
    def self.mirror_assets(name=nil)
      if name.present?
        find(name).mirror_assets
      else
        all.each do |plugin|
          plugin.mirror_assets
        end
      end
    end
  end
end
