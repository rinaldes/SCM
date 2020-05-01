class Companyprofile < ActiveRecord::Base
  belongs_to :entity
  attr_accessor :logo, :favicon
  mount_uploader :logo, LogoUploader
  mount_uploader :favicon, LogoUploader
end
