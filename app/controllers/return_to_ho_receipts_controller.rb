class ReturnToHoReceiptsController < ApplicationController
#  before_filter :can_view_transfer_receipt, only: [:index, :show]
#  before_filter :can_manage_mutation_receipt, only: [:accept, :mark_as_received]

  def show
    @good_transfer = ReturnsToHo.find(params[:id])
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(product_size: [:product]).group_by{|pd|pd.product_size.product_id}

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def index
    conditions = current_user.head_office_id.present? ? ["destination_warehouse_id=#{current_user.head_office_id}"] : []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
    } if params[:search].present?
    @product_receipts = ReturnsToHo.where(conditions.join(' AND ')).order(default_order('product_mutations'))
    .joins(
      "INNER JOIN offices origin ON (origin.id=product_mutations.origin_warehouse_id) INNER JOIN offices destination ON (destination.id=product_mutations.destination_warehouse_id)
      LEFT JOIN users sender ON sender.id=product_mutations.sender_id LEFT JOIN users receiver ON receiver.id=product_mutations.receiver_id
      LEFT JOIN suppliers ON suppliers.id=product_mutations.supplier_id")
    .select("product_mutations.*, destination.office_name AS destination_name, origin.office_name AS origin_name, concat(sender.first_name, ' ', sender.last_name) AS sender_name,
      suppliers.name AS supplier_name")
    .paginate(:page => params[:page], :per_page => 10) || []
  end

  def add_product
    @product = Product.find(params[:id])
    @supplier = @product.brand.supplier
    @list_product = ProductDetail.where("warehouse_id=#{current_user.branch.id} AND products.id=#{@product.id}").joins(product_size: [:product])
    respond_to do |format|
      format.js
    end
  end

  def accept_product
    @product_receipt = GoodTransfer.find params[:product_receipt_id]
    @product_details = @product_receipt.good_transfer_details.where("quantity > 0")
    @product = Product.find(params[:id])
  end

  def accept
    @good_transfer = ProductMutation.find params[:id]
    @product_mutation_details = @good_transfer.product_mutation_details
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(product_size: [:product]).group_by{|pd|pd.product_size.product_id}
  end

  def mark_as_received
    @product_receipt = ProductMutation.find params[:id]
    details = @product_receipt.product_mutation_details.where("quantity > 0").map(&:id)
    params[:good_transfer][:product_mutation_details_attributes].values.each{|a|
      detail = @product_receipt.product_mutation_details.find_by_product_size_id(a['product_size_id'])
      details = details-[detail.id] if detail.quantity.to_i == a['quantity'].to_i
    }
    @product_receipt.transfer_product_acceptance params[:good_transfer][:product_mutation_details_attributes]
    flash[:notice] = "Product Transfer Sucessfully Received"
    redirect_to return_to_ho_receipts_url
  end

  def can_view_transfer_receipt
    not_authorized unless current_user.can_view_transfer_receipt?
  end

  def can_manage_mutation_receipt
    not_authorized unless current_user.can_manage_mutation_receipt?
  end
end
