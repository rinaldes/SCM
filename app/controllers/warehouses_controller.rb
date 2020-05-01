class WarehousesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :warehouse, :office_name
  #before_filter :can_view_warehouse, only: [:index, :show]
  #before_filter :can_manage_warehouse, only: [:new, :create, :edit, :update, :destroy]

  def destroy
    @warehouse = Warehouse.find(params[:id])
    if @warehouse.check_transaction && @warehouse.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete warehouse"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete warehouse. data in use"
    end
    get_paginated_warehouses
    respond_to do |format|
      format.js
    end
  end

  def update
    @warehouse = Warehouse.find(params[:id])
    office_departments = @warehouse.office_departments.map(&:id).join(', ')
    if @warehouse.update_attributes(warehouse_params.merge(head_office_id: (Branch.find_by_office_name(params[:branch]).id rescue nil)))
      @warehouse.office_departments.where("id IN (#{office_departments})").delete_all if office_departments.present?
      flash[:notice] = t(:successfully_updated)
      redirect_to warehouses_path
    else
      @head_offices = HeadOffice.all
      @users = User.all.map{|user|[user.username, user.id]}
      load_departments
      flash[:error] = @warehouse.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def edit
    @branch = Warehouse.find(params[:id])
    @regionals = Regional.all
    @branches = Branch.all
    @head_offices = HeadOffice.all
    @users = User.all.map{|user|[user.username, user.id]}
    load_departments
  end

  def new
    @branch = Warehouse.new
    @regionals = Regional.all
    @provinces = Province.all
    @users = User.joins(:role).limit(7).map{|user|[user.username, user.id]}
    @branches = Branch.all
    load_departments
    respond_to do |format|
      format.html
    end
  end

  def create
    @branch = Warehouse.new(warehouse_params.merge(head_office_id: (Branch.find_by_office_name(params[:branch]).id rescue nil), code: ("W#{('%03d' % ((Warehouse.last.code.gsub('W', '').to_i rescue 0)+1))}")))
    @head_offices = HeadOffice.all
    @users = User.joins(:role).limit(7).map{|user|[user.username, user.id]}
      if @branch.save
      flash[:notice] = 'Warehouse successfully created'
      redirect_to warehouses_path
    else
      @regionals = Regional.all
      @head_offices = HeadOffice.all
      @users = User.joins(:role).limit(7).map{|user|[user.username, user.id]}
      @regionals = Regional.all
      load_departments
      flash[:error] = @branch.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def index
    get_paginated_warehouses
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls {
        filename = "Warehouse_#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.xls"
        send_data(@warehouses.to_xls, :type => "text/xls; charset=utf-8; header=present", :filename => filename)
      }
      format.json{
        render json: @warehouses.map{|warehouse|
          sales_sum = Sale.where("store_id=#{warehouse.id}").map(&:total_price).sum
          target_sec2015 = 10000000
          {
            office_name: warehouse.description, lat: warehouse.lat, long: warehouse.long, achievement: [(sales_sum/target_sec2015*100).round(2), 100].min, target_sec2015: target_sec2015,
              secsales: sales_sum
          }
        }.to_json
      }
    end
  end

  def show
    @warehouse = Warehouse.find(params[:id])
    @departments = @warehouse.departments
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def branches_per_regional
    @branches = City.where("regional_id=#{params[:regional_id]}").limit(11)
  end

  def areas_per_branches
    @areas = Area.where("city_id = #{params[:city_id]} AND regional_id = #{params[:regional_id]}").limit(11)
  end

  private
  def warehouse_params
    params.require(:warehouse).permit(
      :office_name, :description, :phone_number, :area, :address, :lat, :long, :regional, :email, :area, :province, :city, :districts, :zip_code, :rt, :rw, :village, :area_id, :city_id, :regional_id,
      :city_name, office_departments_attributes: [:department_id]
    )
  end

  def can_view_warehouse
    not_authorized unless current_user.can_view_warehouse?
  end

  def can_manage_warehouse
    not_authorized unless current_user.can_manage_warehouse?
  end
end
