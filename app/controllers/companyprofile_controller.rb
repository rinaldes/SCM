class CompanyprofileController < ApplicationController
  def index
    @company_profiles = Entity.find_by_domain_name(request.base_url.sub(/^https?\:\/\//, ''))
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
  end

  def edit
    @company_profiles =  Entity.find_by_domain_name(request.base_url.sub(/^https?\:\/\//, ''))
    respond_to do |format|
      format.html
    end
  end

  def update
    @company_profiles =  Entity.find_by_domain_name(request.base_url.sub(/^https?\:\/\//, ''))
    if @company_profiles.update_attributes(company_profiles_params)
      if !params[:image_url].blank?
        @company_profiles.image.clear
        @company_profiles.image = URI.parse(params[:image_url])
        @company_profiles.save!
      end
      flash[:notice] = "Company Profile was successfully updated."
      redirect_to companyprofile_index_path
    else
      flash.now[:error] = @company_profiles.errors.full_messages
      render 'edit'
    end
  end

  private
    def company_profiles_params
      params.require(:entity).permit(:name, :address, :npwp, :npwp_address, :logo, :favicon, :title, :footer, :custom_css)
    end
end
