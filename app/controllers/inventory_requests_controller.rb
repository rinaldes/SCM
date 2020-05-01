class InventoryRequestsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  def index
    get_paginated_inventory_request
  end

  def show
    @inventory_request = InventoryRequest.find(params[:id])
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(:product).group_by{|pd|pd.product_id}
    @supplier = @inventory_request.supplier
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def edit
    @inventory_request = InventoryRequest.find(params[:id])
  end

  def update
    # raise params.inspect
    @inventory_request = InventoryRequest.find(params[:id])
    if @inventory_request.update_attributes(inventory_request_params)
      flash[:notice] = 'Inventory Request was successfully updated'
      redirect_to inventory_requests_path
    else
      flash[:error] = @inventory_request.errors.full_messages
      render "new"
    end
  end

  def new
    time_now = Time.now
    @inventory_request = InventoryRequest.new date: time_now.strftime('%Y-%m-%d'), number: "#{Time.now.to_i}#{(InventoryRequest.last.id rescue 0)+1}"
    @date = time_now.strftime("%d-%m-%Y")
  end

  def create
    @inventory_request = InventoryRequest.new(
      inventory_request_params.merge(status: params[:commit] == 'Save' ? 'Draft' : InventoryRequest::WAITING_APPROVAL, requester_id: current_user.id, date: Time.now)
    )
    if @inventory_request.save
      flash[:notice] = 'Inventory Request was successfully created'
      redirect_to inventory_requests_path
    else
      flash[:error] = @inventory_request.errors.full_messages
      render "new"
    end
  end

  def add_product
    @detail = InventoryRequestDetail.new
    @detail.product = Product.find_by_id(params[:id])
    @detail.quantity = params[:quantities]
  end

  def del_product
    @detail = InventoryRequestDetail.find_by_id[params[:id]]
    @detail.product = Product.find_by_id(params[:id])
    @detail.quantity = params[:quantities]
  end


  def get_product
    @product = Product.find_by_barcode(params[:barcode])
    @office = Office.find_by_id(params[:origin_warehouse_id])
    @supplier = @product.brand.supplier
    @productdetail = ProductDetail.where("product_id=#{@product.id} and warehouse_id=#{@office.id}").first
    #find_by_product_id_and_warehouse_id
    @sellingprice = SellingPrice.where("product_id=#{@product.id} and office_id=#{@office.id}").first
    @list_product = ProductDetail.where("warehouse_id=#{params[:origin_warehouse_id] || current_user.branch_id || Branch.first.id} AND products.id=#{@product.id}")
      .joins(:product)
      .sort_by{|product_detail|
      size_number = (product_detail.product_size.size_detail.size_number rescue 1000000) || 1000000
      size_number.to_i == 0 ? size_number : size_number.to_i
    }
    respond_to do |format|
      format.js
    end
  end
  def autocomplete_inventory_request
    hash = []
    conditions = ["status IN (#{params[:status]})"]
    conditions << "number like '%#{params[:term]}%'" if params[:term].present?
    conditions << "supplier_id=#{params[:supplier_id]}" if params[:supplier_id].present?
    conditions << "number NOT IN (#{params[:present_ir]})" if params[:present_ir].present?
    @ir = InventoryRequest.where(conditions.join(' AND ')).order('number')
    @ir.collect do |p|
      hash << {
        "id" => p.id, "label" => p.number, "value" => p.number, ir_date: p.created_at.strftime('%Y-%m-%d'), ir_note: p.note, branch_name: (p.branch.office_name rescue nil),
        quantity: p.inventory_request_details.map(&:approved_qty).compact.sum
      }
    end
    respond_to do |format|
      format.js
      format.json {render json: hash}
    end
  end
  def search_in_modal
    search_product_manual
  end

  def search_product_manual
    conditions = []
    conditions << "LOWER(inventory_request_number) LIKE ('%#{params[:inventory_request_number]}%')" if params[:inventory_request_number].present?
    conditions << "LOWER(date) LIKE LOWER('%#{params[:date]}%')" if params[:date].present?
    conditions << "LOWER(status) LIKE LOWER('%#{params[:status]}%')" if params[:status].present?
    # conditions << "LOWER(description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    # conditions << "LOWER(brands.name) LIKE LOWER('%#{params[:brand_name]}%')" if params[:brand_name].present?
    # conditions << "LOWER(barcode) NOT IN (#{params[:present_product]})" if params[:present_product].present?
    @ir = InventoryRequest.where(conditions.join(' AND ')).all
  end
  def destroy
    @inventory_request= InventoryRequest.find(params[:id])
    if @inventory_request.destroy
      flash.now[:notice] = "IR was successfully deleted"
    else
      flash.now[:error] = t(:already_in_used)
    end
    get_paginated_inventory_request
    respond_to do |format|
      format.js
    end

  end

  private
    def inventory_request_params
      params.require(:inventory_request).permit(:note, :date, :number, :supplier_id, :branch_id,
                                                 inventory_request_details_attributes: [:id, :quantity, :product_id, :_destroy])
    end

    def get_paginated_inventory_request
      conditions = Array.new
      params[:search].each{|param|
        conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
      } if params[:search].present?
      @inventory_requests = InventoryRequest.where(conditions.join(' AND ')).paginate(:page => params[:page], :per_page => 10) || []
    end


end
