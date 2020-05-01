class OutStocksController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :out_stock, :name

  def index
    return not_authorized unless current_user.can_view_empty_stock?
    get_paginated_out_stocks
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @out_stock = ProductDetail.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @out_stock = OutStock.find(params[:id])
  end

  def update
    @product_detail = OutStock.find(params[:id])
    respond_to do |format|
      if @product_detail.update_attributes(params.require(:out_stock).permit(:min_stock, :rop_stock, :max_stock))
        flash.now[:notice] = 'successfully updated.'
        format.html{redirect_to out_stocks_url}
      else
        flash[:error] = @product_detail.errors.full_messages.join('<br/>')
        format.html {render :edit}
      end
    end
  end

  def destroy
    @out_stock = ProductDetail.find(params[:id])
    #if @area.check_transaction && @area.destroy
    if @out_stock.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Empty Stock"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Empty Stock. data is in use"
    end
    get_paginated_out_stocks
    respond_to do |format|
      format.js
    end
  end

  def search
    @out_stocks = ProductDetail.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @out_stock = ProductDetail.new
      format.js
    end
  end

  def get_number
    @out_stock_number = Product.number(params)
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
  def get_paginated_out_stocks
    conditions = ["(available_qty = 0 OR available_qty IS NULL) AND barcode IS NOT NULL"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @products = ProductDetail.joins(product: [:m_class])
      .select("products.*, product_details.*, m_classes.name AS m_class_name")
      .where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 100) || []
  end
end
