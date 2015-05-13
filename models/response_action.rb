class ResponseAction
  include DataMapper::Resource

  property :id, Serial, key: true
  property :request_id, Text
  property :response_text, Text
  property :valid, Boolean
  property :error, Boolean
  property :error_message, Text
  property :success_message, Text
  property :response_time_second, Integer
  property :created_date, Time
  belongs_to :request_action
  belongs_to :account
end