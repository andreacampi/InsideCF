class NatsClient
  module Processor
    class Component
      include Base

      def initialize
        super("nats-component")
      end

      def subscribe
        NATS.subscribe('vcap.component.announce') do |message|
          process_announce_message(message)
        end

        self
      end

    protected
    # [#353] Received on [vcap.component.announce] : '{"type":"DEA","index":null,"uuid":"fbee5586c06e322a077369ad18cff6bf","host":"192.168.74.204:52157","credentials":["dbd7d28aff3b26bd3c018d4d141d75f0","247bb4586b7401ce963d858349808feb"],"start":"2012-08-24 10:40:19 +0200"}'
      def process_announce_message(message)
        parsed_message = parse_json(message)

        begin
          class_name = "NatsClient::Processor::#{parsed_message['type']}"
          klass = class_name.constantize
          klass.process_component_announcement(parsed_message, @logger)
        rescue NameError => e
          @logger.debug "Could not find a processor for #{parsed_message['type']}, ignoring."
        end
      end
    end
  end
end
  