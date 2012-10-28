require 'nats_client/processor/dea/finders'

class NatsClient
  module Processor
    class DEA
      include Base
      include Finders
      extend Finders

      RUNNING_STATES    = Set.new(%w[STARTING RUNNING])
      DROPLET_LOST      = 30                            # seconds

      def initialize
        super("nats-dea")
      end

      def subscribe
        NATS.subscribe('dea.advertise') do |message|
          process_advertise_message(message)
        end

        NATS.subscribe('dea.heartbeat') do |message|
          process_heartbeat_message(message)
        end

        NATS.subscribe('dea.start') do |message|
          process_start_message(message)
        end

        EM.add_periodic_timer(DROPLET_LOST) do
          expire_old_droplets
        end

        self
      end

      class << self
        #
        # XXX This API is whack; we should either turn processors into singletons or set
        # the logger per class.
        #
        # [#353] Received on [vcap.component.announce] : '{"type":"DEA","index":null,"uuid":"fbee5586c06e322a077369ad18cff6bf","host":"192.168.74.204:52157","credentials":["dbd7d28aff3b26bd3c018d4d141d75f0","247bb4586b7401ce963d858349808feb"],"start":"2012-08-24 10:40:19 +0200"}'
        def process_component_announcement(parsed_message, logger)
          uuid = parsed_message['uuid']
          index = parsed_message['index']

          unless index
            logger.warn "Component announce (DEA): DEA has no index: #{parsed_message.inspect}"
          end

          # we probably won't find it by UUID anyway
          dea = find_or_create_dea_by_index_or_uuid(index, uuid)

          dea.uuid        = parsed_message['uuid']
          dea.host        = parsed_message['host']
          dea.credentials = parsed_message['credentials']
          dea.started_at  = parsed_message['start']
          dea.updated_at  = Time.now
          dea.save!

          logger.debug "Component announce (DEA): #{dea.inspect} #{parsed_message.inspect}"
        end
      end

    protected
      # [#355] Received on [dea.advertise] : '{"id":"fbee5586c06e322a077369ad18cff6bf","available_memory":4096,"runtimes":["ruby19"],"prod":null}'
      def process_advertise_message(message)
        parsed_message = parse_json(message)

        uuid = parsed_message['id']
        dea = find_or_create_dea_by_uuid(uuid)

        dea.available_memory  = parsed_message['available_memory']
        dea.runtimes          = parsed_message['runtimes']
        dea.prod              = parsed_message['prod']
        dea.updated_at        = Time.now
        dea.save!

        @logger.debug "DEA advertise: #{dea.inspect} #{parsed_message.inspect}"
      end

      # [#3350] Received on [dea.heartbeat] : '{"droplets":[{"droplet":885,"version":"064f5be70794eb8759df06cc2e67f37bc562c45d-1","instance":"d401f9904e15c481b80460fc5f11a55c","index":0,"state":"RUNNING","state_timestamp":1345805016},{"droplet":1243,"version":"121e5472f17e4a47a2c80e8740c143ce0c606306-1","instance":"ffbc2a096b8e49cc3cfd8c12f3f89909","index":0,"state":"RUNNING","state_timestamp":1345805100},{"droplet":1262,"version":"59dd59cf42e4c3a5d731a745156ad13b38f5de21-1","instance":"960cee8f224b615ae1b0221fa76f8612","index":0,"state":"RUNNING","state_timestamp":1345805097},{"droplet":1264,"version":"c0574abb4db6f53144a31562e48006cba2383079-1","instance":"2c53980dcc7923037124471d6382fa07","index":0,"state":"RUNNING","state_timestamp":1345805098},{"droplet":1263,"version":"7afbd3a6555f6ab4bd9d34a56df362a06f33f12b-2","instance":"83d187ab3c488c0af4a4a9aa4100a594","index":0,"state":"RUNNING","state_timestamp":1345810067},{"droplet":1261,"version":"cc1fee42de1c09a5af9cd24d8aef5673243cc636-6","instance":"b84c1646c76a830f6a30da50361653c9","index":0,"state":"RUNNING","state_timestamp":1345810106}],"dea":"0-a3fac1a79c9a7d77f817db1d1b2a98fa","prod":null}'
      def process_heartbeat_message(message)
        parsed_message = parse_json(message)

        uuid = parsed_message['dea']
        unless dea = find_dea_by_uuid(uuid)                 # XXX find_or_create_dea_by_uuid ?
          @logger.warn "DEA #{uuid} is unknown, skipping"
          return
        end

        if uuid =~ /(\d+)-.+/ && dea.index.nil?
          index = $1
          @logger.info "Recovered index #{index} for dea #{dea.inspect}"
          dea.index = index
          dea.save
        end

        dea_prod = parsed_message['prod']

        @logger.debug "DEA heartbeat: #{parsed_message['dea']} droplets: #{parsed_message['droplets'].count}"

        parsed_message['droplets'].each do |d|
          @logger.debug "  : #{d.inspect}"
          d['_added'] = Time.now

          droplet_id      = d['droplet']
          version         = d['version']
          droplet_index   = d['index']
          state           = d['state']

          droplet = dea.droplets.find_or_create_by(:app_id => droplet_id)
          if RUNNING_STATES.include?(state)
            droplet_version = droplet.versions.find_or_create_by(:version => version)
            droplet_entry = droplet_version.entries.find_or_create_by(:index => droplet_index)

            droplet_entry.instance        = d['instance']
            droplet_entry.timestamp       = Time.now
            droplet_entry.dea_prod        = dea_prod
            droplet_entry.state           = state
            droplet_entry.state_timestamp = d['state_timestamp']
            droplet_entry.save!
          end
        end
      end

      # [#354] Received on [dea.start] : '{"id":"fbee5586c06e322a077369ad18cff6bf","ip":"192.168.74.204","port":12345,"version":0.99}'
      def process_start_message(message)
        parsed_message = parse_json(message)

        uuid = parsed_message['id']
        dea = find_or_create_dea_by_uuid(uuid)

        dea.ip          = parsed_message['ip']
        dea.port        = parsed_message['port']
        dea.version     = parsed_message['version']
        dea.updated_at  = Time.now
        dea.save!

        @logger.debug "DEA start: #{dea.inspect} #{parsed_message.inspect}"
      end

      def expire_old_droplets
        cutoff = Time.now - DROPLET_LOST

        Dea.all.each do |dea|
          @logger.debug "expire_old_droplets on #{dea.inspect}"
          dea.droplets.each do |droplet|
            droplet.versions.each do |version|
              version.entries.each do |entry|
                if entry.timestamp
                  if entry.timestamp < cutoff
                    @logger.debug "expire_old_droplets: #{entry.inspect} is old"
                    entry.destroy
                  end
                else
                  @logger.warn "expire_old_droplets: #{entry.inspect} has timestamp=nil"
                  entry.destroy
                end
              end
              version.destroy if version.entries.empty?
            end
            droplet.destroy if droplet.versions.empty?
          end
          dea.save!
        end
      end
    end
  end
end
