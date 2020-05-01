class MobileUser < ActiveRecord::Base
  has_one :api_key
  has_many :favorite_product
  has_many :product, :through => :favorite_product
  
  validates :phone, :presence => {message: 'required'}, :uniqueness => true
  validates :email, :uniqueness => true, allow_blank: true
  validates :name, :presence => {message: 'required'}
  validates :password, :presence => {message: 'required'}
  
  def self.api(params)
    begin
      ActiveSupport::JSON.decode(params).each do |cr|
        mobile_user = self.new()
        mobile_user.name = cr["usr_full_name"]
        mobile_user.email = cr["usr_email"]
        mobile_user.password = cr["usr_pass"]
        mobile_user.phone = cr["usr_phone"]
        mobile_user.token_registration_id = cr["token_registration_id"]
        mobile_user.save!
      end
      error = ""
      status = "success"
    rescue => e
      error = e.message
      status = "failed"
    end
    return error, status
  end  

  def self.profile(user_id, params)
    begin
      ActiveSupport::JSON.decode(params).each do |cr|
        mobile_user = MobileUser.find(user_id)
        mobile_user.name = cr["usr_full_name"]
        mobile_user.password = cr["usr_pass"]
        mobile_user.phone = cr["usr_phone"]
        mobile_user.email = cr["usr_email"]
        mobile_user.jenis_kelamin = cr["usr_gender"]
        mobile_user.alamat = cr["usr_address"]
        mobile_user.save
      end
      error = ""
      status = "success"
    rescue => e
      error = e.message
      status = "failed"
    end
    return error, status
  end

end