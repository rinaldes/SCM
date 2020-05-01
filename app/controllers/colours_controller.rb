class ColoursController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :colour, :name
  before_filter :can_view_colour, only: [:index, :show]
  before_filter :can_manage_colour, only: [:new, :create, :edit, :update]

  # GET /colours
  # GET /colours.json
  def index
    get_paginated_colours
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Colour.all.to_csv2 }
      else
        format.csv { send_data Colour.all.to_csv }
      end
    end
  end

  def import
    import_result = Colour.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to colours_path
  end

  def show
    @colour = Colour.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @colour = Colour.new(params[:colour])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /colours/1/edit
  def edit
    @colour = Colour.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /colours
  # POST /colours.json
  def create
    init = params[:colour][:name][0]
    colour_number = Colour.create_number(params)
    @colour = Colour.new(colour_params.merge(code: ("C#{('%03d' % ((Colour.last.code.gsub('C', '').to_i rescue 0)+1))}")))
    if @colour.save
      flash[:notice] = 'Colour was successfully created'
      redirect_to colours_path
    else
      flash[:error] = @colour.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  # PUT /colours/1
  # PUT /colours/1.json
  def update
    @colour = Colour.find(params[:id])
    if @colour.update_attributes(colour_params)
      flash[:notice] = 'Colour was successfully created'
      redirect_to colours_path
    else
      flash[:error] = @colour.errors.full_messages.join('<br/>')
      # format.js
      render "edit"
    end
  end

  # DELETE /colours/1
  # DELETE /colours/1.json
  def destroy
    @colour = Colour.find(params[:id])
    if @colour.check_transaction && @colour.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete colour"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete colour. data in used"
    end
    get_paginated_colours
    respond_to do |format|
      format.js
    end
  end

  def search
    @colours = Colour.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @colour = Colour.new
      format.js
    end
  end

  def get_number
    @colour_number = Colour.number(params)
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
  def colour_params
    params.require(:colour).permit(:code, :name)
  end

  def can_view_colour
    not_authorized unless current_user.can_view_colour?
  end

  def can_manage_colour
    not_authorized unless current_user.can_manage_colour?
  end
end
