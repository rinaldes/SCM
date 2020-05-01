class AreasController < ApplicationController
  	skip_before_filter :verify_authenticity_token, only: [:destroy]
  	before_filter :can_view_area, only: [:index, :show]
  	before_filter :can_manage_area, only: [:new, :create, :edit, :update]
    autocomplete :area, :name

  	def index
  	get_paginated_areas
  	respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data @areas.to_csv2 }
      else
        format.csv { send_data @areas.to_csv(@areas, {}) }
      end
    end
  end

  def branches_per_regional
    @areas = City.where("regional_id=#{params[:regional_id]}").limit(11)
  end

  def new
  	@regional = Regional.all
    @city = City.all
    @area = Area.new(params[:area])
    respond_to do |format|
      format.html
    end
  end

  def create
    #@area = Area.new(area_params)
    @area = Area.new area_params.merge(code: (("AREA#{sprintf '%03d', ((Area.where("code IS NOT NULL").order("code DESC").limit(1).last.code.gsub('AREA', '').to_i rescue 0)+1)}")))
    if @area.save
      flash[:notice] = 'Area Successfully Created'
      redirect_to areas_path
    else
      @regionals = Regional.all
      flash[:error] = @area.errors.full_messages.join(',')
      render 'new'
    end
  end

  def show
  	@area = Area.find(params[:id])
  end

  def update
  	@area = Area.find(params[:id])
  	if @area.update(area_params)
  		flash[:notice] =  "Successfully update Area"
  		redirect_to areas_path
  	else
      @regional = Regional.all
  		flash[:error] = @area.errors.full_messages.join(',')
      	render 'edit'
    end
  end

  def edit
    @area = Area.find(params[:id])
    @regional = Regional.all
  end

  def destroy
    @area = Area.find(params[:id])
    if @area.check_transaction && @area.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Area"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Area. data is in use"
    end
    get_paginated_areas
    respond_to do |format|
      format.js
    end
  end

  def areas_per_cities
    @areas = Area.where("city_id = #{params[:city_id]}").limit(11)
    #respond_to :js
  end

	def import
    import_result = Area.import(params[:file])
    if import_result[:error] == 1
      flash[:error] = import_result[:message]
    else
      flash[:notice] = import_result[:message]
    end
    redirect_to areas_path
  end

  private

  def area_params
    params.require(:area).permit(:code, :name, :description, :regional_id, :city_id)
  end

  def get_paginated_areas
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @areas = Area.select("zones.*, regionals_zones.name AS regional_name, cities_zones.name AS city_name").where(conditions.join(' AND ')).joins(:regional,:city).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def can_view_area
    not_authorized unless current_user.can_view_area?
  end

  def can_manage_area
    not_authorized unless current_user.can_manage_area?
  end
end
