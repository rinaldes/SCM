class Finances::ApInvoicesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_ap_invoice , only: [:index, :show]
  before_filter :can_manage_ap_invoice, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("AP Invoices".html_safe, only: ["index"]) { |instance| instance.send :finances_ap_invoices_path }

  def index
    get_paginated_ap_invoices
  end

  def add_ap_details
    respond_to do |format|
      format.js
    end
  end

  def select_receiving
    @key = params[:key]
    conditions = ["receivings.supplier_id = #{params[:supplier_id]}"]
    @receivings = Receiving.where(conditions.join(' AND ')).order(default_order('receivings')).joins(:supplier, :head_office)
      .joins("LEFT JOIN purchase_orders ON purchase_orders.id=receivings.purchase_order_id").joins('left outer join receiving_details on receiving_details.receiving_id = receivings.id').group('receivings.id, suppliers.id, purchase_orders.id, office_name')
      .select("office_name, receivings.*, suppliers.name AS supplier_name, purchase_orders.number AS po_number, purchase_orders.total_qty as total_qty, sum(receiving_details.quantity * receiving_details.hpp) AS total_receiving_detail").paginate(:page => params[:page], :per_page => 10) || []
  end

  def get_receiving
    @key = params[:key]
    @receiving = Receiving.find_by_number(params[:number])
  end

  def search_receivings
    @key = params[:key]
    @receivings = Receiving.all
  end

  def show
    @ap_invoice = ApInvoice.find(params[:id])
  end

  def new
    @ap_invoice = ApInvoice.new
    @ap_invoice.ap_invoice_details.build
  end

  def create
    @ap_invoice = ApInvoice.new(ap_invoice_params.merge(number: "API-#{((sprintf '%03d', ((ApInvoice.order("id DESC").limit(1).last.number.gsub('API-', '').to_i rescue 0)+1)))}"))
    if @ap_invoice.save
      flash[:notice] = 'AP Invoice was successfully created'
      redirect_to finances_ap_invoices_path
    else
      flash[:error] = @ap_invoice.errors.full_messages.join(',')
      render "new"
    end
  end

  def edit
    @ap_invoice = ApInvoice.find(params[:id])
  end

  def update
    @ap_invoice = ApInvoice.find(params[:id])
    if @ap_invoice.update_attributes(ap_invoice_params)
      flash[:notice] = 'AP Invoice was successfully updated.'
      redirect_to finances_ap_invoices_path
    else
      flash[:error] = @ap_invoice.errors.full_messages.join(',')
      render "edit"
    end
  end

  def destroy
    @ap_invoice = ApInvoice.find(params[:id])
    if @ap_invoice.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete AP Invoice"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete AP Invoice."
    end
    get_paginated_ap_invoices
    respond_to do |format|
      format.js
    end
  end


  private

  def can_view_ap_invoice
    not_authorized unless current_user.can_view_ap_invoice?
  end

  def can_manage_ap_invoice
    not_authorized unless current_user.can_manage_ap_invoice?
  end


  def ap_invoice_params
    params.require(:ap_invoice).permit(:number, :supplier_id, :dpp, :ppn, :total, :due_date,
      ap_invoice_details_attributes: [:id, :store_id, :receiving_id, :tax_code, :tax_number, :tax_date,
        :gross, :vat, :amount])
  end

  def get_paginated_ap_invoices
    @ap_invoices = ApInvoice.joins("INNER JOIN suppliers ON ap_invoices.supplier_id = suppliers.id").select("ap_invoices.*, suppliers.name AS supplier_name").paginate(:page => params[:page], :per_page => 10) || []
  end
end
