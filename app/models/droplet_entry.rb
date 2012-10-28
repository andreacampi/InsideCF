class DropletEntry
  include Mongoid::Document
  embedded_in :droplet_version
  field :instance, :type => String
  field :timestamp, :type => DateTime
  field :dea_prod, :type => Boolean
  field :state, :type => String
  field :state_timestamp, :type => DateTime
end
