class Dea
  include Mongoid::Document

  # static information
  field :uuid, :type => String
  field :index, :type => Integer
  field :ip, :type => String
  field :version, :type => String

  # runtime information
  field :port, :type => Integer
  field :available_memory, :type => Integer
  field :runtimes, :type => Array
  field :prod, :type => Boolean
  field :started_at, :type => DateTime
  field :updated_at, :type => DateTime

  # private
  field :host, :type => String
  field :credentials, :type => Array

  # status info
  embeds_many :droplets
end
