class ProductDetail < ActiveRecord::Base
  belongs_to :product_size
  belongs_to :warehouse, class_name: 'Office', foreign_key: 'warehouse_id'
  before_save :set_warehouse

  validates :min_stock, :presence => true
  validates_format_of :min_stock, :with => /^[0-9\s]*$/i, :multiline => true, :message => "masukkan bilangan bulat saja"


  CATALOG = 1
  NON_CATALOG = 2
  ONLINE = 3

  def set_warehouse
    #self.warehouse_id = HeadOffice.first.id if self.warehouse_id.blank?
  end
end
