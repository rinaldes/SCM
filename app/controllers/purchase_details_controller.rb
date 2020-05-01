class PurchaseDetailsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_receipt, only: [:show, :mark_as_inspected, :print_to_pdf]
  before_filter :can_view_purchase_summary, only: [:index, :show]

  def index
    conditions = []
    if current_user.branch_id.present?
      conditions << "receivings.head_office_id = #{current_user.branch_id}"
    else
      conditions << "receivings.head_office_id = #{params[:store]}" if params[:store].present?  && params[:store] != '0'
    end
    conditions << "receivings.date >= '#{params[:start_date].to_date.strftime('%Y-%m-%d')}'" if params[:start_date].present?
    conditions << "receivings.date <= '#{params[:end_date].to_date.strftime('%Y-%m-%d')}'" if params[:end_date].present?
    params[:search].each{|param|
      if param[0] == 'uom'
        conditions << "product_id IN (SELECT products.id FROM products INNER JOIN units ON products.unit_id=units.id WHERE LOWER(units.name) LIKE LOWER('#{param[1]}'))" if param[1].present?
      else
        conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
      end
    } if params[:search].present?

    @filenames = params[:controller].titleize
    @filenames << '_' + Office.find(params[:store]).office_name if params[:store].present?  && params[:store] != '0'
    @filenames << '_from_' + params[:start_date] if params[:start_date].present?
    @filenames << '_until_' + params[:end_date] if params[:end_date].present?
    @filenames << '.xls'
    respond_to do |format|
      format.html do
        @receivings = ReceivingDetail.where(conditions.join(' AND ')).order(default_order('receiving_details')).joins(receiving: [:supplier, :head_office]).joins(:product).select("receiving_details.*, receivings.date AS date, receivings.number AS number, products.description AS description, products.article AS article, suppliers.name AS supplier_name, office_name").paginate(:page => params[:page], :per_page => 10) || []
      end
      format.js do
        @receivings = ReceivingDetail.where(conditions.join(' AND ')).order(default_order('receiving_details')).joins(receiving: [:supplier, :head_office]).joins(:product).select("receiving_details.*, receivings.date AS date, receivings.number AS number, products.description AS description, products.article AS article, suppliers.name AS supplier_name, office_name").paginate(:page => params[:page], :per_page => 10) || []
      end
      format.xls do
        headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}\""
        @receivings = ReceivingDetail.where(conditions.join(' AND ')).order(default_order('receiving_details')).joins(receiving: [:supplier, :head_office]).joins(:product).select("receiving_details.*, receivings.date AS date, receivings.number AS number, products.description AS description, products.article AS article, suppliers.name AS supplier_name, office_name")
        @office_nya = params[:store] if params[:store].present? && params[:store] != '0'
      end
    end
  end

  def show
    @receiving = Receiving.find params[:id]
    @receiving = @receiving.receiving
    @supplier = @receiving.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{|pd|pd.product_id}
    @receiving_details = @receiving.receiving_details.where("quantity>0").joins(:product).order(default_order('receiving_details')).paginate(:page => params[:page], :per_page => 50) || []
    load_master
  end

  def get_last_number
    render json: {
      number: sprintf("R#{Time.now.year}#{sprintf('%06d', Receiving.last.number.gsub("R#{Time.now.year}", '').to_i+1)}")
    }
  end

  def search
    @receivings = Receiving.search(params[:search]).paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @receiving = Receiving.new
      format.js
    end
  end

  def get_number
    @receiving_number = Receiving.number(params)
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

  def load_master
    load_supplier
    @products = Product.select("barcode, id").limit(7).order("barcode").map{|product|[product.barcode, product.id]}
    @orders = PurchaseOrder.select("number, id").limit(7).order("number").map{|product|[product.number, product.id]}
  end

  def get_receiving
    @order = PurchaseOrder.find_by_number(params[:number])
    respond_to do |format|
      format.js
    end
  end

  def get_product_details
    @receiving = PurchaseOrder.find(params[:receivings_id])
    respond_to do |format|
      format.js
    end
  end

  def search_receiving
    get_paginated_receivings
    respond_to do |format|
      format.js
    end
  end

private
  def get_paginated_receivings
    conditions = []
      if current_user.branch_id.present?
        conditions << "receivings.head_office_id = #{current_user.branch_id}"
      else
        conditions << "receivings.head_office_id = #{params[:store]}" if params[:store].present?  && params[:store] != '0'
      end
      conditions << "receivings.date >= '#{params[:start_date].to_date.strftime('%Y-%m-%d')}'" if params[:start_date].present?
      conditions << "receivings.date <= '#{params[:end_date].to_date.strftime('%Y-%m-%d')}'" if params[:end_date].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @receivings = ReceivingDetail.where(conditions.join(' AND ')).order(default_order('receiving_details')).joins(receiving: :supplier).joins(:product)
      .select("receiving_details.*, receivings.date AS date, receivings.number AS number, products.description AS description, products.article AS article, suppliers.name AS supplier_name").paginate(:page => params[:page], :per_page => 10) || []
  end

  def find_receipt
    @receiving = Receiving.find(params[:id])
  end

  def can_view_purchase_summary
    not_authorized unless current_user.can_view_receiving?
  end
end
