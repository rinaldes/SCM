class RolesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_action :set_role, except: [:index, :new, :create, :destroy, :import]
  respond_to :html
  before_filter :can_view_role, only: [:index, :show]
  before_filter :can_manage_role, only: [:new, :create, :edit, :update]

  def index
    get_paginated_roles
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Role.all.to_csv2 }
      else
        format.csv { send_data Role.all.to_csv }
      end
    end
  end

  def import
    import_result = Role.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to roles_path
  end

  def show
    @role = Role.find (params[:id])
  end

  def new
    @role =Role.new
    @feature_names = FeatureName.select("DISTINCT module_name")
  end

  def create
    @role = Role.new(role_params)
    if @role.save
      params[:features].keys.each{|feature|
        Feature.create role_id: @role.id, feature_name_id: feature, id: (Feature.last.id rescue 0)+1
      }
      respond_to do |format|
        format.html { redirect_to roles_path }
        format.js { render :create }
      end
    else
      respond_to do |format|
        format.js { render :create }
      end
    end
  end

  def edit
    @role = Role.find(params[:id])
    @feature_names = FeatureName.select('distinct module_name')
  end

  def update
    if @role.update(role_params)
      @role.features.delete_all
      params[:features].keys.each{|feature|
        Feature.create role_id: @role.id, feature_name_id: feature, id: Feature.last.id+1
      } if params[:features].present?
      respond_to do |format|
        format.html { redirect_to roles_path }
        format.js { render :update }
      end
    else
      respond_to do |format|
        format.html { render :index }
        format.js { render :update }
      end
    end
  end

  def destroy
  	@role = Role.find(params[:id])
    @role.destroy
    redirect_to roles_path, :notice => "Your Role has been deleted"
  end

 private
    def set_role
      
      @role = Role.find(params[:id])
    end

    def set_roles
      base_role = Role.all
      @roles_count = base_role.count
      @roles = base_role.paginate(:page => params[:page])
    end

    def role_params
      params.require(:role).permit(:name, :features)
    end

  def get_paginated_roles
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @roles = Role.where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 10) || []
  end

  def can_view_role
    not_authorized unless current_user.can_view_role?
  end

  def can_manage_role
    not_authorized unless current_user.can_manage_role?
  end
end
