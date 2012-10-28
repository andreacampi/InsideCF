class NatsClient
  module Processor
    module Base

      def initialize(identifier, log_level = :default)
        @identifier = identifier
        @logger = Logger.new(Rails.root.join("log", "#{identifier}.log"))

        @logger.level = if log_level == :default
          Rails.env.production? ? Logger::INFO : Logger::DEBUG
        else
          log_level
        end
      end

    protected
      def parse_json(string = '{}')
        Yajl::Parser.parse(string)
      end
    end
  end
end
