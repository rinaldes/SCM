class PurchasePrice < ActiveRecord::Base
  has_many :purchase_price_discounts, dependent: :destroy
  belongs_to :product
  accepts_nested_attributes_for :purchase_price_discounts, allow_destroy: true
  scope :get_hpp_disc_with_unit, ->(product, unit_id) { where("product_id = ? and unit_id = ? and end_date > now()", product, unit_id).last }
  # scope :get_hpp_disc, ->(product) { where("product_id = ? and end_date > now()", product).last }
  scope :get_hpp_disc, ->(product) { where("product_id = ? and end_date > now()", product).last.total_discount rescue 0 }
  scope :get_disc1_percent, ->(product) { where("product_id = ? and end_date > now()", product).last.purchase_price_discounts.find_by_disc_type("Disc.1").disc_percentage rescue 0 }
  scope :get_disc2_percent, ->(product) { where("product_id = ? and end_date > now()", product).last.purchase_price_discounts.find_by_disc_type("Disc.2").disc_percentage rescue 0 }
end
