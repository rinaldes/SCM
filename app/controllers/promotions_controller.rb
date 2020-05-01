class PromotionsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :promotion, :name
  before_filter :can_view_promo, only: [:index, :show]
  before_filter :can_manage_promo, only: [:new, :create, :edit, :update, :destroy]

  def index
    get_paginated_promotions
    respond_to do |format|
      format.html
      format.js
    end
  end

  def search_in_modal
    search_product_manual
  end

  def search_product_manual
    @key = params[:key]

    conditions = []
    conditions << "LOWER(suppliers.code) LIKE LOWER('%#{params[:supplier_code]}%')" if params[:supplier_code].present?
    conditions << "LOWER(article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    if params[:barcode].present?
      if params[:barcode].include?(" ")
        conditions << "LOWER(barcode) IN ('%#{params[:barcode].gsub(' ', "','")}%')"
      else
        conditions << "LOWER(barcode) LIKE LOWER('%#{params[:barcode]}%')"
      end
    end
    conditions << "LOWER(description) LIKE LOWER('%#{params[:description].gsub("'", "''")}%')" if params[:description].present?
    conditions << "LOWER(brands.name) LIKE LOWER('%#{params[:brand_name]}%')" if params[:brand_name].present?
    conditions << "LOWER(barcode) NOT IN (#{params[:present_product]})" if params[:present_product].present?
    @products = Product.where(conditions.join(' AND '))
      .joins("LEFT JOIN product_suppliers ON products.id=product_suppliers.product_id LEFT JOIN suppliers ON product_suppliers.supplier_id=suppliers.id").paginate(page: params[:page], per_page: 10) || []
  end

  def get_product
    @key = params[:key]
    @product = Product.find(params[:product_id])
    respond_to do |format|
      format.js
    end
  end

  def add_prize_list
    load_master
    respond_to do |format|
      format.js
    end
  end

  def add_promo_item_list
    load_master
    respond_to do |format|
      format.js
    end
  end

  def load_master
    load_departments
    @depart = Department.limit(7).order('name').map(&:name)
    @mclass = MClass.limit(7).order('name').map(&:name)
    @brand = Brand.limit(7).order('name').map(&:name)
    @m_classes = MClass.where("parent_id IS NOT NULL")
    @brands = Brand.all
  end

  def show
    @promotion = Promotion.find(params[:id])
    @store_name = @promotion.office.office_name
    respond_to do |format|
      format.html
    end
  end

  def new
    @promotion = Promotion.new(params[:promotion])
    @promotion.promo_item_lists.build
    @promotion.prize_lists.build
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /promotions/1/edit
  def edit
    @promotion = Promotion.find(params[:id])
    load_master
    respond_to do |format|
      format.html
    end
  end

  # POST /promotions
  # POST /promotions.json
  def create
    if params[:promotion][:promotion_type] == "Discount Period" || params[:promotion][:promotion_type] == "Happy Hour"
      params[:promotion][:promo_item_lists_attributes] = params[:promotion][:prize_lists_attributes]
    end
    params[:promotion][:office_id].each do |poid|
      @promotion = Promotion.create(promotion_params.merge(
        code: (('%03d' % ((Promotion.last.code.to_i rescue 0)+1))),
        office_id: poid
        )
      )
      @promotion.promo_item_lists.update_all(start_time: params[:start_time].to_datetime, end_time: params[:end_time].to_datetime)
    end
    respond_to do |format|
      if @promotion.valid?
        flash[:notice] = t(:successfully_created)
      else
        load_master
        flash[:error] = @promotion.errors.full_messages.join('<br/>')
      end
      format.js
    end
  end

  # PUT /promotions/1
  # PUT /promotions/1.json
  def update
    @promotion = Promotion.find(params[:id])
    old_prize_lists = PrizeList.where(promotion_id: @promotion.id).map(&:id)
    old_item_lists = PromoItemList.where(promotion_id: @promotion.id).map(&:id)
    if params[:promotion][:promotion_type] == "Discount Period" || params[:promotion][:promotion_type] == "Happy Hour"
      params[:promotion][:promo_item_lists_attributes] = params[:promotion][:prize_lists_attributes]
    end
    respond_to do |format|
      if @promotion.update_attributes(promotion_params)
        PrizeList.where(id: old_prize_lists).delete_all
        PromoItemList.where(id: old_item_lists).delete_all
        @promotion.promo_item_lists.first.update_attributes(start_time: params[:start_time], end_time: params[:end_time])
        flash[:notice] = t(:successfully_updated)
      else
        flash[:error] = @promotion.errors.full_messages
      end
      format.js
    end
  end

  # DELETE /promotions/1
  # DELETE /promotions/1.json
  def destroy
    @promotion = Promotion.find(params[:id])
    @promotion.destroy
    get_paginated_promotions
    respond_to do |format|
      format.js
    end
  end

  def search
    @promotions = Promotion.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @promotion = Promotion.new
      format.js
    end
  end

  def get_number
    @promotion_number = Promotion.number(params)
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
  def get_paginated_promotions
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @promotions = Promotion.where(conditions.join(' AND ')).order(default_order).paginate(:page => params[:page], :per_page => 10).joins(:office).select("promotions.*, offices.office_name AS branch_name")
    #@promotions = Promotion.joins(promo_item_lists: :product).where(conditions.join(' AND ')).order(default_order).paginate(:page => params[:page], :per_page => 10).joins(:office).select("promotions.*, offices.office_name AS branch_name, barcode") || []
  end

  def promotion_params
    params.require(:promotion).permit(
      :code, :name, :from, :to, :min_amount, :min_qty, :max, :is_p2p, :is_member, :is_claim, :office_id, :multi, :discount_amount, :discount_percent, :promotion_type,
      promo_item_lists_attributes: [:department_id, :m_class_id, :brand_id, :article_id, :product_id, :min_qty],
      prize_lists_attributes: [:department_id, :m_class_id, :brand_id, :article_id, :max_qty, :min_qty, :product_id, :disc_amt, :prize_promo]
    )
  end

  def can_view_promo
    not_authorized unless current_user.can_view_promo?
  end

  def can_manage_promo
    not_authorized unless current_user.can_manage_promo?
  end
end
