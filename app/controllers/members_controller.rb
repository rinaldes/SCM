class MembersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :get_paginated_members, only: [:index, :new, :edit, :create, :update, :destroy, :expire]
  before_filter :can_view_member, only: [:index, :show]
  before_filter :can_manage_member, only: [:new, :create, :edit, :update, :destroy]

  # GET /members
  # GET /members.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Member.all.to_csv2 }
      else
        format.csv { send_data Member.all.to_csv }
      end
    end
  end

  def show
    @member = Member.find(params[:id])
  end

  def import
    if params[:file].present?
      @pesan = Member.import(params[:file])
      if @pesan.present?
        flash[:error] = @pesan
      else
        flash[:notice] = "Member imported."
      end
    else
      flash[:error] = "Please attach CSV File!"
    end
    redirect_to members_path
  end

  def new
    @member = Member.new(params[:member])
    respond_to do |format|
      format.html
    end
  end

  # GET /members/1/edit
  def edit
    @member = Member.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /members
  # POST /members.json
  def create
    @member = Member.new(member_params.merge(code: (('%03d' % ((Member.last.code.to_i rescue 0)+1)))))
    if @member.save
      flash[:notice] = "Member was successfully created."
      redirect_to members_path
    else
      flash[:error] = @member.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  # PUT /members/1
  # PUT /members/1.json
  def update
    @member = Member.find(params[:id])
    if @member.update_attributes(member_params)
      flash[:notice] = "Member was successfully updated."
      redirect_to members_path
    else
      flash[:error] = @member.errors.full_messages.join('<br/>')
      render "edit"
    end
  end

  # DELETE /members/1
  # DELETE /members/1.json
  def destroy
    @member = Member.find(params[:id])
    respond_to do |format|
      if @member.destroy
        flash.now[:notice] = "Member was successfully deleted"
      else
        flash.now[:error] = @member.errors.full_messages
      end
      format.js
    end
  end

  def search
    @members = Member.search(params[:search]).paginate(:page => params[:page], :per_page => 100) || []

    respond_to do |format|
      @member = Member.new
      format.js
    end
  end

  def setting_point
    @points = SettingPointMember.paginate(:page => params[:page], :per_page => 100)
    @setting = SettingPointMember.new
  end

  def create_setting_point
    @setting = SettingPointMember.new(params[:setting_point_member])
    @setting.price = params[:setting_point_member][:price].split(".").join("")
    respond_to do |format|
      if @setting.save
        @member = "Discount Member was successfully created."
        format.js
      else
        flash.now[:error] = @setting.errors.full_messages
        format.js
      end
    end
  end

  def discount
    get_paginated_discount_member
    @discount = Discount.new
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create_member_discount
    @discount = Discount.new(params[:discount].merge(item_type: Member.to_s, start_date: DateTime.now.strftime('%Y-%m-%d')))
    respond_to do |format|
      get_paginated_discount_member
      if @discount.save
        @discount = Discount.new
        flash.now[:notice] = "Discount Member was successfully created."
        format.js
      else
        flash.now[:error] = @discount.errors.full_messages
        format.js
      end
    end
  end

  def edit_member_discount
    @discount = Discount.find(params[:id])
  end

  def update_member_discount
    @discount = Discount.find(params[:id])
    respond_to do |format|
      get_paginated_discount_member
      if @discount.update_attributes(params[:discount])
        @discount = Discount.new
        flash.now[:notice] = "Discount Member was successfully updated."
        format.js
      else
        flash.now[:error] = @discount.errors.full_messages
        format.js
      end
    end
  end

  def delete_member_discount
    @discount = Discount.find(params[:id])
    @discount.destroy

    respond_to do |format|
      get_paginated_discount_member
      @discount = Discount.new
      flash.now[:notice] = "Discount Member was successfully deleted"
      format.js
    end
  end

  def expire
    @member = Member.find(params[:id])
    if @member.reactivate
      flash[:notice] = "Member successfully activated back."
      redirect_to members_path
    else
      respond_to do |format|
        flash.now[:error] = @member.errors.full_messages
        format.js
      end
    end
  end

  private
  def member_params
    params.require(:member).permit(:code, :card_number, :name, :birthday, :address, :hp, :email, :gender, :member_level_id, :credit_limit)
  end

  def can_view_member
    not_authorized unless current_user.can_view_member?
  end

  def can_manage_member
    not_authorized unless current_user.can_manage_member?
  end
end
