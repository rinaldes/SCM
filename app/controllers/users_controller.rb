class UsersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  skip_before_filter :require_no_authentication
  autocomplete :user, :username
  before_filter :find_user, only: [:show, :change_status, :change_password, :post_change_password]
  before_filter :init_verify, only: [:verify_user, :verification_request]
  before_filter :can_view_user, only: [:index, :show]
  before_filter :can_manage_user, only: [:new, :create, :edit, :update]

  def post_change_password
    @user.update_attributes(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation])
    respond_to do |format|
        #@user.update_attributes(user_params)
      if @user.update_attributes(password: params[:user][:password], password_confirmation: params[:user][:password_confirmation], pos_password: Digest::MD5.hexdigest(params[:user][:password]))
        flash[:notice] = "Password was successfully updated."
        format.html { redirect_to users_path }
      else
        flash.now[:error] = @user.errors.full_messages.uniq.join('<br/>')
        format.html {render 'change_password'}
      end
    end
  end

  def change_password
  end

  # GET /users
  def index
    get_paginated_users
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data User.all.to_csv2 }
      else
        format.csv { send_data User.all.to_csv }
      end
    end
  end

  def import
    import_result = User.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to users_path
  end

  def change_status
    flash[:notice] = "#{@user.update_attribute(:status, current_user.is_superadmin? && @user.status == User::AKTIF ? User::TIDAK_AKTIF : User::AKTIF) ? 'Success' : 'Fail'} change status #{@user.full_name}"
    @users = User.all
    respond_to do |format|
      format.js
    end
  end

  def autocomplete_name
    hash = []
    supplier = User.joins(:role).where("LOWER(username) like '%#{params[:term]}%'").limit(11).order('username')
    supplier.collect do |p|
      hash << {"id" => p.id, "label" => p.username, "value" => p.username}
    end
    render json: hash
  end

  # GET /users/1
  def show
    @allowable_pages = @user.allowable_pages
    @pages = Page.all

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /users
  def create
    params[:user][:password] = params[:user][:username]
    @user = User.new(params[:user])
    respond_to do |format|
      if @user.save
        flash[:notice] = 'User was successfully created.'
        format.js
      else
        flash[:error] = @user.errors.full_messages
        format.js#html { render action: "new" }
      end
    end
  end

  # PUT /users/1
  def update
    @user = User.find(params[:id])
    respond_to do |format|
      if @user.update_attributes(user_params)
      #if @user.update_without_password(user_params)
        flash[:notice] = "User was successfully updated."
        format.html { redirect_to users_path }
      else
        flash.now[:error] = @user.errors.full_messages
        format.html {render 'edit'}
      end
    end
  end

  # DELETE /users/1
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    get_paginated_users
    respond_to do |format|
      format.js
    end
  end



  def verification_request
    respond_to do |format|
      format.js
    end
  end

  def verify_user
    respond_to do |format|
      format.js
    end
  end

  def init_verify
    @data = params[:data]
    @id = params[:id]
    @officer = User.verify(params[:user])
  end

  def page_setting
    user = User.find(params[:format])
    pages = user.allowable_pages
    params[:page_id] = [] if params[:page_id].nil?
    old_pages = pages.map{|x| x.page_id} - params[:page_id]
    new_pages = params[:page_id] - pages.map{|x| x.page_id}
    new_pages.each do |page|
      pages.create(:page_id => page)
    end
    old_pages.each do |page|
      pages.find_by_user_id_and_page_id(user.id, page).destroy
    end
    flash[:notice] = 'User allowable pages was successfully updated.'
    redirect_to user_path(user.id)
  end

private
  def find_user
    @user = User.find(params[:id])
  end

  def get_paginated_users
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
    } if params[:search].present?
    @users = User.joins(
      "INNER JOIN roles ON users.role_id=roles.id"
    ).joins(
      "LEFT JOIN offices ON users.branch_id=offices.id"
    ).select(
      "users.*, concat(first_name, ' ', last_name) AS fullname, roles.name AS role_name, (SELECT office_name FROM offices WHERE id=users.branch_id LIMIT 1) AS branch_name"
    ).where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: PER_PAGE) || []
  end

  def user_params
    params.require(:user).permit(:first_name, :last_name, :gender, :birth_place, :birth_date, :email, :role_id, :status, :username, :image, :password, :password_confirmation,
      :head_office_id, :branch_id)
  end

  def can_view_user
    not_authorized unless current_user.can_view_user?
  end

  def can_manage_user
    not_authorized unless current_user.can_manage_user?
  end
end
