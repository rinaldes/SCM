class ToDoListsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :to_do_list, :name
  #before_filter :can_view_to_do_list, only: [:index, :show]
  #before_filter :can_manage_to_do_list, only: [:new, :create, :edit, :update]

  before_filter :set_current_user

  def set_current_user
    ToDoList.current_user = current_user
  end

  def index
    get_paginated_to_do_lists
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data ToDoList.all.to_csv2 }
      else
        format.csv { send_data ToDoList.all.to_csv }
      end
    end
  end

  def import
    ToDoList.import(params[:file])
    redirect_to to_do_lists_path, notice: "To Do List imported."
  end

  def show
    @to_do_list = ToDoList.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @ho = Office.all
    @to_do_list = ToDoList.new(params[:to_do_list])
    respond_to do |format|
      format.html
    end
  end

  def edit
    @to_do_list = ToDoList.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def create
    @to_do_list = ToDoList.new(to_do_list_params.merge(:code => (('%03d' % ((ToDoList.last.code.to_i rescue 0)+1)))))
    if !params['office'].blank?
      params['office'].each do |office_id|
        @to_do_list.branch_to_do_lists.new(office: Office.find(office_id))
      end
    end

    if @to_do_list.save
      flash[:notice] = 'To Do List was successfully created'
      redirect_to to_do_lists_path
    else
      flash[:error] = @to_do_list.errors.full_messages
      render "new"
    end
  end

  def update
    @to_do_list = ToDoList.find(params[:id])
    if @to_do_list.update_attributes(to_do_list_params)
      flash[:notice] = 'To Do List was successfully updated.'
      redirect_to to_do_lists_path
    else
      flash[:error] = @to_do_list.errors.full_messages
      render "edit"
    end
  end

  def destroy
    @to_do_list = ToDoList.find(params[:id])
    @to_do_list.destroy
    get_paginated_to_do_lists
    respond_to do |format|
      format.js
    end
  end

  def search
    @to_do_lists = ToDoList.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @to_do_list = ToDoList.new
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
  def to_do_list_params
    params.require(:to_do_list).permit(:date, :end_at, :time, :description, :tujuan, :image, :code, :user_id, :status)
  end

  def can_view_to_do_list
    not_authorized unless current_user.can_view_to_do_list?
  end

  def can_manage_to_do_list
    not_authorized unless current_user.can_manage_to_do_list?
  end
end
