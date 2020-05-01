class ProductReceiptsController < ApplicationController
  before_filter :can_view_transfer_receipt, only: [:index, :show]
  before_filter :can_manage_mutation_receipt, only: [:accept, :mark_as_received]

  def index
    conditions = current_user.branch_id.present? ? ["destination_warehouse_id=#{current_user.branch_id}"] : []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
    } if params[:search].present?
    @product_receipts = GoodTransfer.where(conditions.join(' AND ')).order(default_order('product_mutations'))
    .joins(
      "INNER JOIN offices origin ON (origin.id=product_mutations.origin_warehouse_id) INNER JOIN offices destination ON (destination.id=product_mutations.destination_warehouse_id)
      LEFT JOIN users sender ON sender.id=product_mutations.sender_id LEFT JOIN users receiver ON receiver.id=product_mutations.receiver_id")
    .select("product_mutations.*, destination.office_name AS destination_name, origin.office_name AS origin_name, concat(sender.first_name, ' ', sender.last_name) AS sender_name")
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

  def print_to_pdf
    @product_mutation = ProductMutation.find params[:id]
    #tables = [['BARCODE', 'DESCRIPTION', 'QUANTITY']]
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "PM-#{@product_mutation.code}.pdf",
      :disposition => 'attachment'
    )
    # @product_mutation.product_mutation_details.each{|pmd|
    #   product = pmd.product
    #   tables << [
    #     product.barcode, product.description, pmd.quantity
    #   ]
    # }
    # Prawn::Document.generate("#{Rails.root.to_s}/public/ActiveLicense.pdf") do |pdf|
    #   pdf.text "<b>MUTASI BARANG</b>", :style => :normal, :inline_format => true, :align => :center
    #   pdf.move_down(7)
    #   pdf.text "Transfer Date            : #{@product_mutation.mutation_date.strftime('%d-%m-%Y')}", :style => :normal, :inline_format => true
    #   pdf.move_down(7)
    #   pdf.text "No. Transfer Barang  : #{@product_mutation.code}", :style => :normal, :inline_format => true
    #   pdf.move_down(7)
    #   pdf.text "Dari                           : #{@product_mutation.origin_warehouse.office_name}", :style => :normal, :inline_format => true
    #   pdf.move_down(7)
    #   pdf.text "Tujuan                       : #{@product_mutation.destination_warehouse.office_name}", :style => :normal, :inline_format => true
    #   pdf.text "\n"
    #   pdf.table tables
    #   pdf.text "\n"
    #   send_data pdf.render, :type => "application/pdf", :filename => "Product Mutation #{@product_mutation.code}.pdf"
    # end
  end

  def show
    @good_transfer = GoodTransfer.find(params[:id])
    @offices = current_user.offices
    @products = Product.select("barcode, barcode").limit(11).order("barcode").map{|product|[product.barcode, product.barcode]}
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{:product_id}
    @product_mutation_details = @good_transfer.product_mutation_details
  end

  def accept_product
    @product_receipt = GoodTransfer.find params[:product_receipt_id]
    @product_details = @product_receipt.good_transfer_details.where("quantity > 0")
    @product = Product.find(params[:id])
  end

  def accept
    @good_transfer = GoodTransfer.find params[:id]
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(:product).group_by{|pd|pd.product_id}
  end

  def mark_as_received
    qty = []
    params[:product_mutation][:product_mutation_details_attributes].each do |rqty|
      qty << rqty[1][:received_qty]
    end
    @product_receipt = ProductMutation.find params[:id]
    # details = @product_receipt.product_mutation_details.where("quantity > 0").map(&:id)
    @product_receipt.product_mutation_details.each_with_index{|a,i|
        a.update_attributes(received_qty: qty[i])
        a.product_received_by_destination_branch
    }
    @product_receipt.update_attributes(
      status: ProductMutation::RECEIVED,
      received_date: Date.today,
      total_quantity: @product_receipt.product_mutation_details.sum(:received_qty)
    )
    flash[:notice] = "Product Transfer Sucessfully Received"
    redirect_to product_receipts_url
  end

  def can_view_transfer_receipt
    not_authorized unless current_user.can_view_transfer_receipt?
  end

  def can_manage_mutation_receipt
    not_authorized unless current_user.can_manage_mutation_receipt?
  end
end
