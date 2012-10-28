class Droplet
  include Mongoid::Document
  embedded_in :dea
  field :app_id, :type => Integer
  embeds_many :versions, :class_name => 'DropletVersion'
end
