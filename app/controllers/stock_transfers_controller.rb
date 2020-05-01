class StockTransfersController < ApplicationController
  before_filter :can_view_stock_transfer, only: [:index, :show]
  before_filter :can_manage_stock_mutation, only: [:new, :create]
  skip_before_filter :verify_authenticity_token, only: [:destroy]

  def print_to_pdf
    @good_transfer = StockTransfer.find(params[:id])
    @list_product = StockTransferDetail.where("stock_transfer_id=#{params[:id]}")
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "PM-#{@good_transfer.number}.pdf",
      :disposition => 'attachment'
    )
  end

  def add_product
    @product = Product.find(params[:id])
    @supplier = @product.suppliers.first
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)} AND products.id=#{@product.id}").joins(:product)
    respond_to do |format|
      format.js
    end
  end

  def index
    get_paginated_good_transfers
  end

  def new
    @suppliers = Supplier.limit(7)
    @transfer = StockTransfer.new(number: "SI#{Time.now.year}#{sprintf('%06d', (StockTransfer.last.id rescue 0)+1)}")
    @products = Product.select("barcode, barcode").limit(11).order("barcode").map{|product|[product.barcode, product.barcode]}
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @transfer = StockTransfer.new(stock_transfer_params.merge(user_id: current_user.id))
    if @transfer.save
      #@transfer.generate_details(params)
      flash[:notice] = 'Inventory Issue was successfully created'
      redirect_to stock_transfers_path
    else
      @products = Product.select("barcode, barcode").limit(11).order("barcode").map{|product|[product.barcode, product.barcode]}
      flash[:error] = @transfer.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def edit
    @transfer = StockTransfer.find(params[:id])
    @list_product = StockTransferDetail.where("stock_transfer_id=#{params[:id]}")
  end

  def show
    @good_transfer = StockTransfer.find(params[:id])
    @list_product = StockTransferDetail.where("stock_transfer_id=#{params[:id]}")
  end

  def add_brand
    @product = Product.find params[:product_id]
    @list_product = ProductDetail.where(:warehouse_id => params[:origin_branch], product_size_id: @product.product_sizes.map(&:id)).order('id asc')
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @good_transfer = StockTransfer.find(params[:id])
    if @good_transfer.destroy
      get_paginated_good_transfers
    else
      flash[:error] = t(:data_already_in_used)
    end
    respond_to do |format|
      format.js
    end
  end

  def update
    @stock_transfer = StockTransfer.find(params[:id])
    if @stock_transfer.update_attributes(stock_transfer_params.merge(user_id: current_user.id))
      flash[:notice] = 'Mutation status was successfully updated.'
      redirect_to stock_transfers_path
    else
      flash[:error] = @stock_transfer.errors.full_messages.join('</br>')
      render "edit"
    end
  end

  def getsellingprice
  end

  private
    def stock_transfer_params
      params.require(:stock_transfer).permit(:date, :no_surat_jalan, :status, :effective_date, :location_id, :remark,
                                             :number, :origin_id, :destination_id, :origin_stock, :destination_stock,
                                             :old_status, :new_status, stock_transfer_details_attributes: [
                                               :id, :product_id, :quantity, :_destroy
                                             ])
    end


    def get_paginated_good_transfers
      conditions = []
      conditions << "destination_id=#{current_user.office_id}" if current_user.office_id.present?
      params[:search].each{|param|
        conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'" if param[1].present?
      } if params[:search].present?
      @stock_transfers = StockTransfer.joins(:user, :destination).select("stock_transfers.*, stock_transfers.created_at as st_created_at, office_name as location_name, concat(users.first_name, ' ', users.last_name) AS creator_name").where(conditions.join(' AND '))
        .order(default_order('stock_transfers')).paginate(:page => params[:page], :per_page => 10) || []
    end

    def can_view_stock_transfer
      not_authorized unless current_user.can_view_stock_transfer?
    end

    def can_manage_stock_mutation
      not_authorized unless current_user.can_manage_stock_mutation?
    end
end
