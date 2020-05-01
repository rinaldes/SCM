class SupplierDepartment < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :department
end
