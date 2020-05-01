class PrizeList < ActiveRecord::Base
  belongs_to :promotion
  belongs_to :m_class
  belongs_to :brand
  belongs_to :department
  belongs_to :product

  after_create :set_available_qty

  def set_available_qty
    self.update_attributes available_qty: max_qty
  end
end