class PurchasePricesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  helper :purchase_prices
  def index
    get_paginated_purchase_prices

    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @purchase_price = PurchasePrice.new
    2.times do @purchase_price.purchase_price_discounts.build end
    # @purchase_price.purchase_price_discounts.build
  end

  def create
    @purchase_price = PurchasePrice.new(purchase_price_params)
    if @purchase_price.save
      flash[:notice] = "Purchase Price created."
      redirect_to purchase_prices_path
    else
      render 'new'
    end
  end

  def show
    @purchase_price = PurchasePrice.find(params[:id])
  end

  def edit
    @purchase_price = PurchasePrice.find(params[:id])
  end

  def update
    @purchase_price = PurchasePrice.find(params[:id])
    if @purchase_price.update_attributes(purchase_price_params)
      redirect_to purchase_prices_path
    else
      render 'edit'
    end
  end

  def destroy
    @purchase_price = PurchasePrice.find(params[:id])
    @purchase_price.destroy!
    flash[:notice] = 'Success Remove Purchase Price'
    get_paginated_purchase_prices
  end

  def get_paginated_purchase_prices
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @purchase_prices = PurchasePrice.where(conditions.join(' AND ')).joins(:product).paginate(:page => params[:page], :per_page => 10) || []
  end


  private

  def purchase_price_params
    params.require(:purchase_price).permit(:start_date, :end_date, :product_id,
      :total_discount, :total_unit_cost, :total_price_cost, :price, :unit_id,
      :purchase_price_discounts_attributes => [:disc_rules,:disc_type,
        :disc_percentage, :disc_amount]
    )
  end
end
