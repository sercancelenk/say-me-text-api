class Addresy
  include DataMapper::Resource

  property :id, Serial, key: true
  property :address, Text

  belongs_to :account

end