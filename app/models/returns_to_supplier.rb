class ReturnsToSupplier < ActiveRecord::Base
  belongs_to :supplier
  belongs_to :head_office
  belongs_to :receiving
  belongs_to :user

  has_many :returns_to_supplier_details

  scope :count_no, lambda { |x| where("extract(month from created_at) = ?", "#{x}") }
  scope :count_not, lambda { |x| where("extract(year from created_at) = ?", "#{x}") }

  accepts_nested_attributes_for :returns_to_supplier_details, reject_if: :all_blank, allow_destroy: true

  validates_uniqueness_of :receive_no, :allow_blank => true
#  validate :check_stock
#  after_create :customize_ap

  def customize_ap
    current_ap = AccountPayable.where("supplier_id=#{supplier_id} AND due_date>'#{Time.now.strftime("%Y-%m-%d")}'").order("id DESC").limit(1).first
    current_ap.update_attributes(retur_amount: current_ap.retur_amount.to_f + total.to_f, outstanding_amount: current_ap.outstanding_amount.to_f-total.to_f)
  end

  def check_stock
    returns_to_supplier_details.each{|p|
      errors.add(:quantity, " in size #{p.product.barcode} can't be more than available quantity") if p.quantity.present? && p.quantity > (ProductDetail.find_by_warehouse_id_and_product_id(head_office_id, p.product_id).available_qty.to_i rescue 0)
    }
  end

  def delivered?
    self.status=="Delivered"
  end
end
