class Payment
  include DataMapper::Resource

  property :id, Serial, key: true

  belongs_to :account
  belongs_to :service_type
  property :servicetoken, Text
  property :paymentstatus, Text
  property :remainingcredit, Integer
  property :created_date, Time


end