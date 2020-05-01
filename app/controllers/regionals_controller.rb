class RegionalsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_regional, only: [:index, :show]
  before_filter :can_manage_regional, only: [:new, :create, :edit, :update]
  autocomplete :regional, :name

  def index
  	@regionals = Regional.all
  	get_paginated_regionals
  	respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Regional.where("parent_id IS NULL").to_csv2 }
      else
        format.csv { send_data Regional.all.to_csv }
      end
    end
  end

  def new
    @regional = Regional.new(params[:regional])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @regional = Regional.new regional_params.merge(code: (("RGN#{sprintf '%03d', ((Regional.where("code IS NOT NULL").order("id DESC").limit(1).last.code.gsub('RGN', '').to_i rescue 0)+1)}")))
    if @regional.save
      flash[:notice] = 'Regional Successfully Created'
      redirect_to regionals_path
    else
      flash[:error] = @regional.errors.full_messages.join(',')
      render 'new'
    end
  end

  def show
  	@regional = Regional.find(params[:id])
  end

  def update
  	@regional = Regional.find(params[:id])
  	if @regional.update(regional_params)
  		flash[:notice] =  "Successfully update regional"
  		redirect_to regionals_path
  	else
  		flash[:error] = @regional.errors.full_messages.join(',')
      	render 'edit'
    end
  end

  def edit
    @regional = Regional.find(params[:id])
  end

  def destroy
    @regional = Regional.find(params[:id])
    if @regional.check_transaction && @regional.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Regional"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Regional. data in use"
    end
    get_paginated_regionals
    respond_to do |format|
      format.js
    end
  end

	def import
    import_result = Regional.import(params[:file])
    if import_result[:error] == 1
      flash[:error] = import_result[:message]
    else
      flash[:notice] = import_result[:message]
    end
    redirect_to regionals_path
  end

  private

  def regional_params
    params.require(:regional).permit(:code, :name, :description)
  end

  def get_paginated_regionals
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @regionals = Regional.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def can_view_regional
    not_authorized unless current_user.can_view_regional?
  end

  def can_manage_regional
    not_authorized unless current_user.can_manage_regional?
  end
end
