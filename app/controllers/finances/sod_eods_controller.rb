class Finances::SodEodsController < ApplicationController

  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_sod_eods, only: [:index, :destroy]
  before_filter :prepare_sod_eod, only: [:edit, :update, :destroy]
  before_filter :get_cashiers
  before_filter :can_view_sod_eod , only: [:index, :show]
  before_filter :can_manage_sod_eod, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("SOD - EOD".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_sod_eods_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finances_sod_eods_path }
  add_crumb("New".html_safe, only: ["new", "create"]) { |instance| instance.send :new_finances_sod_eod_path }

  def index
  end

  def new
    @sod_eod = SodEod.new
  end

  def create
    #ToDo: Dot not need if autocomplete can return it's id as value.
    params[:sod_eod][:office_id] = Office.where(:office_name => params[:sod_eod][:office_id]).first.id unless params[:sod_eod][:office_id].blank?

    @sod_eod = SodEod.new(sod_eod_params)
    @sod_eod.cash = params[:start_cash]
    @sod_eod.date =  Time.now

    if @sod_eod.save
      flash[:notice] = 'Petty Cash was successfully created.'
      redirect_to edit_finances_sod_eod_path(@sod_eod.id)
    else
      flash[:error] = @sod_eod.errors.full_messages
      redirect_to new_finances_sod_eod_path 
    end
  end

  def edit
  end

  def update
    @sod_eod.cash = @sod_eod.cash.merge(params[:end_cash]) unless params[:end_cash].blank?

    if @sod_eod.update_attributes(sod_eod_params)
      flash[:notice] = 'Petty Cash was successfully updated.'
      redirect_to edit_finances_sod_eod_path(@sod_eod.id)
    else
      flash[:error] = @sod_eod.errors.full_messages
      redirect_to edit_finances_sod_eod_path(@sod_eod.id)
    end
  end

  def destroy
    @sod_eod.destroy unless @sod_eod.blank?
  end

  def get_branches
    @offices = Office.where('head_office_id is not null')
    respond_to do |format|
      format.json { render :json => @offices }
    end
  end

 private

  def sod_eod_params
    params.require(:sod_eod).permit(:office_id, :start_time, :end_time, :actual_end_amount, :note, :user_id, cash_outs_attributes: [:id, :time, :description, :amount, :_destroy, :receipt])
  end

  def prepare_sod_eods
    date = params[:by_date]
    branch = params[:by_branch]
    results = SodEod.in_date(date).in_branch(branch).order('created_at DESC')
    @sod_eods = results.page(params[:page]).per(PER_PAGE)
  end

  def prepare_sod_eod
    @sod_eod = SodEod.find(params[:id])
  end

  # Role_id kasir = 10
  def get_cashiers
    @cashiers = User.where(role_id: KASIR_ROLE_ID)
  end

  def can_view_sod_eod
    not_authorized unless current_user.can_view_sod_eod?
  end

  def can_manage_sod_eod
    not_authorized unless current_user.can_manage_sod_eod?
  end

end
