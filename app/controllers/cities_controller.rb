class CitiesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_city, only: [:index, :show]
  before_filter :can_manage_city, only: [:new, :create, :edit, :update]
  autocomplete :city, :name

  def index
  	get_paginated_cities
    filename = 'branch.xls'
  	respond_to do |format|
      format.html
      format.js
      format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
      if(params[:a] == "a")
        format.csv { send_data City.all().to_csv2, :filename => 'branch.csv' }
      else
        format.csv { send_data City.all.to_csv, :filename => 'branch.csv' }
      end
    end
  end

  def new
  	@regionals = Regional.all
    @city = City.new(params[:city])
    respond_to do |format|
      format.html
    end
  end

  def create
    #@city = City.new(city_params)
    @city = City.new city_params.merge(code: (("BRANCH#{sprintf '%03d', ((City.where("code IS NOT NULL").order("id DESC").limit(1).last.code.gsub('BRANCH', '').to_i rescue 0)+1)}")))
    if @city.save
      flash[:notice] = 'Branch Successfully Created'
      redirect_to cities_path
    else
      @regionals = Regional.all
      flash[:error] = @city.errors.full_messages.join(',')
      render 'new'
    end
  end

  def show
  	@city = City.find(params[:id])	
  end

  def update
  	@city = City.find(params[:id])
  	if @city.update(city_params)
  		flash[:notice] =  "Successfully update Branch"
  		redirect_to cities_path
  	else
      @regionals = Regional.all
  		flash[:error] = @city.errors.full_messages.join(',')
      	render 'edit'
    end
  end

  def edit
    @city = City.find(params[:id])
    @regionals = Regional.all
  end

  def destroy
    @city = City.find(params[:id])
    #if @city.check_transaction && @city.destroy
    if @city.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Branch"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Branch. data is in use"
    end
    get_paginated_cities
    respond_to do |format|
      format.js
    end
  end

	def import
    import_result = City.import(params[:file])
    if import_result[:error] == 1
      flash[:error] = import_result[:message]
    else
      flash[:notice] = import_result[:message]
    end
    redirect_to cities_path
  end

  def cities_per_regional
    @cities = City.where("regional_id=#{params[:regional_id]}").limit(11)
  end

  private
  
  def city_params
    params.require(:city).permit(:code, :name, :description, :regional_id)
  end

  def get_paginated_cities
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @cities = City.select("zones.*, regionals_zones.name AS regional_name").where(conditions.join(' AND ')).joins(:regional).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def can_view_city
    not_authorized unless current_user.can_view_city?
  end

  def can_manage_city
    not_authorized unless current_user.can_manage_city?
  end
end