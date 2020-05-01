class PlanogramsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_planogram, only: [:index, :show]
  before_filter :can_manage_planogram, only: [:new, :create, :edit, :update]
  autocomplete :regional, :name

  def index
    #@planograms = Planogram.all
    get_paginated_planograms
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Planogram.all().to_csv2 }
      else
        format.csv { send_data Planogram.all.to_csv }
      end
    end
  end

  def new
    @offices = Office.active_store
    @planogram = Planogram.new(params[:planogram])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @planogram = Planogram.find(params[:id])
    @offices = Office.active_store
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @planogram = Planogram.find(params[:id])
  end

  def create
    save = nil
    begin
        @planogram = Planogram.new(planogram_param)
        if @planogram.save
          params[:planogram][:office_id].each{|branch|
            @planogram.planograms_stores.create(branch_id: branch)
          }
            save = true
        else
          save = false
        end
    rescue
    end
    if save
      flash[:notice] = 'Rack was successfully created.'
      redirect_to planograms_path
    else
      flash[:error] = @planogram.errors.full_messages
      render "new"
    end
  end

  def update
    @planogram = Planogram.find(params[:id])
    if @planogram.update(planogram_param)
      flash[:notice] =  "Successfully update Planogram"
      redirect_to planograms_path
    else
      @offices = Office.all
      flash[:error] = @planogram.errors.full_messages.join(',')
        render 'edit'
    end
  end

  def destroy
    @planogram = Planogram.find(params[:id])
    #if @planogram.check_transaction && @planogram.destroy
    if @planogram.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Planogram"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Planogram. data is in use"
    end
    get_paginated_planograms
    respond_to do |format|
      format.js
    end
  end

  def import
    import_result = Planogram.import(params[:file])
    if import_result[:error] == 1
      flash[:error] = import_result[:message]
    else
      flash[:notice] = import_result[:message]
    end
    redirect_to planograms_path
  end

  private

  def planogram_param
    params.require(:planogram).permit(:office_id,:rack_number,:rack_type)
  end

  def get_paginated_planograms
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @planograms = PlanogramsStore.select("planograms_stores.*, planograms.rack_number AS rack_number, planograms.rack_type AS rack_type, offices.office_name AS office_name").where(conditions.join(' AND ')).joins(:planogram).joins("INNER JOIN offices ON planograms_stores.branch_id = offices.id").order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def can_view_planogram
    not_authorized unless current_user.can_view_planogram?
  end

  def can_manage_planogram
    not_authorized unless current_user.can_manage_planogram?
  end
end
