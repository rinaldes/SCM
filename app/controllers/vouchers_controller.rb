class VouchersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_by_id, only: [:show, :edit]
  before_filter :can_view_voucher, only: [:index, :show]
  before_filter :can_manage_voucher, only: [:new, :create, :edit, :update, :destroy]

  def show
  end

  def index
    get_paginated_vouchers
    respond_to do |format|
      format.html
      format.js
      format.xls {
        filename = "Voucher_#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.xls"
        send_data(@vouchers.to_xls, :type => "text/xls; charset=utf-8; header=present", :filename => filename)
      }
    end
  end

  def new
    @voucher = Voucher.new(params[:voucher])
    @office = Office.all.order('name')
    respond_to do |format|
      format.html
    end
  end

  def create
    if params[:dari].present?
      if params[:voucher][:valid_from].to_date <= params[:voucher][:valid_until].to_date
        dari = params[:dari].to_i
        if params[:prefix].present?
          prefix = params[:prefix]
        else
          prefix = "HMV"
        end
        nominal = (params[:voucher][:amount] == "100000" ? params[:voucher][:amount].chop.chop.chop.chop : params[:voucher][:amount].chop.chop.chop)
        amount = prefix + nominal
        if params[:hingga].present?
          ke = params[:hingga].to_i + 1
          udah_ada = Voucher.where("voucher_number BETWEEN #{dari} AND #{ke-1} AND voucher_code LIKE '#{amount}%'")
          unless udah_ada.present?
            while dari < ke  do
              @voucher = Voucher.new(voucher_params.merge(voucher_number: dari, is_active: true, voucher_code: (amount +"#{sprintf '%04d', dari}")))
              @voucher.save
              dari += 1
            end
          else
            daftarnya = ''
            udah_ada.each do |datanya|
              daftarnya += datanya.voucher_number.to_s + ", "
            end
            noticenya = 'Voucher Number ' + daftarnya.chop.chop + ' Already Used, Choose Another Number.'
          end
        else
          udah_ada = Voucher.find_by_voucher_code(amount +"#{sprintf '%04d', dari}")
          unless udah_ada.present?
            @voucher = Voucher.new(voucher_params.merge(voucher_number: dari, is_active: true, voucher_code: (amount +"#{sprintf '%04d', dari}")))
            @voucher.save
          else
            noticenya = 'Voucher Number ' + udah_ada.voucher_number + ' Already Used, Choose Another Number.'
          end
        end
      else
        noticenya = 'Valid Until must be after Valid From.'
      end
    else
      noticenya = "Nomor Voucher required."
    end
    if @voucher.present?
      respond_to do |format|
        flash[:notice] = 'Voucher was successfully created.'
        format.html{redirect_to vouchers_path}
      end
    else
      @voucher = Voucher.new(voucher_params)
      flash[:error] = noticenya
      render 'new'
    end
  end

  def edit
    respond_to do |format|
      format.html
    end
  end

  def update
    @voucher = Voucher.find(params[:id])
    if @voucher.update_attributes(voucher_params)
      flash[:notice] = 'Voucher was successfully updated.'
      redirect_to vouchers_path
    else
      flash[:error] = @voucher.errors.full_messages
      render "edit"
    end
  end

  def destroy
    @voucher = Voucher.find(params[:id])
    @voucher.destroy
    get_paginated_vouchers
    respond_to do |format|
      format.js
    end
  end

  private
  def get_paginated_vouchers
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @vouchers = Voucher
      .joins('LEFT JOIN offices ON vouchers.office_id = offices.id').select("voucher_code, vouchers.id AS id, name, to_char(valid_from, 'DD-MM-YYYY') AS valid_from, to_char(valid_until, 'DD-MM-YYYY') AS valid_until, amount, office_name, used_date")
      .where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
  end

  def voucher_params
    params.require(:voucher).permit(:name, :valid_from, :valid_until, :amount, :voucher_number, :is_active, :voucher_code)
  end

  def find_by_id
    @voucher = Voucher.find_by_id(params[:id])
  end

  def can_view_voucher
    not_authorized unless current_user.can_view_voucher?
  end

  def can_manage_voucher
    not_authorized unless current_user.can_manage_voucher?
  end
end