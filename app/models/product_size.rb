class ProductSize < ActiveRecord::Base
  belongs_to :size_detail
  belongs_to :product

  has_many :product_details

  accepts_nested_attributes_for :product_details, reject_if: :all_blank, allow_destroy: true
  attr_accessor :minimum_stock

  after_create :generate_product_details

#  validate :check_min_stock

  def check_min_stock
    errors.add(:ProductDetails, " min_stock required") if product_details.blank?
  end

  def generate_product_details
    Office.all.each{|office|
      ProductDetail.where(product_size_id: id, warehouse_id: office.id, min_stock: 7).first_or_create
    }
  end
end
