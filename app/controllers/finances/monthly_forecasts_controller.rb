class Finances::MonthlyForecastsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :prepare_monthly_forecast, only: [:index, :edit, :update, :show]
  before_filter :can_view_forecast, only: [:index, :show]
  before_filter :can_manage_forecast, only: [:new, :create, :edit, :update]

  add_crumb "Finance", '/'
  before_filter :set_custom_breadcrumb, only: [:index, :edit, :update]
  add_crumb("Forecast".html_safe, only: ["index", "new", "create", "edit", "update", "show"]) { |instance| instance.send :finances_forecasts_path }
  add_crumb("Details".html_safe, only: ["show", "edit", "update"]) { |instance| instance.send :finances_forecasts_path }

  def index
  end

  def edit
  end

  def show
  end

  def update
    if @monthly_forecast.update_attributes(monthly_forecast_params)
        flash[:notice] = 'Forecast was successfully created.'
        redirect_to edit_finances_forecast_monthly_forecast_path(@monthly_forecast.forecast_id, @monthly_forecast.id)
    else
      # render :edit
      flash[:error] = @monthly_forecast.errors.full_messages
      redirect_to edit_finances_forecast_monthly_forecast_path(@monthly_forecast.forecast_id, @monthly_forecast.id)
    end
  end

 private

  def monthly_forecast_params
    params.require(:monthly_forecast ).permit(monthly_forecast_details_attributes: [:id, :qty, :amount])
  end

  def prepare_forecasts
    @forecasts = Forecast.page(params[:page]).order('year DESC').per(PER_PAGE)
  end

  def prepare_monthly_forecast
    month = params[:month]
    forecast = Forecast.find(params[:forecast_id])
    @monthly_forecast = forecast.monthly_forecasts.by_month(month).first

pp @monthly_forecast.monthly_forecast_details#.first.forecast_date.beginning_of_month
pp '======================='


                   # <% (@monthly_forecast.monthly_forecast_details.first.forecast_date.beginning_of_month..
                   # @monthly_forecast.monthly_forecast_details.first.forecast_date.end_of_month).each do |day| %>


  end

  def set_custom_breadcrumb
      add_crumb "<a href='#{finances_forecast_path(@monthly_forecast.forecast_id)}'><i></i>Forecast</a>".html_safe, "", {}
  end

  def can_view_forecast
    not_authorized unless current_user.can_view_forecast?
  end

  def can_manage_forecast
    not_authorized unless current_user.can_manage_forecast?
  end

end