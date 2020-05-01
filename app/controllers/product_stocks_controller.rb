class ProductStocksController < ApplicationController
 skip_before_filter :verify_authenticity_token, only: [:destroy]
 autocomplete :productstock, :product_detail_id


  # GET /colours
  # GET /colours.json
  def index
    # get_paginated_colours
    get_paginated_product_stocks
    #@product_stocks = ProductStock.all
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data ProductStock.all.to_csv2 }
      else
        format.csv { send_data ProductStock.all.to_csv }
      end
    end
  end

  def import
    import_result = ProductStock.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to product_stocks_path
  end

  def show
    @product_stock = ProductStock.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @product_stock = ProductStock.new(params[:productstock])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /colours/1/edit
  def edit
    @product_stock = ProductStock.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /colours
  # POST /colours.json
  def create
    #init = params[:stock][:stock_type][0]
    #colour_number = ProductStock.create_number(params)
    @product_stock = ProductStock.new(productstock_params)
    #merge(product_detail_id: (ProductDetail.find_by_id(params[:product_detail_id]).id rescue nil)))
    if @product_stock.save
      flash[:notice] = 'Product Stock was successfully created'
      redirect_to product_stocks_path
    else
      flash[:error] = @product_stock.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  # PUT /colours/1
  # PUT /colours/1.json
  def update
    @product_stock = ProductStock.find(params[:id])
    if @product_stock.update_attributes(productstock_params)
      flash[:notice] = 'Product Stock was successfully updated'
      redirect_to product_stocks_path
    else
      flash[:error] = @product_stock.errors.full_messages.join('<br/>')
      # format.js
      render "edit"
    end
  end

  # DELETE /colours/1
  # DELETE /colours/1.json
  def destroy
    @product_stock = ProductStock.find(params[:id])
    if @product_stock.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Product Stock"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Product Stock. data in used"
    end
    get_paginated_product_stocks    
    respond_to do |format|
      format.js
    end
  end

  def search
    @product_stock = ProductStock.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @product_stock = ProductStock.new
      format.js
    end
  end

  def get_number
    #@colour_number = Colour.number(params)
    respond_to do |format|
      format.js
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end
 
private
  def productstock_params
    params.require(:product_stock).permit(:product_detail_id, :stock, :stock_type)
  end

  def can_view_colour
    not_authorized unless current_user.can_view_colour?
  end

  def can_manage_colour
    not_authorized unless current_user.can_manage_colour?
  end
end
