class ProvincesController < ApplicationController
  autocomplete :province, :name

  def provinces_per_regional
    @provinces = Province.where("regional_id=#{params[:regional_id]}").limit(11)
  end
end