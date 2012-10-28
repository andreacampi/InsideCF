class CloudControllerAPI
  class << self
    def instance
      @_instance ||= new
    end
  end

  def client
    @_client ||= begin
      password = ENV['cc_password'] || configatron.cc.password
      client = CFoundry::V1::Client.new(configatron.cc.url)
      client.login(:username => configatron.cc.username, :password => password)
      client
    end
  end

  def app_by_name(name)
    client.apps.find do |a|
      a.name =~ /^#{name}(:?---.+)$/
    end
  end

  def ensure_url_mapped(app_or_name, url)
    app = app_or_name.is_a?(String) ? app_by_name(app_or_name) : app_or_name
    unless app.uris.include?(url)
      app.update!(:uris => app.uris + [url])
    end
  end

  def manage_urls(app_or_name, urls)
    app = app_or_name.is_a?(String) ? app_by_name(app_or_name) : app_or_name
    return unless app

    to_remove = app.uris - urls
    to_add = urls - app.uris
    puts "manage_urls: from #{app.uris.inspect} to #{urls.inspect}: remove #{to_remove.inspect} add #{to_add.inspect}"

    app.update!(:uris => urls)
  end
end
