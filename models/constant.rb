class Constant
  include DataMapper::Resource

  property :id, Serial, key: true
  property :nkey, Text
  property :nvalue, Text
  property :status, Boolean

end