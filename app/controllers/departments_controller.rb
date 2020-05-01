class DepartmentsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :department, :name
  before_action :set_department, only: [:show, :destroy, :edit, :update]
  before_filter :can_view_department, only: [:index, :show]
  before_filter :can_manage_department, only: [:new, :create, :edit, :update]

  def departments_list
    @departments = HeadOffice.find(params[:office_id]).departments
    respond_to do |format|
      format.js
    end
  end

  # GET /departments
  # GET /departments.json
  def index
    get_paginated_departments
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Department.where("parent_id IS NULL").to_csv2 }
      else
        format.csv { send_data Department.where("parent_id IS NULL").to_csv }
      end
    end
  end

  def import
    import_result = Department.import(params[:file])
    if import_result[:error] == 1
      flash[:error] = import_result[:message]
    else
      flash[:notice] = import_result[:message]
    end
    redirect_to departments_path
  end

  def departments_per_supplier
    supplier = Supplier.find(params[:supplier_id])
    @departments = supplier.departments
    respond_to do |format|
      format.js
    end
  end

  def show
    @department = Department.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @department = Department.new(params[:department])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /departments/1/edit
  def edit
    respond_to do |format|
      format.html
    end
  end

  # DELETE /departments/1
  # DELETE /departments/1.json
  def destroy
    if @department.check_transaction && @department.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete department"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete department. data in use"
    end
    get_paginated_departments
    respond_to do |format|
      format.js
    end
  end

  # POST /departments
  # POST /departments.json
  def create
    @department = Department.new(department_params.merge(code: "D#{((sprintf '%03d', ((MClass.where("parent_id IS NULL").order("id DESC").limit(1).last.code.gsub('D', '').to_i rescue 0)+1)))}"), level: 0)
    if @department.save
      flash[:notice] = 'Department was successfully created'
      redirect_to departments_path
    else
      flash[:error] = @department.errors.full_messages.join(',')
      render "new"
    end
  end

  # PUT /departments/1
  # PUT /departments/1.json
  def update
    if @department.update_attributes(department_params)
      flash[:notice] = 'Department was successfully updated.'
      redirect_to departments_path
    else
      flash[:error] = @department.errors.full_messages.join(',')
      render "departments/edit"
    end
  end

  def autocomplete_department_name
    hash = []
    supplier = MClass.where("LOWER(name) like '%#{params[:term]}%' AND parent_id IS NULL").limit(11).order('name')
    supplier.collect do |p|
      hash << {"id" => p.id, "label" => p.name, "value" => p.name}
    end
    render json: hash
  end

  def categories_per_department
    @categories = MClass.where("parent_id=#{params[:department_id]}")
    respond_to do |format|
      format.js
    end
  end

private
  def get_paginated_departments
    conditions = ["parent_id IS NULL"]
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @departments = Department.where(conditions.join(' AND ')).order(default_order('m_classes')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def department_params
    params.require(:department).permit(:code, :name, :level)
  end

  def set_department
    @department = Department.find(params[:id])
  end

  def can_view_department
    not_authorized unless current_user.can_view_department?
  end

  def can_manage_department
    not_authorized unless current_user.can_manage_department?
  end
end
