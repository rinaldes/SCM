class BranchesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :branch, :office_name
  before_filter :can_view_branch, only: [:index, :show]
  before_filter :can_manage_branch, only: [:new, :create, :edit, :update, :destroy]

  def destroy
    @branch = Branch.find(params[:id])
    if @branch.check_transaction && @branch.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete branch"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete branch. data in use"
    end
    get_paginated_branches
    respond_to do |format|
      format.js
    end
  end

  # POST /suppliers
  # POST /suppliers.json
  def update
    @branch = Branch.find(params[:id])
    office_departments = @branch.office_departments.map(&:id).join(', ')
    if @branch.update_attributes(branch_params.merge(head_office_id: (Branch.find_by_office_name(params[:branch2]).id rescue nil), province_id: (Province.find_by_name(params[:province]).id rescue nil)))
      @branch.office_departments.where("id IN (#{office_departments})").delete_all if office_departments.present?
      flash[:notice] = t(:successfully_updated)
      redirect_to branches_path
    else
      @regionals = Regional.all
      @head_offices = HeadOffice.all
      @users = User.all.map{|user|[user.username, user.id]}
      load_departments
      flash[:error] = @branch.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def edit
    @regionals = Regional.all
    @branch = Branch.find(params[:id])
    @head_offices = HeadOffice.all
    @users = User.all.map{|user|[user.username, user.id]}
    load_departments
  end

  def new
    @regionals = Regional.all
    @branch = Branch.new
    @users = User.joins(:role).limit(7).map{|user|[user.username, user.id]}
    @head_offices = HeadOffice.all
    load_departments
    respond_to do |format|
      format.html
    end
  end

  # POST /suppliers
  # POST /suppliers.json
  def create
    @branch = Branch.new(
      branch_params.merge(
        head_office_id: (Branch.find_by_username(params[:branch2]).id rescue nil),
        code: ("#{('%03d' % ((Branch.last.code.gsub('M', '').to_i rescue 0)+1))}")
      )
    )
    @head_offices = HeadOffice.all
    @users = User.joins(:role).limit(7).map{|user|[user.username, user.id]}
    if @branch.save
      flash[:notice] = 'Store successfully created'
      redirect_to branches_path
    else
      @head_offices = HeadOffice.all
      @regionals = Regional.all
      @users = User.joins(:role).limit(7).map{|user|[user.username, user.id]}
      load_departments
      flash[:error] = @branch.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def index
    get_paginated_branches
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls {
        filename = "Branch_#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}.xls"
        send_data(@branches.to_xls, :type => "text/xls; charset=utf-8; header=present", :filename => filename)
      }
      format.json{
        render json: @branches.map{|branch|
          sales_sum = Sale.where("store_id=#{branch.id}").map(&:total_price).sum
          target_sec2015 = 10000000
          {
            office_name: branch.office_name, lat: branch.lat, long: branch.long, achievement: [(sales_sum/target_sec2015*100).round(2), 100].min, target_sec2015: target_sec2015,
              secsales: sales_sum
          }
        }.to_json
      }
      if(params[:a] == "a")
        format.csv {
          send_data(Branch.all.to_csv2, :filename => "Store.csv")
        }
      else
        format.csv {
          send_data(Branch.all.to_csv, :filename => "Store.csv")
        }
      end
    end
  end

  def import
    import_result = Branch.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to branches_path
  end

  def show
    @branch = Branch.find(params[:id])
    @departments = @branch.departments
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  def branches_per_regional
    @branches = City.where("regional_id=#{params[:regional_id]}").limit(11)
  end

  def areas_per_branches
    @areas = Area.where("regional_id=#{params[:regional_id]} AND city_id=#{params[:city_id]}").limit(11)
  end

  private
  def branch_params
    params.require(:branch).permit(
      :office_name, :description, :phone_number, :area, :address, :lat, :long,
      :regional, :email, :area, :province, :city, :districts, :zip_code, :rt,
      :rw, :village, :area_id, :province_id, :district_id, :city_id,
      :regional_id, :city_name, :city_name, :npwp, :is_active,
      office_departments_attributes: [:department_id]
    )
  end

  def can_view_branch
    not_authorized unless current_user.can_view_branch?
  end

  def can_manage_branch
    not_authorized unless current_user.can_manage_branch?
  end
end
