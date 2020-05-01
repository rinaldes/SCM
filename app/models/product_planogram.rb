class ProductPlanogram < ActiveRecord::Base
  belongs_to :planogram
  belongs_to :product
end
