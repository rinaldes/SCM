class Finances::CashOutsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]

  add_crumb "Finance", '/'
  add_crumb("Cash Out".html_safe, only: ["index", "new", "create", "show"]) { |instance| instance.send :finances_petty_cashes_path }
  add_crumb("Cash Out Details".html_safe, only: ["show"])

  def new
    @cash_out = CashOut.new
  end

  def create
    id_petty_cash = params[:cash_out][:petty_cash_id]
    tanggal = params[:tanggal]
    tanggalnya = tanggal.to_s.split(" ")
    jamnya = Time.now.to_s.split(" ")
    tanggal = tanggalnya[0] + " " + jamnya[1] + " " + jamnya[2]

    @cash_out = CashOut.new(cash_out_params.merge(time: tanggal.to_time, created_at: tanggal.to_date)) #
    if @cash_out.save!
      pcd = PettyCashDetail.where(petty_cash_id: params[:cash_out][:petty_cash_id], date: tanggal.to_date).first_or_create
      pcd_tobe_updated = params[:cash_out][:cash_out_type] == 'CASH IN' ? {cash_in: pcd.cash_in.to_f+params[:cash_out][:amount].to_f} : {cash_out: pcd.cash_out.to_f+params[:cash_out][:amount].to_f}
      pcd.update_attributes(pcd_tobe_updated)

      flash[:notice] = t(:successfully_created)
      redirect_to finances_petty_cash_url(@cash_out.petty_cash_id)
    else
      #load_master
      flash[:error] = @cash_out.errors.full_messages.join('<br/>')
      redirect_to new_finances_cash_out_url(id: id_petty_cash)
    end
  end

  def show
    if params[:date].present?
      @cash_outs = CashOut.where("DATE(created_at) = ? AND petty_cash_id = ?", params[:date], params[:id]).page(params[:page]).per(PER_PAGE)
    else
      @cash_out = CashOut.find_by_petty_cash_id(params[:id])
      @cash_outs = CashOut.where(petty_cash_id: @cash_out.id).page(params[:page]).per(PER_PAGE)
    end
  end

  private
    def cash_out_params
      params.require(:cash_out).permit(:amount, :cash_out_type, :description, :petty_cash_id)
    end
end
