class AdsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :ad, :url
  #before_filter :can_view_ad, only: [:index, :show]
  #before_filter :can_manage_ad, only: [:new, :create, :edit, :update]

  # GET /ads
  # GET /ads.json
  def index
    get_paginated_ads
    respond_to do |format|
      format.html
      format.js
      format.xls
      if(params[:a] == "a")
        format.csv { send_data Ad.all.to_csv2 }
      else
        format.csv { send_data Ad.all.to_csv }
      end
    end
  end

  def import
    import_result = Ad.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to ads_path
  end

  def show
    @ad = Ad.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def new
    @ad = Ad.new(params[:ad])
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /ads/1/edit
  def edit
    @ad = Ad.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /ads
  # POST /ads.json
  def create
    init = params[:ad][:url][0]
    ad_number = Ad.create_number(params)
    @ad = Ad.new(ad_params)
    if @ad.save
      flash[:notice] = 'Ad was successfully created'
      redirect_to ads_path
    else
      flash[:error] = @ad.errors.full_messages.join('<br/>')
      render "new"
    end
  end

  # PUT /ads/1
  # PUT /ads/1.json
  def update
    @ad = Ad.find(params[:id])
    if @ad.update_attributes(ad_params)
      flash[:notice] = 'Ad was successfully created'
      redirect_to ads_path
    else
      flash[:error] = @ad.errors.full_messages.join('<br/>')
      # format.js
      render "edit"
    end
  end

  # DELETE /ads/1
  # DELETE /ads/1.json
  def destroy
    @ad = Ad.find(params[:id])
    if @ad.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete ad"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete ad. data in used"
    end
    get_paginated_ads
    respond_to do |format|
      format.js
    end
  end

  def search
    @ads = Ad.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @ad = Ad.new
      format.js
    end
  end

  def get_number
    @ad_number = Ad.number(params)
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
  def ad_params
    params.require(:ad).permit(:url, :ad_type, :valid_until, :valid_from, :store)
  end

  def can_view_ad
    not_authorized unless current_user.can_view_ad?
  end

  def can_manage_ad
    not_authorized unless current_user.can_manage_ad?
  end
end
