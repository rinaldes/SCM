class PriceTagsController < ApplicationController
  layout 'application', :except => :print_to_pdf
  def index
    get_paginated_products

    newest_product_conditions = []
    newest_product_conditions << "selling_price_details.last_print IS NULL"
    newest_product_conditions << "office_id=#{current_user.branch_id}" if current_user.branch_id.present?
    newest_product_conditions << "end_date>NOW()"
    newest_product_conditions << "products.status1 = 'Active'"
    newest_product_conditions << "price>0"

    @selling = SellingPriceDetail.where(newest_product_conditions.join(' AND ')).joins(selling_price: [:office, :product])
    @sp_product = @selling.map{|s|s.selling_price.product}
  end

  def price_for_l
    if params[:barcode].present?
      if params[:article].present?
        @selling = SellingPriceDetail.select("selling_price_details.*, selling_prices.*, products.description, office_name, selling_price_details.id AS spd_id")
      .where("selling_price_details.id IN (#{params[:ids]})")
      .order(default_order('selling_prices'))
      .joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
      else
        @selling = SellingPriceDetail.select("selling_price_details.*, selling_prices.*, products.description, office_name, selling_price_details.id AS spd_id")
      .where("selling_price_details.id IN (#{params[:ids]})")
      .order(default_order('selling_prices'))
      .joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
      end
    else
      @selling = SellingPriceDetail.select("selling_price_details.*, selling_prices.*, products.description, office_name, selling_price_details.id AS spd_id")
      .where("selling_price_details.id IN (#{params[:ids]})")
      .order(default_order('selling_prices'))
      .joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
    end
  end

  def print_to_pdf
    begin
      @selling_prices = SellingPriceDetail.select("selling_price_details.*, selling_prices.*, products.description, office_name, selling_price_details.id AS spd_id")
        .where("selling_price_details.id IN (#{params[:ids]})")
        .order(default_order('selling_prices'))
        .joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
      @selling_prices.update_all("last_print=NOW(), updated_at=NOW()")
    rescue
      @selling_prices = []
    end

    respond_to do |format|
      format.html { render 'print_to_pdf_hana.html.erb', :layout => false } # your-action.html.erb
    end
  end

  def print_newest_product
    conditions = []
    conditions << "selling_price_details.last_print IS NULL"
    conditions << "office_id=#{current_user.branch_id}" if current_user.branch_id.present?
    conditions << "end_date>NOW()"
    conditions << "products.status1 = 'Active'"
    conditions << "price>0"

    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @selling_prices = SellingPriceDetail.where(conditions.join(' AND ')).joins(selling_price: [:office, :product])
    @product = @selling_prices.map{|s|s.selling_price.product}
    @selling_prices.update_all("last_print=NOW(), updated_at=NOW()")
    respond_to do |format|
        format.html { render 'print_to_pdf_hana.html.erb', :layout => false } # your-action.html.erb
    end
  end

  def get_products_to_table
    @product = Product.find(params[:product_id])
  end

  private
  def get_paginated_products
    conditions = ["price>0 AND end_date > now()"]
    conditions << "office_id=#{current_user.branch_id}" if current_user.branch_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1].gsub("'", "''")}%')" if param[1].present?
    } if params[:search].present?
    @selling_prices = SellingPriceDetail.select("selling_price_details.*, selling_prices.*, products.description, office_name, selling_price_details.id AS spd_id").where(conditions.join(' AND '))
      .order(default_order('selling_prices')).joins(selling_price: [:product, :office]).paginate(page: params[:page], :per_page => 100) || []
  end
end
