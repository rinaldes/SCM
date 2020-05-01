class SizesController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :size, :description
  before_action :set_size, only: [:show, :destroy, :edit, :update]
  before_filter :can_view_size, only: [:index, :show]
  before_filter :can_manage_size, only: [:new, :create, :edit, :update]

  def generate_details
    @size = Size.find params[:size_id]
  end

  # GET /sizes
  # GET /sizes.json
  def index
    get_paginated_sizes
    respond_to do |format|
      format.html # index.html.erb
      format.js # index.js.erb
    end
  end

  def show
    @size = Size.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    get_paginated_sizes
    @size = Size.new(params[:size])
    respond_to do |format|
      format.html
    end
  end

  # GET /sizes/1/edit
  def edit
    @size = Size.find(params[:id])
    @size_number = @size.sorted_size_details
    respond_to do |format|
      format.html
    end
  end

  # POST /sizes
  # POST /sizes.json
  def create
    size_number = Size.create_number(params)
    @size = Size.new(size_params.merge(code: (("S#{'%03d' % ((Size.last.code.last.to_i rescue 0)+1)}"))))
    respond_to do |format|
      if @size.save
        flash[:notice] = 'Size was successfully created'
      else
        flash[:error] = @size.errors.full_messages.join('<br/>')
      end
      format.js
    end
  end

  # PUT /sizes/1
  # PUT /sizes/1.json
  def update
    @size = Size.find(params[:id])
    old_details = @size.size_details.map(&:id)
    @errors = []
    params[:size][:size_details_attributes].each{|sd|
      @errors << "Size #{sd[1]['size_number']} already in use. Can't be deleted" if sd[1]['size_number'].blank? && sd[1]['id'].present? && ProductSize.find_by_size_detail_id(sd[1]['id'])
    }
    respond_to do |format|
      if @errors.present?
        flash[:error] = @errors.join('<br/>')
      elsif @size.update_attributes(params.require(:size).permit(:description, :code))
        params[:size][:size_details_attributes].each{|sd|
          if sd[1]['size_number'].present?
            if SizeDetail.find_by_id(sd[1]['id']).present?
              SizeDetail.find_by_id(sd[1]['id']).update_attributes(size_number: sd[1]['size_number'])
            else
              SizeDetail.create(size_number: sd[1]['size_number'], size_id: @size.id)
            end
          else
            SizeDetail.find_by_id(sd[1]['id']).delete rescue ''
          end
        }
        flash[:notice] = 'Size was successfully updated.'
      else
        @errors = @size.errors.full_messages
        flash[:error] = (@size.errors.full_messages).join('<br/>')
      end
      format.js
    end
  end

  # DELETE /sizes/1
  def destroy
    if @size.check_transaction && @size.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete size"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete size. data in use"
    end
    get_paginated_sizes
    respond_to do |format|
      format.js
    end
  end

  def search
    @sizes = Size.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @size = Size.new
      format.js
    end
  end

  def autocomplete_size_name
    hash = []
    sizes = Size.limit(7).order("concat(code, ' / ', description)").select("concat(code, ' / ', description) AS name, id")
      .where("LOWER(concat(code, ' / ', description)) like '%#{params[:term]}%'")
    sizes.each do |p|
      hash << {id: p.id, label: p.name, value: p.name, size_details: p.size_details}
    end
    render json: hash
  end

private
  def size_params
    params.require(:size).permit(:description, :code, size_details_attributes: [:size_number])
  end

  def can_view_size
    not_authorized unless current_user.can_view_size?
  end

  def can_manage_size
    not_authorized unless current_user.can_manage_size?
  end

  def set_size
    @size = Size.find_by_id params[:id]
  end
end
