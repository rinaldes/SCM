class SellingPricesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
#  before_filter :can_view_selling_price, only: [:index, :show]
#  before_filter :can_manage_selling_price, only: [:new, :create]

  def index
    get_paginated_selling_prices
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data SellingPrice.to_csv2 }
      else
        format.csv { send_data @selling_prices.to_csv }
      end
    end
  end

  def fitur_filter
    if params[:fitur_filter] == "current"
      conditions = ["end_date > now()"]
      conditions << "offices.is_active = true"
      @selling_prices = SellingPriceDetail.select("selling_prices.*, selling_price_details.*, products.description, offices.office_name, article, barcode").where(conditions.join(' AND '))
       .order(default_order('selling_prices')).joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
    elsif params[:fitur_filter] == "history"
      conditions = ["end_date < now()"]
      conditions << "offices.is_active = true"
      @selling_prices = SellingPriceDetail.select("selling_prices.*, selling_price_details.*, products.description, offices.office_name, article, barcode").where(conditions.join(' AND '))
       .order(default_order('selling_prices')).joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
    else
      @selling_prices = SellingPriceDetail.select("selling_prices.*, selling_price_details.*, products.description, offices.office_name, article, barcode").where("offices.is_active = true")
     .order(default_order('selling_prices')).joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
    end
  end

  def import
    begin
      if params[:commit] == 'Reset Product Per Store'
        import_result = SellingPrice.reset_product_per_store(params[:file])
      else
        import_result = SellingPrice.import(params[:file])
      end
      if params[:file].present?
        if import_result[:error] == 1
          flash[:error] = import_result[:message]
        else
          flash[:notice] = import_result[:message]
        end
      else
        flash[:error] = "Please attach CSV File"
      end
    rescue
        flash[:error] = "Failed import. Please recheck CSV File"
    end
    redirect_to selling_prices_path
  end

  def show
    @selling_price = SellingPrice.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
  @margins = ProductMargin.all
  @selling_price = SellingPrice.new(params[:selling_price])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def edit
    @selling_price = SellingPrice.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def create
    sp = Hash.new
    sp = params[:selling_price]
    save = nil

    product = Product.find_by_barcode(params[:product]) || Product.find_by_article(params[:product])
    sku = Sku.find_by_product_id_and_barcode(product.id, product.barcode) || Sku.find_by_product_id(product.id)
    if (params[:selling_price][:hpp_average].to_f rescue 0) == 0
      hpp_ave = params[:selling_price][:hpp]
    else
      hpp_ave = params[:selling_price][:hpp_average]
    end
    begin
      params[:selling_price][:office_id].each{|branch|
        @selling_price = SellingPrice.new(
          selling_price_params.merge(code: (('%03d' % ((SellingPrice.last.code.to_i rescue 0)+1))), product_id: (product.id rescue nil), office_id: branch, branch_id: branch, hpp_average: hpp_ave)
        )
        if @selling_price.save
          SellingPriceDetail.create selling_price_id: @selling_price.id, sku_id: sku.id, price: @selling_price.selling_price, id: (SellingPriceDetail.last.id+1 rescue 1)
          if params[:selling_price_middle].present?
            SellingPriceDetail.create selling_price_id: @selling_price.id, sku_id: Sku.find_by_barcode(product.box_barcode).id, price: params[:selling_price_middle], id: (SellingPriceDetail.last.id+1 rescue 1)
          end
          if params[:selling_price_high].present?
            SellingPriceDetail.create selling_price_id: @selling_price.id, sku_id: Sku.find_by_barcode(product.box2_barcode).id, price: params[:selling_price_high], id: (SellingPriceDetail.last.id+1 rescue 1)
          end
          SellingPrice.where("product_id=#{product.id} AND id!=#{@selling_price.id} AND end_date>'#{@selling_price.start_date}' AND branch_id=#{branch}")
            .update_all("end_date='#{((@selling_price.start_date || Time.now)-1.days).strftime('%Y-%m-%d')}', updated_at=NOW()")
          save = true
        end
      }
    rescue
    end
    if save
      flash[:notice] = 'Selling Price was successfully created.'
      redirect_to selling_prices_path
    else
      flash[:error] = @selling_price.errors.full_messages
      render "new"
    end
  end


  def update
    @selling_price = SellingPrice.find(params[:id])
    if @selling_price.update_attributes(selling_price_params)
      flash[:notice] = 'Selling Price was successfully updated.'
      redirect_to selling_prices_path
    else
      flash[:error] = @selling_price.errors.full_messages
      render "edit"
    end
  end

  def destroy
    @selling_price = SellingPrice.find(params[:id])
    @selling_price.destroy
    get_paginated_selling_prices
    respond_to do |format|
      format.js
    end
  end

  def search
    @selling_price = SellingPrice.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @selling_price = SellingPrice.new
      format.js
    end
  end

  def search_in_modal
    search_product_manual
  end

  def search_product_manual
    conditions = []
    conditions << "LOWER(suppliers.code) LIKE LOWER('%#{params[:supplier_code]}%')" if params[:supplier_code].present?
    conditions << "LOWER(article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    conditions << "LOWER(barcode) LIKE LOWER('%#{params[:barcode]}%')" if params[:barcode].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(brands.name) LIKE LOWER('%#{params[:brand]}%')" if params[:brand].present?
    @products = Product.where(conditions.join(' AND '))
      .joins("LEFT JOIN product_suppliers ON products.id=product_suppliers.product_id LEFT JOIN contact_people ON product_suppliers.contact_person_id=contact_people.id LEFT JOIN suppliers ON contact_people.supplier_id=suppliers.id").paginate(page: params[:page], :per_page => 10) || []
    @offices = params[:offices].split(",") if params[:offices].present?
  end

  def get_number
    @selling_price = SellingPrice.number(params)
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
  def selling_price_params
    params.require(:selling_price).permit(:start_date, :end_date, :product_id ,:margin, :hpp, :hpp_2, :hpp_average, :dpp, :ppn_in, :ppn_out, :office_id, :margin_amount, :margin_percent, :selling_price,
      :selling_price_middle, :selling_price_high)
  end

  def get_paginated_selling_prices
    conditions = []
    conditions << "end_date > now()" if params[:fitur_filter] == "current"
    conditions << "end_date < now()" if params[:fitur_filter] == "history"
    conditions << "office_id=#{current_user.branch_id}" if current_user.branch_id.present?
    conditions << "offices.is_active = true"

    params[:search].each{|param|
      if param[0] == 'barcode' && param[1].include?(' ')
        conditions << "barcode IN ('#{param[1].split( ).join("','")}')"
      else
        conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
      end
    } if params[:search].present?
    if (params[:format].present? && %w(csv xls).include?(params[:format]))
      @selling_prices = SellingPriceDetail.select("selling_prices.*, selling_price_details.*, products.description, offices.office_name, article, barcode").where(conditions.join(' AND '))
        .order(default_order('selling_prices')).joins(selling_price: [:product, :office])
    else
      @selling_prices = SellingPriceDetail.select("selling_prices.*, selling_price_details.*, products.description, offices.office_name, article, barcode").where(conditions.join(' AND '))
        .order(default_order('selling_prices')).joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
   end
  end

  def can_view_selling_price
    not_authorized unless current_user.can_view_selling_price?
  end

  def can_manage_selling_price
    not_authorized unless current_user.can_manage_selling_price?
  end

end
