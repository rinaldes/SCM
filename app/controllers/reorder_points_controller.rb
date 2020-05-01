class ReorderPointsController < ApplicationController
  def index
    get_paginated_reorder_points
  end

  private
    def get_paginated_reorder_points
      conditions = Array.new
      params[:search].each{|param|
        conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
      } if params[:search].present?
      @product_detail = ProductDetail.joins("LEFT JOIN products ON products.id = product_id
                                             LEFT JOIN offices ON offices.id = warehouse_id
                                             LEFT JOIN brands ON brands.id = products.brand_id")
                                             .where(conditions.join(' AND ')).paginate(:page => params[:page], :per_page => 10) || []
    end
end
