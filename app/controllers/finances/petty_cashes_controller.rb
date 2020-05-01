class Finances::PettyCashesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy, :create]
  before_filter :prepare_petty_cashes, only: [:index, :destroy]
  before_filter :prepare_petty_cash, only: [:update, :destroy]
  before_filter :can_view_petty_cash, only: [:index, :show]
  before_filter :can_manage_petty_cash, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("Petty Cash".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_petty_cashes_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finances_petty_cashes_path }

  def new
    @petty_cash = PettyCash.new
  end

  def create
    PettyCash.generate_petty_cashes(params[:f_year], params[:f_month], params[:f_store],params[:f_init_budget])
    prepare_petty_cashes
    flash[:notice] = 'Initial Petty Cash Successfully created.'
  end

  def index
    PettyCash.generate_petty_cashes(Time.now.year, Time.now.month)
  end

  def show
    # if current_user.branch_id.present?
      # prepare_petty_cash2
    # else
      prepare_petty_cash
    # end
  end

  def destroy
    @petty_cash.destroy unless @petty_cash.blank?
  end

  def petty_cash_month
    conditions = []
    year = Date.today.strftime("%Y")
    month = Date.today.strftime("%m")
    if current_user.branch_id.present?
      conditions << "petty_cashes.office_id = #{current_user.branch_id}"
    else
      conditions << "petty_cashes.office_id = #{params[:store]}" if params[:store].present?  && params[:store] != '0'
    end
    year = params[:date_year] if params[:date_year].present?
    month = params[:date_month] if params[:date_month].present?
    if current_user.branch_id.present?
      office_id = current_user.branch_id
      @petty_cash = PettyCashDetail.joins(petty_cash: :office).select("petty_cash_details.*, year, month, offices.id").where("offices.id = ?", office_id).where("EXTRACT(YEAR FROM year) = ?", year).where("EXTRACT(MONTH FROM year) = ?", month).order('date')
    else
      @petty_cash = PettyCashDetail.joins(:petty_cash).select("petty_cash_details.*, year, month").where(conditions.join(' AND ')).where("EXTRACT(YEAR FROM year) = ?", year).where("EXTRACT(MONTH FROM year) = ?", month).order('date')
    end
  end

  def get_branches
    @offices = Office.where('head_office_id is not null')
    respond_to do |format|
      format.json { render :json => @offices }
    end
  end

 private
  def petty_cash_params
    params.require(:petty_cash).permit(petty_cash_details_attributes: [:id, :petty_cash_id, :date, :initial_budget, :cash_in, :cash_out, :note, :_destroy])
  end

  def prepare_petty_cashes
    conditions = []
    conditions << "petty_cashes.year = '#{params[:by_date].to_date.strftime('%Y-%m-%d')}'" if params[:by_date].present?

    if current_user.branch_id.present?
      results = PettyCash.where(conditions.join(' AND ')).where(office_id: current_user.branch_id).order('created_at DESC')
    else
      conditions << "petty_cashes.office_id = #{params[:store]}" if params[:store].present?  && params[:store] != '0'
      results = PettyCash.where(conditions.join(' AND ')).order('created_at DESC')
    end
    @petty_cashes = results.page(params[:page]).per(PER_PAGE)
  end

  def prepare_petty_cash
    if (params[:petty_cash].present? && params[:branch].present?) || params[:date].present?
      if current_user.branch_id.present?
        office_id = current_user.branch_id
      else
        office_id = params[:branch]
      end

      year = params[:date][:year]
      month = params[:date][:month]
      @petty_cash = PettyCash.joins(:office).where("offices.id = ?", office_id).where("EXTRACT(YEAR FROM year) = ?", year).where("EXTRACT(MONTH FROM year) = ?", month).first
    else
      @petty_cash = PettyCash.find(params[:id])
    end
  end

  def prepare_petty_cash2
    if (params[:petty_cash].present? && current_user.branch_id.present?) || params[:date].present?
      office_id = current_user.branch_id
      year = params[:date][:year]
      month = params[:date][:month]
      @petty_cash = PettyCash.joins(:office).where("offices.id = ?", office_id).where("EXTRACT(YEAR FROM year) = ?", year).where("EXTRACT(MONTH FROM year) = ?", month).first
    else
      @petty_cash = PettyCash.find_by_office_id(current_user.branch_id)
    end
  end

  def can_view_petty_cash
    not_authorized unless current_user.can_view_petty_cash?
  end

  def can_manage_petty_cash
    not_authorized unless current_user.can_manage_petty_cash?
  end
end
