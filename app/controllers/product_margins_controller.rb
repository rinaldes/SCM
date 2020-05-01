class ProductMarginsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_product_margin, only: [:index, :show]
  before_filter :can_manage_product_margin, only: [:new, :create, :edit, :update]

  def index
    #@product_margins = ProductMargin.all
    get_paginated_product_margins
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data ProductMargin.all.to_csv2 }
      else
        format.csv { send_data ProductMargin.all.to_csv }
      end
    end
  end

  def new
    @product_margin = ProductMargin.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @product_margin = ProductMargin.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def create
    office = HeadOffice.find_by_office_name(params[:office])
    @product_margin = ProductMargin.new(product_margin_params.merge(:code => (('%03d' % ((ProductMargin.last.code.to_i rescue 0)+1))), product_id: (Product.find_by_barcode(params[:product]).id rescue nil)))
    if @product_margin.save
      flash[:notice] = 'Product Margin was successfully created'
      redirect_to product_margins_path
    else
      flash[:error] = @product_margin.errors.full_messages
      render "new"
    end
  end

  def update
    @product_margin = ProductMargin.find(params[:id])
    if @product_margin.update_attributes(product_margin_params)
      flash[:notice] = 'Product Margin was successfully updated.'
      redirect_to product_margins_path
    else
      flash[:error] = @product_margin.errors.full_messages
      render "edit"
    end
  end

  def destroy
    @product_margin = ProductMargin.find(params[:id])
    @product_margin.destroy
    get_paginated_product_margins
    respond_to do |format|
      format.js
    end
  end

  def import
    import_result = ProductMargin.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to product_margins_path
  end

private
  def product_margin_params
    params.require(:product_margin).permit(:start_date, :end_date, :product_id ,:margin, :office_id)
  end

  def get_paginated_product_margins
    conditions = []
    params[:search].each{|param|
      conditions << "#{param[0]} = '#{param[1]}'" if param[1].present?
    } if params[:search].present?
    @product_margins = ProductMargin.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def can_view_product_margin
    not_authorized unless current_user.can_view_product_margin?
  end

  def can_manage_product_margin
    not_authorized unless current_user.can_manage_product_margin?
  end
end
