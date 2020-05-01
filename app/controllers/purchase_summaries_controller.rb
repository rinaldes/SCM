class PurchaseSummariesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_receipt, only: [:show, :mark_as_inspected, :print_to_pdf]
  before_filter :can_view_purchase_summary, only: [:index, :show]

  def index
    get_paginated_receivings
    @filenames = params[:controller]
    @filenames << '_' + Office.find(params[:store]).office_name if params[:store].present?  && params[:store] != '0'
    @filenames << '_from_' + params[:start_date] if params[:start_date].present?
    @filenames << '_until_' + params[:end_date] if params[:end_date].present?
    respond_to do |format|
      format.html
      format.js
      format.xls{ headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xls\""}
    end
  end

  def show
    @receiving = Receiving.find params[:id]
    @purchase_order = @receiving.purchase_order
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

  def get_purchase_order
    @order = PurchaseOrder.find_by_number(params[:number])
    respond_to do |format|
      format.js
    end
  end

  def get_product_details
    @purchase_order = PurchaseOrder.find(params[:purchase_orders_id])
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
    @receivings = Receiving.where(conditions.join(' AND ')).order(default_order('receivings')).joins(:supplier, :head_office)
      .joins("LEFT JOIN purchase_orders ON purchase_orders.id=receivings.purchase_order_id").joins('left outer join receiving_details on receiving_details.receiving_id = receivings.id').group('receivings.id, suppliers.id, purchase_orders.id, office_name')
      .select("office_name, receivings.*, suppliers.name AS supplier_name, purchase_orders.number AS po_number, purchase_orders.total_qty as total_qty, sum(receiving_details.quantity * receiving_details.hpp) AS total_receiving_detail")#.paginate(:page => params[:page], :per_page => 100) || []
  end

  def find_receipt
    @receiving = Receiving.find(params[:id])
  end

  def can_view_purchase_summary
    not_authorized unless current_user.can_view_receiving?
  end
end
