require 'nats_client/processor'

class NatsClient

  def initialize(*args)
    @started = nil
    @logger = Rails.logger
    @processor = {}

    configure
  end

  def run
    @started = Time.now
    NATS.on_error do |e|
      @logger.error("NATS problem, #{e}")
      STDERR.puts "NATS problem, #{e}"
      exit!
    end
    EM.error_handler do |e|
      @logger.error "Eventmachine problem, #{e}\n#{e.backtrace.join("\n")}"
      STDERR.puts "Eventmachine problem, #{e}"
      exit!
    end

    EM.next_tick do
      NATS.start(:uri => @config['mbus']) do
        # configure_timers
        # register_as_component
        subscribe_to_messages
      end
    end
  end

  def shutdown
    NATS.stop
  end

protected
  def configure
    @config = {
      'mbus' => configatron.mbus
    }
  end

  def subscribe_to_messages
    @processor[:component] = NatsClient::Processor::Component.new.subscribe
    @processor[:cloud_controller] = NatsClient::Processor::CloudController.new.subscribe
    @processor[:dea] = NatsClient::Processor::DEA.new.subscribe
    @processor[:droplet] = NatsClient::Processor::Droplet.new.subscribe
  end
end
