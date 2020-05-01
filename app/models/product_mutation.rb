class ProductMutation < ActiveRecord::Base
  has_many :product_mutation_details, dependent: :destroy

  belongs_to :origin_warehouse, class_name: 'Office', :foreign_key => "origin_warehouse_id"
  belongs_to :destination_warehouse, class_name: 'Office', :foreign_key => "destination_warehouse_id"
  belongs_to :supplier

  before_validation :upcase_save
  after_destroy :restore_quantity

  accepts_nested_attributes_for :product_mutation_details, :allow_destroy => true

  PENDING = 'PENDING'
  RECEIVED = 'RECEIVED'

  validates :code, presence: true
  validates_presence_of [:origin_warehouse_id, :destination_warehouse_id]
  validate :check_stock, on: :create

  def check_stock
    product_mutation_details.each{|p|
      errors.add(:quantity, "of #{p.product.description} can't be more than available quantity") if p.quantity.to_i > (ProductDetail.find_by_warehouse_id_and_product_id(origin_warehouse_id, p.product_id).available_qty.to_i rescue 0)
    }
  end

  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def is_pending?
    status == PENDING
  end

  def generate_details(params)
    params[:good_transfer][:good_transfer_details_attributes].each do |detail|
      if detail[1]["quantity"].present?
        if self.good_transfer_details.build(:origin_store_id => params[:good_transfer][:origin_branch_id], :quantity => detail[1]["quantity"], :size_detail_id => detail[1]["size_detail_id"], :product_detail_id => detail[1]["product_detail_id"])
          # byebug
          origin = ProductDetail.find_by_id(detail[1]["product_detail_id"])
          origin.update(available_qty: (origin.available_qty - detail[1]["quantity"].to_i))
          destination = ProductDetail.find_by_warehouse_id_and_size_detail_id(params[:good_transfer][:destination_branch_id], detail[1]["size_detail_id"])
          destination.update(available_qty: (destination.available_qty + detail[1]["quantity"].to_i))
        end
      end
    end
  end

  def restore_quantity
    product_mutation_details.each{|pmd|
      product_detail = ProductDetail.find_by_warehouse_id_and_product_size_id(origin_warehouse_id, pmd.product_size_id)
      product_detail.update_attributes(available_qty: product_detail.available_qty+pmd.quantity)
      ProductMutationHistory.find_by_product_detail_id_and_product_mutation_detail_id(product_detail.id, pmd.id).delete
    }
  end

  def upcase_save
    self.code = code.upcase rescue nil
  end
=begin
  def goods_already_in_used?
    return true
    #goods.each{|item|return false if item.check_relation}
  end
=end
  def self.number(params)
    number = (GoodTransfer.first(:conditions => "code like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:good_transfer][:code][0]
    number = (GoodTransfer.first(:conditions => "code like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_good_transfer_id(good_transfer)
    id = (GoodTransfer.first(:conditions => "code = '#{good_transfer}' or code = '#{good_transfer}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end
end
