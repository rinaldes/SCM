class HeadOfficesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :can_view_ho, only: [:index, :show]
  before_filter :can_manage_ho, only: [:new, :create, :edit, :update, :destroy]
  autocomplete :head_office, :office_name
  before_action :set_ho, only: [:show, :destroy, :edit, :update]

  def autocomplete_head_office_office_name
    hash = []
    suppliers = HeadOffice.where("LOWER(office_name) LIKE LOWER('%#{params[:term]}%')").limit(25)
    suppliers.collect do |p|
      hash << {"id" => p.id, "label" => p.office_name, "value" => p.office_name}
    end
    render json: hash
  end

  def destroy
    if @head_office.check_transaction && @head_office.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Office"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete office. data in use"
    end
    get_paginated_head_offices
    respond_to do |format|
      format.js
    end
  end

  def search

    # @head_offices = HeadOffice.search(params[:search]).paginate(:page => params[:page], :per_page => 10) || []
    get_paginated_head_offices
    respond_to do |format|
      # @head_offices = HeadOffice.new
      format.js
    end
  end

  def show
    @head_office = HeadOffice.find(params[:id])
    @depart = OfficeDepartment.where(office_id: params[:id])
  end

  def index
    get_paginated_head_offices
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls {
        filename = "Office_#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.xls"
        send_data(@head_offices.to_xls, :type => "text/xls; charset=utf-8; header=present", :filename => filename)
      }
    end
  end

  def branches_per_regional
    @cities = City.where("regional_id=#{params[:regional_id]}").limit(11)
  end

  def areas_per_branches
    @areas = Area.where("city_id = #{params[:city_id]} AND regional_id = #{params[:regional_id]}").limit(11)
  end

  # POST /suppliers
  # POST /suppliers.json
  def create
    @branch = HeadOffice.new(head_office_params.merge(warehouse: (Branch.find_by_office_name(params[:branch]).office_name rescue nil), code: ("O#{('%03d' % ((HeadOffice.last.code.gsub('O', '').to_i rescue 0)+1))}")))
    if @branch.save
      flash[:notice] = 'Office was successfully created'
      redirect_to head_offices_path
    else
      @regionals = Regional.all
      flash[:error] = @branch.errors.full_messages.join('<br/>')
      user_department
      render "new"
    end
  end

  def edit
    @branch = HeadOffice.find(params[:id])
    @regionals = Regional.all
    user_department
  end

  # POST /suppliers
  # POST /suppliers.json
  def update
    @head_office = HeadOffice.find(params[:id])
    old_departments = @head_office.office_departments.map(&:id)
    if @head_office.update_attributes(head_office_params)
      OfficeDepartment.where(id: old_departments).delete_all
      flash[:notice] = 'Office was successfully updated'
      redirect_to head_offices_path
    else
      user_department
      flash[:error] = @head_office.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def new
    @branch = HeadOffice.new
    @regionals = Regional.all
    user_department
    respond_to do |format|
      format.html
    end
  end

  private
  

  def head_office_params
    params.require(:head_office).permit(
      :office_name, :description, :is_active, :phone_number, :area, :address, :lat, :long, :regional, :email, :area, :province, :city, :districts, :zip_code, :rt, :rw, :village, :area_id, :city_id, :regional_id,
      :city_name, office_departments_attributes: [:department_id])
  end

  def can_view_ho
    not_authorized unless current_user.can_view_ho?
  end

  def can_manage_ho
    not_authorized unless current_user.can_manage_ho?
  end

  def user_department
    @users = User.joins(:role).map{|user|[user.username, user.id]}
    load_departments
  end

  def set_ho
    @head_office = HeadOffice.find params[:id]
  end
end
