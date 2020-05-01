class SafetyStocksController < ApplicationController
  def index
    get_paginated_safety_stocks
  end

  private
    def get_paginated_safety_stocks
      conditions = Array.new
      params[:search].each{|param|
        conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
      } if params[:search].present?
      @products = Product.joins("LEFT JOIN brands ON brands.id = brand_id
                                 LEFT JOIN m_classes ON m_classes.id = m_class_id")
                         .where(conditions.join(' AND ')).paginate(:page => params[:page], :per_page => 10) || []
    end
end
