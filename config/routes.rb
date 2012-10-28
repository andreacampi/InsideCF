InsideCF::Application.routes.draw do
  root :to => 'home#index'

  resources :deas

  Dir.glob File.expand_path("plugins/*", Rails.root) do |plugin_dir|
    file = File.join(plugin_dir, "config/routes.rb")
    if File.exists?(file)
      begin
        instance_eval File.read(file)
      rescue Exception => e
        puts "An error occurred while loading the routes definition of #{File.basename(plugin_dir)} plugin (#{file}): #{e.message}."
        exit 1
      end
    end
  end
end
