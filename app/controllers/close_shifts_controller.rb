class CloseShiftsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy, :tutup_shift]
  before_filter :can_view_session, only: [:index]
  before_filter :can_manage_session, only: [:tutup_shift]

  def index
    get_paginated_sessions
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @session = SodEod.find(params[:id])
    filename = "End Shift #{@session.user.username}/#{@session.start_time.strftime("%d-%m-%Y")}.xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  def print_to_pdf
    @session = SodEod.find(params[:id])
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html)
    send_data(pdf,
      :filename    => "Close Shift.pdf",
      :disposition => 'attachment',
    )
  end

  def search_shift
    @session = SodEod.find(params[:id]) if params[:id].present?
    @session.update_attributes(end_time: Time.now) if params[:id].present?
    get_paginated_sessions
    flash[:notice] = 'Shift was successfully ended' if params[:id].present?
    respond_to do |format|
      format.js
    end
  end

  def tutup_shift
    @sod_eod = SodEod.find(params[:id])
    if @sod_eod.update_attributes(end_time: Time.now)
      @sod_eod.update_attributes(paid_difference: params[:v_paid]) if params[:v_paid].present?
      @sod_eod.update_attributes(end_amount: params[:cash_income]) if params[:cash_income].present?
      itung_sales
      flash[:notice] = 'Session was successfully ended'
    else
      flash[:error] = @session.errors.full_messages.join('<br/>')
    end
  end

  def save_income
    @sod_eod = SodEod.find(params[:id])
    @sod_eod.update_attributes(end_amount: params[:cash_income]) if params[:cash_income].present?
    itung_sales
  end

  def itung_sales
    conditions = ["store_id = #{@sod_eod.office_id}"]
    conditions << "user_id = #{@sod_eod.user_id}"
    conditions << "transaction_date >= '#{@sod_eod.start_time}'"
    sales = Sale.where(conditions.join(' AND '))
    cash = 0
    voucher = 0
    debit = 0
    credit = 0
    promo = 0
    total = 0
    ppn = 0
    receipt_count = sales.count
    sales.each do |sale|
      if (sale.payment_type.to_s.downcase == "cash")
        cash += sale.total_price
      elsif (sale.payment_type.to_s.downcase == "voucher")
        voucher += sale.total_price
      elsif (sale.payment_type.to_s.downcase == "debit")
        debit += sale.total_price
      elsif (sale.payment_type.to_s.downcase == "credit")
        credit += sale.total_price
      elsif (sale.payment_type.to_s.downcase == "promo")
        promo += sale.total_price
      end
      total += sale.total_price
      ppn += sale.total_ppn
    end
    diff = total - @sod_eod.end_amount
    @sod_eod.update_attributes(difference: diff, actual_end_amount: total,receipt_count: receipt_count, ppn: ppn, total_cash_sales: total - ppn, total_sales: total, cash: cash, debit: debit, credit: credit, voucher: voucher, claim_promo: promo)
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

private
  def get_paginated_sessions
    conditions = []
    conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    conditions << "end_time is null" if(params[:unfinished] == "true")
    conditions << "user_id = #{params[:user]}" if(params[:user].present? && params[:user] != "0")
    conditions << "office_id = #{params[:store]}" if(params[:store].present? && params[:store] != "0")
    conditions << "shift_no = #{params[:shift]}" if(params[:shift].present? && params[:shift] != "0")
    conditions << "start_time <= '#{params[:date]} 23:59:59'" if params[:date].present?
    conditions << "start_time >= '#{params[:date]} 00:00:00'" if params[:date].present?
    @sessions = SodEod.joins(:office, :user).select("offices.*, users.username").where(conditions.join(' AND ')).where("sod_eods.note = 'MOBILE_POS'").order(:start_time)
     .select("sod_eods.*, office_name, concat(users.first_name, ' ', users.last_name) as user_name").paginate(:page => params[:page], :per_page => 10) || []
  end

  def can_view_session
    not_authorized unless current_user.can_view_sod_eod?
  end

  def can_manage_session
    not_authorized unless current_user.can_manage_sod_eod?
  end
end
