class ApiKey < ActiveRecord::Base

  before_create :generate_access_token
  belongs_to :user
  belongs_to :mobile_user

  def create_access_token
    begin
      self.access_token = SecureRandom.hex
      self.expired_at = Time.now + 2.day
    end while self.class.exists?(access_token: access_token)
  end

  def generate_access_token
    begin
      self.access_token = SecureRandom.hex
      self.expired_at = Time.now + 2.day
    end while self.class.exists?(access_token: access_token)
  end

  def checking_access_token
  	generate_access_token
  	self.update_attributes(:access_token => self.access_token)
  end
end
