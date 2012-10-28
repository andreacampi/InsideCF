class NatsClient
  module Processor
    class Droplet
      include Base

      def initialize
        super("nats-droplet")
      end

      def subscribe
        NATS.subscribe('droplet.exited') do |message|
          @logger.debug { "droplet.exited: #{message}" }
          process_exited_message(message)
        end

        NATS.subscribe('droplet.updated') do |message|
          @logger.debug { "droplet.updated: #{message}" }
          process_updated_message(message)
        end
      end

    protected
      def process_exited_message(message)
        parsed_message = parse_json(message)
        @logger.info "process_exited_message: #{parsed_message.inspect}"
      end

      def process_updated_message(message)
        parsed_message = parse_json(message)
        @logger.info "process_updated_message: #{parsed_message.inspect}"
      end
    end
  end
end
