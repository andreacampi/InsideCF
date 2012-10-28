class App
  include Mongoid::Document

  # basic info
  field :app_id, :type => Integer
  field :owner_id, :type => Integer
  field :name, :type => String                  # glossy
  field :original_name, :type => String         # glossy---123

  # transient
  field :staged_package_hash, :type => String

  # complete response
  field :extra, :type => Hash
end
