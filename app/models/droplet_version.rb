class DropletVersion
  include Mongoid::Document
  embedded_in :droplet
  field :version, :type => String
  embeds_many :entries, :class_name => 'DropletEntry'
end
