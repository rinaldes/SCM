class MemberLevelsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :member_level, :description
  before_filter :can_view_member_level, only: [:index, :show]
  before_filter :can_manage_member_level, only: [:new, :create, :edit, :update]

  # GET /member_levels
  # GET /member_levels.json
  def index
    get_paginated_member_levels
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data MemberLevel.all.to_csv2 }
      else
        format.csv { send_data MemberLevel.all.to_csv }
      end
    end
  end

  def import
    MemberLevel.import(params[:file])
    redirect_to member_levels_path, notice: "Member Level imported."
  end

  def show
    @member_level = MemberLevel.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @member_level = MemberLevel.new(params[:member_level])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /member_levels/1/edit
  def edit
    @member_level = MemberLevel.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /member_levels
  # POST /member_levels.json
  def create
    init = params[:member_level][:description][0]
    member_level_number = MemberLevel.create_number(params)
    @member_level = MemberLevel.new(member_level_params)
    if @member_level.save
      flash[:notice] = 'Successfully created'
      redirect_to member_levels_path
    else
      flash[:error] = @member_level.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  # PUT /member_levels/1
  # PUT /member_levels/1.json
  def update
    @member_level = MemberLevel.find(params[:id])
    if @member_level.update_attributes(member_level_params)
      flash[:notice] = 'Member Level was successfully updated.'
      redirect_to member_levels_path
    else
      flash[:error] = @member_level.errors.full_messages
      # format.js
      render "edit"
    end
  end

  # DELETE /member_levels/1
  # DELETE /member_levels/1.json
  def destroy
  @member_level = MemberLevel.find(params[:id])
    @member_level.destroy
    get_paginated_member_levels
    respond_to do |format|
      format.js
    end
  end

  def search
    @member_levels = MemberLevel.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @member_level = MemberLevel.new
      format.js
    end
  end

  def get_number
    @member_level_number = MemberLevel.number(params)
    respond_to do |format|
      format.js
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

private
  def member_level_params
    params.require(:member_level).permit(:level, :description, :minimum_amount, :discount_percent, :is_credit)
  end

  def can_view_member_level
    not_authorized unless current_user.can_view_member_level?
  end

  def can_manage_member_level
    not_authorized unless current_user.can_manage_member_level?
  end
end
