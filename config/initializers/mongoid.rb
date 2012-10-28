require 'cfruntime'

unless Rails.env.production?
  Mongoid.logger.level = Logger::DEBUG
  Moped.logger.level = Logger::DEBUG
end

Mongoid.configure do |config|
  if CFRuntime::CloudApp.running_in_cloud?
    conn_info = CFRuntime::CloudApp.service_props('mongodb')
    puts "conn_info=#{conn_info.inspect}"

    sess = {
      :default => {
        :database => conn_info[:db],
        :hosts => ["#{conn_info[:host]}:#{conn_info[:port]}"],
        :username => conn_info[:username],
        :password => conn_info[:password]
      }
    }
    puts "mongo sess=#{sess.inspect} conn_info=#{conn_info.inspect}"

    config.sessions = sess
  else
    Mongoid.load!("config/mongoid.yml")
  end
end

if Rails.env.production?
  puts 'running migrations...'
  InsideCF::Application.instance_eval do
    config.after_initialize do
      Mongoid::Migrator.migrate("db/migrate/")
    end
  end
end
