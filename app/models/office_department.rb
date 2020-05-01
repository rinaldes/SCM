class OfficeDepartment < ActiveRecord::Base
  belongs_to :office
  belongs_to :department
end
