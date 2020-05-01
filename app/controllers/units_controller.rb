class UnitsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :unit, :name
  before_action :set_unit, only: [:show, :destroy, :edit, :update]
  before_filter :can_view_unit, only: [:index, :show]
  before_filter :can_manage_unit, only: [:new, :create, :edit, :update, :destroy]

  def index
    get_paginated_units
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls {
        filename = "Unit_#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.xls"
      }
      if(params[:a] == "a")
        format.csv { send_data Unit.all.to_csv2 }
      else
        format.csv { send_data Unit.all.to_csv }
      end
    end
  end

  def show
    @unit = Unit.find(params[:id])
  end

  def import
    import_result = Unit.import(params[:file])
    if %w(text/csv application/vnd.ms-excel).include?params[:file].content_type
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to units_path
  end

  def new
    @unit = Unit.new(params[:unit])
    respond_to do |format|
      format.html
    end
  end

  def create
    @unit = Unit.new(unit_params)
    respond_to do |format|
      if @unit.save
        flash[:notice] = 'Unit was successfully created.'
        format.html{redirect_to units_path}
      else
        flash[:error] = @unit.errors.full_messages.join('</br>')
        format.html{render "new"}
      end
    end
  end

  def edit
    @unit = Unit.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def update
    @unit = Unit.find(params[:id])
    if @unit.update_attributes(unit_params)
      flash[:notice] = 'Unit was successfully updated.'
      redirect_to units_path
    else
      flash[:error] = @unit.errors.full_messages
      render "edit"
    end
  end

  def destroy
    if @unit.check_transaction && @unit.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete unit"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete unit. data in use"
    end
    get_paginated_units
    respond_to do |format|
      format.js
    end
  end

  private
  def get_paginated_units
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @units = Unit.where(conditions.join(' AND ')).order(default_order('units')).paginate(page: params[:page], per_page: 10) || []
  end

  def unit_params
    params.require(:unit).permit(:name, :short_name)
  end

  def can_view_unit
    not_authorized unless current_user.can_view_unit?
  end

  def can_manage_unit
    not_authorized unless current_user.can_manage_unit?
  end

  def set_unit
    @unit = Unit.find(params[:id])
  end
end
