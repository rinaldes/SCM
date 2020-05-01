class PurchaseReturnSummariesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_receipt, only: [:show, :mark_as_inspected, :print_to_pdf]
  before_filter :can_view_purchase_summary, only: [:index, :show]

  def index
    get_paginated_receivings
    @filenames = params[:controller]
    if request.format.xls?
      @filenames << '_' + Office.find(params[:store]).office_name if params[:store].present?
      @filenames << '_from_' + params[:start_date] if params[:start_date].present?
      @filenames << '_until_' + params[:end_date] if params[:end_date].present?
    end
    respond_to do |format|
      format.html
      format.js
      format.xls{ headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xls\""}
    end
  end

  def show
    @receiving = ReturnsToSupplier.find params[:id]
    #@purchase_order = @receiving.purchase_order
    @supplier = @receiving.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{|pd|pd.product_id}
    @returns_to_supplier_details = @receiving.returns_to_supplier_details.where("quantity>0").joins(:product).order(default_order('returns_to_supplier_details')).paginate(:page => params[:page], :per_page => 50) || []
  end

  def get_last_number
    render json: {
      number: sprintf("R#{Time.now.year}#{sprintf('%06d', ReturnsToSupplier.last.number.gsub("R#{Time.now.year}", '').to_i+1)}")
    }
  end

  def search
    @receivings = ReturnsToSupplier.search(params[:search]).paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @receiving = ReturnsToSupplier.new
      format.js
    end
  end

  def get_number
    @receiving_number = ReturnsToSupplier.number(params)
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

  def search_receiving
    get_paginated_receivings
    respond_to do |format|
      format.js
    end
  end

private
  def get_paginated_receivings
    if params[:store] == '0'
      params[:store] = nil
    end
    @ada_toko = params[:store] if params[:store].present?
    conditions = []
      if current_user.branch_id.present?
        conditions << "returns_to_suppliers.head_office_id = #{current_user.branch_id}"
      else
        conditions << "returns_to_suppliers.head_office_id = #{params[:store]}" if (params[:store].present? && params[:store] != '0')
      end
      conditions << "returns_to_suppliers.date >= to_date('#{params[:start_date]}', 'YY-MM-DD')" if params[:start_date].present?
      conditions << "returns_to_suppliers.date < to_date('#{params[:end_date]}', 'YY-MM-DD')+ interval '1 day'" if params[:end_date].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    params[:sort] = params[:sort].present? ? params[:sort] : "date-desc"
    if params[:type].present? || request.format.xls? || request.format.csv?
      @receivings = ReturnsToSupplier.where(conditions.join(' AND '))
      .order(params[:sort].to_s.gsub('-', ' '))
      .joins("INNER JOIN offices ho ON ho.id=returns_to_suppliers.head_office_id INNER JOIN suppliers sup ON sup.id=supplier_id")
      .select("supplier_id, ho.office_name AS office_name, sup.name AS supplier_name, to_char(date, 'DD-MM-YYYY') AS date, status, number, to_char(quantity, '999') As quantity, total, note, receive_no, returns_to_suppliers.id, reason_code")
    else
      @receivings = ReturnsToSupplier.where(conditions.join(' AND '))
      .order(params[:sort].to_s.gsub('-', ' '))
      .joins("INNER JOIN offices ho ON ho.id=returns_to_suppliers.head_office_id INNER JOIN suppliers sup ON sup.id=supplier_id")
      .select("supplier_id, ho.office_name AS office_name, sup.name AS supplier_name, date, to_char(date, 'DD-MM-YYYY') AS r_date, status, number, to_char(quantity, '999') As quantity, total, note, receive_no, returns_to_suppliers.id, reason_code")
      .paginate(:page => params[:page], :per_page => 10) || []
    end
  end

  def find_receipt
    @receiving = ReturnsToSupplier.find(params[:id])
  end

  def can_view_purchase_summary
    not_authorized unless current_user.can_view_return_to_supplier?
  end
end
