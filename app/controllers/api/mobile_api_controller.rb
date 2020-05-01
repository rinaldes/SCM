class Api::MobileApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_filter :check_current_user, :check_permitted_page
  skip_before_filter :protect_from_forgery
  skip_before_filter :authenticate_user!
  #before_filter :check_token, except: [:usr_login, :create_usr]

  def create_usr
    user_reg = MobileUser.api(params[:usr_crt])
    render json: {errorMessage: user_reg[0], status: user_reg[1]}, status: 201
  end

  def usr_checkout
    usr_checkout = MobileOrder.api(params[:usr_checkout])
    render json: {errorMessage: usr_checkout[0], status: usr_checkout[1], transaction_number: usr_checkout[2]}, status: 201, include: :mobile_order_details
  end

  def insert_to_cart
    insert_to_cart = MobileOrder.to_cart(params[:user_id], params[:insert_to_cart])
    render json: {errorMessage: insert_to_cart[0], status: insert_to_cart[1]}, status: 201
  end

  def change_quantity_cart
    change_qty = MobileOrder.update_cart(params[:user_id], params[:change_qty])
    render json: {errorMessage: change_qty[0], status: change_qty[1]}, status: 201
  end

  def remove_from_cart
    begin
      mobile_order = MobileOrder.find_by_member_id_and_status(params[:user_id], "Cart").id
      mobile_order_details = MobileOrderDetail.find_by_product_id_and_mobile_order_id(params[:product_id], mobile_order)
      mobile_order_details.destroy
      error = ""
      status = "success"
    rescue => e
      error = e.message
      status = "failed"
    end
    render json: {errorMessage: error, status: status}, status: 200
  end

  def check_cart
    begin
      cart = MobileOrder.find_by_member_id_and_status(params[:user_id], "Cart").mobile_order_details.joins(:product).select("mobile_order_details.*, products.description as product_name, article") rescue []
      error = ''
      status = 'success'
    rescue => e
      cart = []
      error = e.message
      status = "failed"
    end
    render json: {data: cart, errorMessage: error, status: status}, status: 200
  end

  def set_favo_item
    favo = FavoriteProduct.api(params[:favo_item])
    render json: {errorMessage: favo[0], status: favo[1]}, status: 201
  end

  def remove_favo_item
    begin
      favo = FavoriteProduct.find_by_mobile_user_id_and_product_id(params[:user_id], params[:product_id])
      favo.destroy
      error = ""
      status = "success"
    rescue => e
      error = e.message
      status = "failed"
    end
    render json: {errorMessage: error, status: status}, status: 200
  end

  def favo_item
    begin
      favorite_item = FavoriteProduct.where(mobile_user_id: params[:user_id]).joins(:product)
        .select("favorite_products.id, product_id, quantity, products.description as product_name, products.selling_price as price")
      render json: {data: favorite_item, errorMessage: '', status: 'success'}, status: 200
    rescue => e
      error_msg = e.message
      render json: {data: [], errorMessage: error_msg, status: 'failed'}, status: 200
    end
  end

  def order_history
    begin
      history = MobileOrder.where(member_id: params[:user_id]).where.not(status: "Cart").order("transaction_date DESC")
        .select("id, transaction_number, transaction_date, status")
      render json: {data: history, errorMessage: '', status: 'success'}, status: 200, include: {:mobile_order_details => {include: :product}}
    rescue => e
      render json: {data: [], errorMessage: e.message, status: 'failed'}, status: 200
    end
  end

  def set_profile
    profile = MobileUser.profile(params[:user_id], params[:set_profile])
    render json: {errorMessage: profile[0], status: profile[1]}, status: 200
  end

  def get_profile
    begin
      profile = MobileUser.find(params[:user_id])
      render json: {data: [profile], errorMessage: '', status: 'success'}, status: 200
    rescue => e
      render json: {data: [], errorMessage: e.message, status: 'failed'}, status: 200
    end
  end

  def check_stock
    begin
      conditions = []
      conditions << "product_id = #{params[:product_id]}" if params[:product_id].present?
      stock = ProductDetail.where(conditions.join(' AND ')).joins(:product, :warehouse)
        .select("product_details.id, article, barcode, products.description as product_name, warehouse_id, offices.office_name as warehouse_name, available_qty as qty").order("article")
      render json: {data: stock, errorMessage: '', status: 'success'}, status: 200
    rescue => e
      render json: {data: [], errorMessage: e.message, status: 'failed'}, status: 200
    end
  end

  def order_confirmation
    nomor_order = MobileOrder.find_by_transaction_number(params[:transaction_number])
    if nomor_order.present?
      render json: {data: [nomor_order], errorMessage: "", status: "success"}, status: 200, include: {mobile_order_details: {include: {product: {only: :description}}}}
    else
      render json: {data: [], errorMessage: "Transaction Number not Found", status: "failed"}, status: 200
    end
  end

  def order_list
    order = MobileOrder.joins(:mobile_user).where(member_id: params[:user_id]).select("mobile_orders.id, transaction_number, mobile_users.name as member_name, transaction_date, status")
    if params[:sorting].present?
      if params[:sorting] == "ASC"
         order = order.order(:transaction_date)
      else
         order = order.order(transaction_date: :desc)
      end
    end
    if order.present?
      render json: {data: [order], errorMessage: "", status: "success"}, status: 200
    else
      render json: {data: [], errorMessage: "Transaction not Found", status: "failed"}, status: 200
    end
  end

  def display_product
    category = Department.find_by_name((params[:prd_category].titlecase rescue ''))
    conditions = []
    conditions << "products.department_id = #{category.id}" if category.present?
    conditions << "LOWER(description) LIKE LOWER('%#{params[:prd_name]}%')" if params[:prd_name].present?
    conditions << "products.id IN (SELECT product_id FROM product_details WHERE available_qty>0)"
    @product = Product.joins(:m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id LEFT JOIN brands ON products.brand_id=brands.id")
    .select("products.*, departments.name as product_category").where(conditions.join(' AND '))
    if @product.present?
      render json: {data: [@product.map{|p|p.attributes.merge(selling_price: (p.product_price(Time.now).selling_price rescue 0))}], errorMessage: "", status: "success"}, status: 200
    else
      render json: {data: [], errorMessage: "Product not Found", status: "failed"}, status: 200
    end
  end

  def ads_list
    conditions = []
    conditions << "valid_from <= '#{Time.now}'"
    conditions << "valid_until >= '#{Time.now}'"
    @product = Ad.where(conditions.join(' AND ')).offset(params[:offset]).limit(params[:limit])
    if @product.present?
      render json: {data: [@product], errorMessage: "", status: "success"}, status: 200
    else
      render json: {data: [], errorMessage: "No Ads", status: "failed"}, status: 200
    end
  end

  def search_product
    conditions = []
    conditions << "LOWER(description) LIKE LOWER('%#{params[:prd_name]}%')" if params[:prd_name].present?

    @products = Product.where(conditions.join(' AND '))

    if @products.present?
      render json: {data: [@products.map{|p|p.attributes.merge(selling_price: (p.product_price(Time.now).selling_price rescue 0))}], errorMessage: "", status: "success"}, status: 200, include: :product_details
    else
      render json: {data: [], errorMessage: "Product not Found", status: "failed"}, status: 200
    end
  end

  def display_product_new
    category = Department.find_by_name((params[:prd_category].titlecase rescue ''))

    conditions = []
    conditions << "products.department_id = #{category.id}" if category.present?
    conditions << "LOWER(description) LIKE LOWER('%#{params[:prd_name]}%')" if params[:prd_name].present?

    @product = Product.joins(:m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id LEFT JOIN brands ON products.brand_id=brands.id")
     .select("products.*, departments.name as product_category").where(conditions.join(' AND '))

    page = params[:page].to_i
    limit = params[:limit].to_i
    last_id = @product.first(limit*(page-1)).last.id rescue 0
    @products = @product.where("products.id > #{last_id}").first(limit)

    if @products.present?
      render json: {data: [@products.map{|p|p.attributes.merge(selling_price: (p.product_price(Time.now).selling_price rescue 0))}], errorMessage: "", status: "success"}, status: 200
    else
      render json: {data: [], errorMessage: "Product not Found", status: "failed"}, status: 200
    end
  end

  def usr_login
    if params[:user_number].present?
      log_in = MobileUser.find_by_phone_and_password(params[:user_number], params[:user_pass])
    elsif params[:user_email].present? 
      log_in = MobileUser.find_by_email_and_password(params[:user_email], params[:user_pass])
    end
    if log_in.present?
      api_key = log_in.api_key
      log_in.update_attribute(:token_registration_id, params[:log_token_google]) if params[:log_token_google].present?
      time_now = Time.now
      api_key = ApiKey.new access_token: SecureRandom.hex, mobile_user_id: log_in.id, expired_at: time_now + 2.day unless api_key
      api_key.save
      render json: {data: [user_id: log_in.id, login_as: log_in.name, login_at: time_now.strftime("%Y-%m-%d %H:%M:%S"), token_string: api_key.access_token], errorMessage: "", status: "success"}, status: 200
    else
      render json: {data: [], errorMessage: 'Phone Number and Password does not match', status: 'failed'}, status: 200
    end
  end

  private
  def check_token
      #example params[:token]=
      access_token = ApiKey.find_by_access_token(params[:token])
      unless access_token
        render :json => {message: "Token invalid", status: 401}, status: 401
      end
    end
end
