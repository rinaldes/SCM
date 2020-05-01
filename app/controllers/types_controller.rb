class TypesController < ApplicationController
  autocomplete :type, :name
  before_filter :get_paginated_types, except: [:render_404, :search, :autocomplete_type_name]

  # GET /types
  # GET /types.json
  def index
    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  def new
    @type = Type.new
    respond_to do |format|
      format.html
    end
  end

  # GET /types/1/edit
  def edit
    @type = Type.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /types
  # POST /types.json
  def create
    @type = Type.new(type_params)
    @sub_types = params[:subtype_attributes]
    if @type.save
      @sub_types.each do |subtype|
        @subtype = @type.subtype.new
        @subtype.name = subtype["name"]
        @subtype.code = subtype["code"]
        @subtype.save
      end
      flash[:notice] = 'Type was successfully created.'
      redirect_to types_path
    else
      flash[:error] = @type.errors.full_messages
      render "new"
    end
  end

  # PUT /types/1
  # PUT /types/1.json
  def update
    @type = Type.find(params[:id])
    @sub_types = params[:subtype_attributes]
    if @type.update_attributes(type_params)
      Type.where("parent_id = ?", @type.id).delete_all
      @sub_types.each do |subtype|
        @subtype = Type.new
        @subtype.name = subtype["name"]
        @subtype.code = subtype["code"]
        @subtype.parent_id = @type.id
        @subtype.save
      end
      flash[:notice] = 'Type was successfully updated.'
      redirect_to types_path
    else
      flash[:error] = @type.errors.full_messages
      render "edit"
    end
  end

  # DELETE /types/1
  # DELETE /types/1.json
  def destroy
    @type = Type.find(params[:id])
    @parent_type = Type.where(:parent_id => @type.id)
    respond_to do |format|
      if @type.destroy
        @parent_type.destroy_all
        flash.now[:notice] = 'Type was successfully deleted.'
        @type = Type.new
        get_paginated_types
      else
        flash.now[:error] = 'Type can not be removed because it is already in use.'
      end
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

  def detail_sub_type
    @type = Type.find(params[:id])
    @sub_types = SubType.where(:type_id => params[:id]).order("code ASC").paginate(:page => params[:page], :per_page => 10) || []
  end

  def new_sub_type
    @type = Type.find(params[:id])
    @sub_types = SubType.order("code ASC").paginate(:page => params[:page], :per_page => 10) || []
    @sub_type = SubType.new(params[:sub_type])
  end

  def search
    @types = Type.search(params[:search]).paginate(:page => params[:page], :per_page => 100) || []
    respond_to do |format|
      @type = Type.new
      format.js
    end
  end

  def autocomplete_type_name
    hash = []
    branches = Type.where("name LIKE ?", "%#{params[:term]}%").limit(25)
    branches.collect do |p|
      hash << {"id" => p.id, "label" => p.name, "value" => p.name}
    end

    respond_to do |format|
      format.json {render json: hash}
    end
  end

private
  def get_paginated_types
    @types = Type.master.order("code ASC").paginate(:page => params[:page], :per_page => 10) || []
    @type_parents = Type.where("parent_id is NOT NULL ").order("code ASC").paginate(:page => params[:page], :per_page => 10) || []
  end

  def type_params
    params.require(:type).permit(:name, :code, :parent_id)
  end
end