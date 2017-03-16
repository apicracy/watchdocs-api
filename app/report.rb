require 'mongoid'
Mongoid.load!('mongoid.yml')

class Report
  include Mongoid::Document
  field :project_id, type: Integer
  field :endpoint, type: String
  field :created_at, type: DateTime
  field :requests, type: Array
end



