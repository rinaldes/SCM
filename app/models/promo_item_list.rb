class PromoItemList < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :m_class
  belongs_to :brand
  belongs_to :department
  belongs_to :product

  before_save :min_qty_1

  def min_qty_1
    if self.promotion.promotion_type == "Discount Period"
      self.min_qty = 1
    end
  end
end