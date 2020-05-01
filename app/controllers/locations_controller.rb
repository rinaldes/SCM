class LocationsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  # before_action :set_location, only: [:show, :edit, :update, :destroy]
  autocomplete :location, :name
  # respond_to :html

  def index
    get_paginated_locations
    #@locations = Location.all
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Location.all.to_csv2 }
      else
        format.csv { send_data Location.all.to_csv }
      end
    end
  end

  def show
    @location = Location.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @provinces = Province.all

    @location = Location.new(jenis: "kota/kabupaten", code: (("K#{sprintf '%03d', ((MClass.where("parent_id IS NOT NULL AND level=1").order("id DESC").limit(1).last.code.gsub('K', '').to_i rescue 0)+1)}")))
    # load_provinces
    #respond_with(@location)
  end

  def edit
    @location = Location.find params[:id]
    @provinces = Province.all
    # load_provinces
  end
  def add_sub_type
    @location = Location.find_by_id params[:location_id]
    @blank_state = true
    respond_to do |format|
      format.js
    end
  end
  def create_sub_type sub_types, parent
    sub_types.values.each_with_index{|location_params, i|
      lv = parent.level+1
      if lv == 2
        jenis='kecamatan'
      elsif lv == 3
        jenis='kelurahan/desa'
      end
      # province = Province.where(name:params[:province]).first
      location = Location.new name: location_params[:name],level: parent.level+1,jenis: jenis,parent_id: parent.id, code: "#{parent.code}.#{i+1}"
      create_sub_type location_params[:location_attributes], location if location.save && location.set_path && location_params[:location_attributes].present?
    }
  end
  def update_sub_type sub_type, parent
    sub_type.values.each_with_index{|location_params, i|
      location = Location.find_by_code location_params[:code]
      if location
        unless location.update_attributes name: location_params[:name]
          @errors << location.errors.full_messages.join('<br/>')
          @quit = true
        end
      else
        unless location.save
        location = Location.new name: location_params[:name], level: parent.level+1, parent_id: parent.id, code:params[:code]
          @errors << location.errors.full_messages.join('<br/>')
          @quit = true
        end
      end
      break if @quit
      location.set_path
      update_sub_type location_params[:location_attributes], location if location_params[:location_attributes].present?
    }
  end

  def create
    @location = Location.new location_params.merge(level: 1)
    if @location.save
      @location.set_path
      create_sub_type params[:location][:location_attributes], @location if params[:location][:location_attributes].present?
      flash[:notice] = "Successfully created"
      redirect_to locations_url
    else
      load_provinces
      flash[:error] = @location.errors.full_messages.join('<br/>')
      render :new
    end
  end

  def update
    @location = Location.find(params[:id])
    @quit =  nil
    @errors = []
    @location.update(location_params)
    # respond_with(@location)
    respond_to do |format|
      hash_to_be_updated = {province_id: params[:location][:province_id], name: params[:location][:name]}
      if @location.update_attributes(hash_to_be_updated) && @location.set_path && @quit.nil?
        Location.where("code IN ('#{params[:tobe_deleted].split(', ').reverse.join("', '").chop.chop.chop.chop}')").delete_all
        update_sub_type params[:location][:location_attributes], @location if params[:location][:location_attributes].present?
        if @quit.nil?
          format.js
        else
          # load_provinces
          @errors.push(@location.errors.full_messages.join('<br/>')) if @location.errors.full_messages.join('<br/>').present?
          flash[:error] = @errors.join('<br/>')
          format.js
        end
      else
        # load_provinces
        flash[:error] = @location.errors.full_messages.join('<br/>')
        format.js
      end
    end
  end

  def destroy
    @location = Location.find(params[:id])
    if @location.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete location"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete location"
    end
    get_paginated_locations
    respond_to do |format|
      format.js
    end
  end
  def import
    import_result = Location.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to locations_path
  end

  private
    def set_location
      @location = Location.find(params[:id])
    end

    def location_params
      params.require(:location).permit( :code, :name, :parent_id, :province_id, :jenis)
    end
end
