class GoodTransferDetail < ActiveRecord::Base
	JOIN = ''
  ORDER = 'good_transfer_details.id'
  SELECTED = 'good_transfer_details.*'
  GROUP_BY = 'good_transfer_details.id'

  belongs_to :good_transfer
  belongs_to :product_size

  after_create :update_quantity

  after_destroy :restore_quantity

  #before_destroy :goods_already_in_used?

  #has_many :goods, class_name: "Goods", dependent: :destroy

  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def restore_quantity
    product = Product.find_by_barcode(barcode)
    size_detail = SizeDetail.find_by_size_id_and_size_number(product.size_id, size)
    product_detail = ProductDetail.find_by_product_id_and_size_detail_id(product.id, size_detail.id)
    product_detail.update_attributes(available_qty: product_detail.available_qty+quantity)
  end

  def update_quantity
    product_detail = product_size.product_details.find_by_warehouse_id(good_transfer.origin_branch_id)
    if product_detail.present? && quantity.to_i > 0
      new_quantity = product_detail.available_qty.to_i-quantity.to_i
      ProductMutation.create product_detail_id: product_detail.id, old_quantity: product_detail.available_qty, moved_quantity: quantity, new_quantity: new_quantity,
        mutation_type: 'Transfer Barang', mutation_id: id, quantity_type: 'available_qty'
      product_detail.update_attributes(available_qty: new_quantity)
    end
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
    number = (GoodTransferDetail.first(:conditions => "code like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:good_transfer_detail][:code][0]
    number = (GoodTransferDetail.first(:conditions => "code like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_good_transfer_detail_id(good_transfer_detail)
    id = (GoodTransferDetail.first(:conditions => "code = '#{good_transfer_detail}' or code = '#{good_transfer_detail}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end
end
