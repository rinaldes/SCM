class PosMachinesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :pos_machine, :name
  before_filter :can_view_pos_machine, only: [:index, :show]
  before_filter :can_manage_pos_machine, only: [:new, :create, :edit, :update]

  def index
    get_paginated_pos_machines
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data PosMachine.all.to_csv2 }
      else
        format.csv { send_data PosMachine.all.to_csv }
      end
    end
  end

  def import
    import_result = PosMachine.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to pos_machines_path
  end

  def show
    @pos_machine = PosMachine.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @pos_machine = PosMachine.new(params[:pos_machine])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /pos_machines/1/edit
  def edit
    @pos_machine = PosMachine.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /pos_machines
  # POST /pos_machines.json
  def create
    init = params[:pos_machine][:name][0]
    pos_machine_number = PosMachine.create_number(params)
    @pos_machine = PosMachine.new(pos_machine_params)
    if @pos_machine.save
      flash[:notice] = 'Pos Machine Created'
      redirect_to pos_machines_path
    else
      flash[:error] = @pos_machine.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  # PUT /pos_machines/1
  # PUT /pos_machines/1.json
  def update
    @pos_machine = PosMachine.find(params[:id])
    if @pos_machine.update_attributes(pos_machine_params)
      flash[:notice] = 'Pos Machine Updated'
      redirect_to pos_machines_path
    else
      flash[:error] = @pos_machine.errors.full_messages.join('<br/>')
      # format.js
      render "edit"
    end
  end

  # DELETE /pos_machines/1
  # DELETE /pos_machines/1.json
  def destroy
    @pos_machine = PosMachine.find(params[:id])
    if @pos_machine.check_transaction && @pos_machine.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete Pos Machine"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete Pos Machine. data in used"
    end
    get_paginated_pos_machines
    respond_to do |format|
      format.js
    end
  end

  def search
    @pos_machines = PosMachine.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @pos_machine = PosMachine.new
      format.js
    end
  end

  def get_number
    @pos_machine_number = PosMachine.number(params)
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
  def pos_machine_params
    params.require(:pos_machine).permit(:name, :office_id, :hide_empty_stock, :enable_ppn, :enable_minus_stock, :enable_loss_price, :receipt_footer, :eod_footer)
  end

  def can_view_pos_machine
    not_authorized unless current_user.can_view_pos_machine?
  end

  def can_manage_pos_machine
    not_authorized unless current_user.can_manage_pos_machine?
  end
end