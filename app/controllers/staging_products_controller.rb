class StagingProductsController < ApplicationController
  def index
    paginating_staging_products
    respond_to do |format|
      format.html
      format.js
      format.csv { send_data DataCenterProduct.where("article IN(#{session[:selected_products].map(&:inspect).join(', ').gsub /"/, "'"})").to_csv }
    end
  end

  def get_selected_products
    if session[:selected_products].include?(params[:id])
      session[:selected_products] = session[:selected_products] - params[:id].split()
    else
      session[:selected_products] << params[:id]
    end
  end

  def sync_products
    DataCenterProduct.all.each do |dcp|
      if StagingProduct.exists?(article: dcp.article)
        exist_prd = StagingProduct.find_by_article(dcp.article)
      else
        StagingProduct.create!(dcp.attributes)
      end
    end

    paginating_staging_products
  end

private
  def paginating_staging_products
    conditions = []
    conditions << "article IN(#{session[:selected_products].map(&:inspect).join(', ').gsub /"/, "'"})" if params[:type].present? && params[:type] == 'selected_products'
    conditions << "article NOT IN(#{session[:selected_products].map(&:inspect).join(', ').gsub /"/, "'"})" if params[:type].present? && params[:type] == 'unselected_products'
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1].gsub("'", "''")}%')" if param[1].present?
    } if params[:search].present?

    @sync_products = DataCenterProduct.where(conditions.join(' AND ')).joins(:m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id LEFT JOIN brands ON products.brand_id=brands.id")
    .order(default_order('products')).paginate(page: params[:page], per_page: 50) || []
  end
end
