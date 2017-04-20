class Project
  include Mongoid::Document
  field :app_id, type: String
  field :app_secret, type: String

  def self.authorize(app_id, app_secret)
    find_by(
      app_id: app_id,
      app_secret: app_secret
    )
  rescue Mongoid::Errors::DocumentNotFound
    nil
  end
end
