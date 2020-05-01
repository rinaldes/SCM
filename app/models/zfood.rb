class Zfood < ActiveRecord::Base
  belongs_to :product_detail
  has_many :zfood_details
end
