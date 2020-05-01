class Entity < ActiveRecord::Base
  mount_uploader :logo, LogoUploader
  mount_uploader :favicon, LogoUploader
  has_one :companyprofile
end
