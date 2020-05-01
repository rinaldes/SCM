class PurchaseOrder < ActiveRecord::Base
  has_many :purchase_order_details, dependent: :destroy
  has_many :receivings
  has_many :purchase_requests, through: :po_prs
  has_many :po_prs

  belongs_to :supplier
  belongs_to :purchase_request
  belongs_to :office, foreign_key: 'head_office_id'

  APPROVED = 'APPROVED'
  REJECTED = 'REJECTED'
  WAITING_APPROVAL = 'WAITING APPROVAL'

  accepts_nested_attributes_for :purchase_order_details, reject_if: :all_blank, allow_destroy: true

  validates :supplier_id, presence: true
  validates :head_office_id, presence: true
  validates :top, presence: true

  def send_to
    "#{office.type == 'Warehouse' ? 'Warehouse' : 'Store'}: #{office.office_name}, #{office.address}"
  end

  def self.to_csv3(options = {}, pds)
    CSV.generate(options) do |csv|
      csv << ['no', 'article', 'description', 'BARCODE (INNER BOX)','ORDER QTY','PRICE PER PCS','TOTAL VALUE (RP)']
      pds.each_with_index do |product, i|
        csv << [i+1, product.article, product.description, "#{product.barcode}", '']
      end
    end
  end

  # def import(file)
  #   line = 0
  #   barcodes = []
  #   total = 0
  #   CSV.foreach(file.path, headers: true) do |row|
  #     params = row.to_hash
  #     total += params['ORDER QTY'].to_i
  #     product = Product.find_by_article(params['article']) || Product.find_by_barcode(params['BARCODE (INNER BOX)'])

  #     if product.blank?
  #       barcodes << params['BARCODE (INNER BOX)']
  #     else
  #       PurchaseOrderDetail.create! purchase_order_id: id, product_id: product.id,
  #         total_price: (params['ORDER QTY'].to_f*product.product_price(Time.now).hpp), quantity: params['ORDER QTY'], unit_type: 'Unit',
  #         hpp: product.product_price(Time.now).hpp, fraction: 1
  #     end
  #   end
  #   self.update_attributes(total_qty: total, grand_total: purchase_order_details.map(&:total_price).sum)
  #   return barcodes.join(', ')
  # end

  def import(file)
    line = 0
    barcodes = []
    total = 0
    CSV.foreach(file.path, headers: true) do |row|
      params = row.to_hash
      total += params['ORDER QTY'].to_i
      product = Product.find_by_article(params['article']) || Product.find_by_barcode(params['BARCODE (INNER BOX)'])
      if product.blank?
        barcodes << params['BARCODE (INNER BOX)']
      else
        PurchaseOrderDetail.create purchase_order_id: id, product_id: product.id,
          total_price: (row.to_hash['TOTAL VALUE (RP)'].gsub(',', '').to_f rescue (params['ORDER QTY'].to_f*params['PRICE PER PCS'].gsub(',', '').to_f)),
          quantity: params['ORDER QTY'], unit_type: 'Unit',
          hpp: params['PRICE PER PCS'].gsub(',', '').to_f, fraction: 1
      end
    end
    self.update_attributes(total_qty: total, grand_total: purchase_order_details.map(&:total_price).sum)
    return barcodes.join(', ')
  end

  def is_waiting_approval?
    status == WAITING_APPROVAL
  end
end
