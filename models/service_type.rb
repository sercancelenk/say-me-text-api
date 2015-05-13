class ServiceType
  include DataMapper::Resource

  property :id, Serial, key: true
  property :name, Text
  property :description, Text
  property :price, Float
  property :created_date, DateTime
  property :totalcredit, Integer

  has n, :payment

end