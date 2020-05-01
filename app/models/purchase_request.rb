class PurchaseRequest < ActiveRecord::Base
  has_many :purchase_request_details, :dependent => :destroy

  belongs_to :supplier
  belongs_to :branch
  belongs_to :purchase_order

  accepts_nested_attributes_for :purchase_request_details, reject_if: :all_blank, allow_destroy: true

  WAITING_APPROVAL = 'WAITING APPROVAL'
  TRANSFER_ON_PROGRESS = 'TRANSFER ON PROGRESS'
  APPROVED = 'APPROVED'

  def is_waiting_approval?
    status == WAITING_APPROVAL
  end

  def self.get_number(time_now)
    "PR/branch/supplier/#{time_now.strftime("%Y-%m-%d")}/#{
      sprintf('%06d',
        (PurchaseRequest.where("extract(year from date) = ? and extract(month from date) = ?", time_now.strftime("%Y"), time_now.strftime("%m")).last.number.split('-')[1].to_i rescue 0) + 1)
    }"
  end

  def self.initialize_pbrop
    Branch.all.each do |branch|
      pbrop = ProductDetail.where(
        "available_qty <= rop_stock AND status1='Active' AND
        product_id IN (SELECT product_id FROM planos)").joins(:product)
        .where(warehouse_id: branch.id)
      generate_pbrop(pbrop, branch.id) if pbrop.present?
    end
  end

  def self.generate_pbrop(arr, branch_id)
    total_hpp = 0

    arr.each do |pbrop|
      qty_on_order = PurchaseOrderDetail.where("purchase_order_id NOT IN (SELECT purchase_order_id FROM receivings) AND purchase_orders.status='APPROVED' and product_id = #{pbrop.product_id}").joins(:purchase_order).first.quantity rescue 0

      qty_now = (pbrop.max_stock - pbrop.available_qty - qty_on_order rescue 0)
      total_hpp = total_hpp + (SellingPrice.where("product_id= #{pbrop.product_id} AND
                                            now() BETWEEN start_date AND end_date AND
                                            office_id=#{branch_id}").first.hpp * qty_now rescue 0)
    end

    PurchaseRequest.create(
      [number: "PR/#{Branch.find(arr.first.warehouse_id).office_name}/#{Time.now.strftime('%Y-%m-%d')}/#{(('%07d' % (((PurchaseRequest.where("extract(YEAR FROM date)=#{Time.now.year}").order("id DESC").limit(1)[0].number.last.to_i rescue 0) +1))))}/AUTO",
      date: Date.today,
      grand_total: total_hpp,
      branch_id: arr.first.warehouse_id,
      status: PurchaseRequest::WAITING_APPROVAL
      ])

    arr.each do |pbrop|
      qty_on_order = PurchaseOrderDetail.where("purchase_order_id NOT IN (SELECT purchase_order_id FROM receivings) AND purchase_orders.status='APPROVED' and product_id = #{pbrop.product_id}").joins(:purchase_order).first.quantity rescue 0

      qty_now = (pbrop.max_stock - pbrop.available_qty - qty_on_order rescue 0)
      PurchaseRequest.last.purchase_request_details.create([product_id: pbrop.product_id,quantity: qty_now ]) if qty_now > 0
    end
  end
end
