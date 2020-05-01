class MclassesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_action :get_departments
  autocomplete :mclass, :name
  autocomplete :department, :name
  # GET /mclasses
  # GET /mclasses.json
 def index
    get_paginated_mclasses
    respond_to do |format|
      format.html
      format.js
      if(params[:a] == "a")
        format.csv { send_data MClass.all.to_csv2 }
      else
        format.csv { send_data MClass.all.to_csv }
      end
    end
  end

  def show
    @mclass = Mclass.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @mclass = Mclass.new(params[:mclass])
    @departments = Department.all.map{|x| [x.name, x.id]}
    @mclasses = Mclass.all.map{|x| [x.name, x.id]}
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /mclasses/1/edit
  def edit
    @mclass = Mclass.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /mclasses
  # POST /mclasses.json
  def create
    init = params[:mclass][:name][0]
    mclass_number = Mclass.create_number(params)
    @mclass = Mclass.new(mclass_params.merge(:code => (('%03d' % ((Mclass.last.code.to_i rescue 0)+1)))))
    if @mclass.save
      flash[:notice] = 'Category was successfully created'
      redirect_to mclasses_path
    else
      flash[:error] = @mclass.errors.full_messages
      render "new"
    end
  end

  # PUT /mclasses/1
  # PUT /mclasses/1.json
  def update
    @mclass = Mclass.find(params[:id])
    if @mclass.update_attributes(mclass_params)
      flash[:notice] = 'Category was successfully updated.'
      redirect_to mclasses_path
    else
      flash[:error] = @mclass.errors.full_messages
      # format.js
      render "edit"
    end
  end

  # DELETE /mclasses/1
  # DELETE /mclasses/1.json
  def destroy
  @mclass = Mclass.find(params[:id])
    @mclass.destroy
    get_paginated_mclasses
    respond_to do |format|
      format.js
    end
  end

  def search
    @mclasses = Mclass.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @mclass = Mclass.new
      format.js
    end
  end

  def get_number
    @mclass_number = Mclass.number(params)
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

  def autocomplete_department_name
    render json: Department.where("parent_id IS NULL AND name like '%#{params[:term]}%'").map { |department| {label: department.name.to_s, value: department.id.to_s} }
  end

private
  def get_paginated_mclasses
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @mclasses = MClass.where(:parent_id => nil).where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def mclass_params
    params.require(:mclass).permit(:code, :name, :department_id, :parent_id, m2classes_attributes: [:id, :code, :code, m3classes_attributes: [:id, :code, :code, m4classes_attributes:
      [:id, :code, :code]]])
  end

  def get_departments
      @departments = Department.all.map { |e| [e.name, e.id] }
    end
end