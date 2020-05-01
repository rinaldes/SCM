class CancelItem < ActiveRecord::Base
  belongs_to :product_detail
  belongs_to :store, class_name: 'Office'
  belongs_to :user
end