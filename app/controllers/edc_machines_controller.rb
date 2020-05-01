class EdcMachinesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_by_id, only: [:show, :destroy, :edit]
  before_filter :can_view_bank, only: [:index, :show]
  before_filter :can_manage_bank, only: [:new, :create, :edit, :update, :destroy]

  def show
  end

  # GET /edc_machines/new
  # GET /edc_machines/new.json
  def new
    @edc_machine = EdcMachine.new
    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @edc_machine }
      format.xls
    end
  end

  def import
    if params[:file].present?
      if %w(text/csv application/vnd.ms-excel).include?params[:file].content_type
        EdcMachine.import(params[:file])
        flash[:notice] = "EDC Machine imported."
      else
        flash[:error] = "File must be a CSV file"
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to edc_machines_path
  end

  # POST /edc_machines
  # POST /edc_machines.json
  def create
    @edc_machine = EdcMachine.new(edc_machine_params)
    if @edc_machine.save
      flash[:notice] = 'EDC Machine was successfully created.'
      redirect_to edc_machines_path
    else
      flash[:error] = @edc_machine.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  def destroy
    @edc_machine.destroy
    get_paginated_edc_machines
    respond_to do |format|
      format.js
    end
  end

  # GET /suppliers/1/edit
  def edit
    respond_to do |format|
      format.html
    end
  end

  # PUT /suppliers/1
  # PUT /suppliers/1.json
  def update
    @edc_machine = EdcMachine.find(params[:id])
    if @edc_machine.update_attributes(edc_machine_params)
      flash[:notice] = 'EDC Machine was successfully updated.'
      redirect_to edc_machines_path
    else
      flash[:error] = @edc_machine.errors.full_messages.join('<br/>')
      render "edit"
    end
  end

  def index
    get_paginated_edc_machines
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data EdcMachine.all.to_csv2 }
      else
        format.csv { send_data EdcMachine.all.to_csv }
      end
    end
  end

  private
  def get_paginated_edc_machines
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @edc_machines = EdcMachine.where(conditions.join(' AND ')).order(default_order('edc_machines')).paginate(page: params[:page], per_page: 10) || []
  end

  def edc_machine_params
    params.require(:edc_machine).permit(:bank_name, :branch, :edc_serial_number, :account_number, :owner)
  end

  def find_by_id
    @edc_machine = EdcMachine.find_by_id(params[:id])
  end

  def can_view_bank
    not_authorized unless current_user.can_view_bank?
  end

  def can_manage_bank
    not_authorized unless current_user.can_manage_bank?
  end
end
