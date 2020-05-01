class Finances::ForecastsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_forecasts, only: [:index, :destroy]
  before_filter :prepare_forecast, only: [:update, :destroy, :show]
  before_filter :can_view_forecast, only: [:index, :show]
  before_filter :can_manage_forecast, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  add_crumb("Forecast".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_forecasts_path }
  add_crumb("List".html_safe, only: ["index"]) { |instance| instance.send :finances_forecasts_path }
  add_crumb("New".html_safe, only: ["new", "create"]) { |instance| instance.send :new_finances_forecast_path }

  def index
  end

  def new
    @forecast = Forecast.new
  end

  def create
    params[:forecast][:branch_id] = Office.where(:office_name => params[:forecast][:office_id]).first.id unless params[:forecast][:office_id].blank? #ToDo: Dot not need if autocomplete can return it's id as value.
    @forecast = Forecast.new(forecast_params)
    if @forecast.save

      # @forecast.monthly_forecasts.each do |monthly_forecast|
      #   start_date = Date.new(@forecast.year.year, monthly_forecast.month_number, 1)
      #   end_date = start_date.end_of_month
      #   departments = @forecast.office.departments
      #   departments.each do | department|
      #     (start_date..end_date).each do |date|
      #       monthly_forecast.monthly_forecast_details.create(:forecast_date => date, :department_id => department.id)
      #     end
      #   end
      # end

      flash[:notice] = 'Forecast was successfully created.'
      redirect_to  finances_forecast_path(@forecast.id)
    else
      flash[:error] = @forecast.errors.full_messages
      render :new
      # redirect_to new_finances_forecast_path
    end
  end

  def show
  end

  def edit
  end

  def update
    if @forecast.update_attributes(forecast_params)
      flash[:notice] = 'Forecast was successfully updated.'
      redirect_to finances_forecast_path(@forecast.id)
    else
      flash[:error] = @forecast.errors.full_messages
      render :edit
    end
  end

  def destroy
    @forecast.destroy unless @forecast.blank?
  end

 private

  def forecast_params
    params.require(:forecast).permit(:year, :branch_id, :department_id , monthly_forecasts_attributes: [:id, :forecast_id, :month_number, :qty, :amount, :realization_qty, :realization_amount, :qty_in_percent, :amount_in_percent, :department_id, :forecast_type, :_destroy])
  end

  def prepare_forecasts
    @forecasts = Forecast.page(params[:page]).order('year DESC').per(PER_PAGE)
  end

  def prepare_forecast
    @forecast = Forecast.find(params[:id])
  end

  def can_view_forecast
    not_authorized unless current_user.can_view_forecast?
  end

  def can_manage_forecast
    not_authorized unless current_user.can_manage_forecast?
  end

end