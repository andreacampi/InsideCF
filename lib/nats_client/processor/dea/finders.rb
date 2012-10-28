class NatsClient
  module Processor
    class DEA
      module Finders

      protected
        def find_dea_by_uuid(uuid)
          Dea.where(:uuid => uuid).first
        end

        def find_or_create_dea_by_uuid(uuid)
          unless dea = find_dea_by_uuid(uuid)
            dea = Dea.new(:uuid => uuid)
          end
          dea
        end

        def find_or_create_dea_by_index(index)
          unless dea = Dea.where(:index => index).first
            dea = Dea.new(:index => index)
          end
          dea
        end

        def find_or_create_dea_by_index_or_uuid(index, uuid)
          if index
            find_or_create_dea_by_index(index)
          else
            find_or_create_dea_by_uuid(uuid)
          end
        end
      end
    end
  end
end
