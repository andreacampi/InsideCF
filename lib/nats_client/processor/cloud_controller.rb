class NatsClient
  module Processor
    class CloudController
      include Base

      UPDATE_APPS = 30  # every 30 seconds

      def initialize
        super("nats-cc")
      end

      def subscribe
        retrieve_apps

        EM.add_periodic_timer(UPDATE_APPS) do
          retrieve_apps
        end
      end

      def retrieve_apps
        NATS.request('cloudcontroller.bulk.credentials') do |response|
          credentials = parse_json(response)
          @logger.debug "credentials: #{credentials.inspect}"

          url = "#{configatron.cc.url}/bulk/apps"
          http = EM::HttpRequest.new(url).get(:head => { "authorization" => [credentials['user'], credentials['password']] })
          http.errback do
            @logger.debug "failed: #{http.response_header.inspect}"
          end
          http.callback do
            if http.response_header.status == 200
              handle_cc_response(http)
            else
              @logger.warn "retrieve_apps: failure: #{http.response_header.status}\n#{http.response_header.inspect}\n#{http.response}"
            end
          end
        end
      end

    protected
      def handle_cc_response(http)
        if http.response.blank?
          @logger.warn "handle_cc_response: response is #{http.response}"
          return
        end

        parsed_response = parse_json(http.response)
        if parsed_response.blank?
          @logger.warn "handle_cc_response: response is #{parsed_response}"
          return
        end

        bulk_token = parsed_response['bulk_token']
        results = parsed_response['results']

        @logger.debug "bulk response: OK, bulk_token=#{bulk_token}"

        results.each do |app_id, info|
          @logger.debug "response: #{app_id}: #{info.inspect}"
          app = App.find_or_create_by(:app_id => info['id']).tap do |app|
            app.app_id              = info['id']
            app.owner_id            = info['owner_id']
            app.name                = info['name'].gsub(/---.*$/, '')
            app.original_name       = info['name']
            app.staged_package_hash = info['staged_package_hash']
            app.extra               = info
            app.save!
            ActiveSupport::Notifications.instrument("app.cc.nats.inside_cf", :app => app)
          end
        end
      end
    end
  end
end
