class ArVouchersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_ar_voucher, only: [:index, :show]
  before_filter :can_manage_ar_voucher, only: [:new, :create, :edit, :update, :destroy]

  def index
    @branches = Branch.select("office_name, office_name").limit(11).order("office_name").map{|product|[product.office_name, product.office_name]}
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @ar_vouchers = ArVoucher.where(conditions.join(' AND ')).order(default_order('vouchers')).paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @voucher_detail = ArVoucherDetail.new(params[:ar_voucher_detail])
    @ar_voucher = ArVoucher.find(params[:id])
    @branch = @ar_voucher.office
    @ar_voucher_p = ArVoucherPaymentSchedule.where(:ar_voucher_id => params[:id])
    @ar_voucher_d = ArVoucherDetail.where(:ar_voucher_id => params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @branches = Branch.select("office_name, office_name").limit(11).order("office_name").map{|product|[product.office_name, product.office_name]}
    @ar_voucher = ArVoucher.new(params[:ar_voucher])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @ar_voucher = ArVoucher.find(params[:id])
    @branches = Branch.select("office_name, office_name").limit(11).order("office_name").map{|product|[product.office_name, product.office_name]}
    @branch = @ar_voucher.office
    respond_to do |format|
      format.html
    end
  end

  def create
    @branches = Branch.select("office_name, office_name").limit(11).order("office_name").map{|product|[product.office_name, product.office_name]}
    office_id = Office.find_by_office_name(params[:office_id])
    @ar_voucher = ArVoucher.new(ar_voucher_params.merge(:office_id => (office_id.id rescue nil)))
    if @ar_voucher.save
      flash[:notice] = 'AR Voucher was successfully created'
      redirect_to ar_vouchers_path
    else
      flash[:error] = @ar_voucher.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def update
    @ar_voucher = ArVoucher.find(params[:id])
    old_schedules = @ar_voucher.ar_voucher_payment_schedules.map(&:id)
    if @ar_voucher.update_attributes(ar_voucher_params)
      ArVoucherPaymentSchedule.where(id: old_schedules).delete_all
      flash[:notice] = 'AR Voucher was successfully updated.'
      redirect_to ar_vouchers_path
    else
      flash[:error] = @ar_voucher.errors.full_messages
      # format.js
      render "edit"
    end
  end

  def destroy
  @ar_voucher = ArVoucher.find(params[:id])
    @ar_voucher.destroy
    @ar_vouchers = ArVoucher.all
    respond_to do |format|
      format.js
    end
  end

  def search
    @ar_vouchers = ArVoucher.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @ar_voucher = ArVoucher.new
      format.js
    end
  end

  def get_number
    @ar_voucher_number = ArVoucher.number(params)
    respond_to do |format|
      format.js
    end
  end

  def add_payment
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
  def ar_voucher_params
    params.require(:ar_voucher).permit(
      :valid_from, :name, :valid_until, :max_voucher_amt, :discount_percent, :discount_amount, :office_id, :term, :quantity, ar_voucher_payment_schedules_attributes: [:payment_number, :due_date,
      :due_date_number, :due_date_month, :ar_voucher_id, :amount]
    )
  end

  def can_view_ar_voucher
    not_authorized unless current_user.can_view_ar_voucher?
  end

  def can_manage_ar_voucher
    not_authorized unless current_user.can_manage_ar_voucher?
  end
end
