class ProductPlanogramsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:create, :destroy]
  def index
    planogram = Planogram.find(params[:planogram_id])
    @product_planograms = planogram.product_planograms
    @products = Product.all
  end

  def new
    planogram = Planogram.find(params[:planogram_id])
    @product_planograms = planogram.product_planograms.build

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    planogram = Planogram.find(params[:planogram_id])
    @product_planogram = planogram.product_planograms.create(:product_id => params[:product_id])

    respond_to do |format|
      if @product_planogram.save
        planogram = Planogram.find(params[:planogram_id])
        @product_planograms = planogram.product_planograms
        format.js
      end
    end
  end

  def destroy
    planogram = Planogram.find(params[:planogram_id])
    @product_planogram = planogram.product_planograms.find(params[:id])
    @product_planogram.destroy
    respond_to do |format|
      planogram = Planogram.find(params[:planogram_id])
      @product_planograms = planogram.product_planograms
      format.js
    end
  end
end
