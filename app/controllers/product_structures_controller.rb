class ProductStructuresController < ApplicationController
  before_filter :can_view_product_convertion, only: [:index, :show, :product_convert]
  before_filter :can_manage_product_convertion, only: [:new, :create, :edit, :update, :convert_product, :convert]

  def edit
    @product_structure = ProductStructure.find(params[:id])
    @parent = @product_structure.parent.product
    @children = ProductStructure.where("parent_id=#{@product_structure.parent_id}")
  end

  def index
    get_paginated_product_structures
    respond_to do |format|
      format.xls
      if(params[:a] == "a")
        format.csv { send_data ProductStructure.to_csv2 }
      else
        format.csv { send_data ProductStructure.to_csv(@products, {}) }
      end
      format.html
      format.js
    end
  end

  def search_convertion
    conditions = []
    conditions << "LOWER(products.article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(products.barcode) LIKE LOWER('%#{params[:barcode]}%')" if params[:barcode].present?
    conditions << "LOWER(zfood_details.moved_qty) LIKE LOWER('%#{params[:quantity]}%')" if params[:quantity].present?
    conditions << "LOWER(offices.office_name) LIKE LOWER('%#{params[:warehouse]}%')" if params[:warehouse].present?
    conditions << "LOWER(code) LIKE LOWER('%#{params[:code]}%')" if params[:code].present?

    if current_user.branch_id.present?
      @zf = Zfood.where("product_details.product_id = #{params[:id]} AND warehouse_id = #{current_user.branch_id}").where(conditions.join(' AND '))
        .joins(product_detail: :warehouse, zfood_details: [sku: :product]).distinct()
    else
      @zf = Zfood.where("product_details.product_id = #{params[:id]}").where(conditions.join(' AND '))
        .joins(product_detail: :warehouse, zfood_details: [sku: :product]).distinct()
    end

    respond_to do |format|
      format.js
    end
  end

  def convertion
    if current_user.branch_id.present?
      @zf = Zfood.where("product_id = #{params[:id]} AND warehouse_id = #{current_user.branch_id}").joins(:product_detail)
    else
      @zf = Zfood.where("product_id = #{params[:id]}").joins(:product_detail)
    end
  end

  def show_convertion_details
    @zfd = ZfoodDetail.where(zfood_id: params[:id])
  end

  def product_convert
    get_paginated_product_structures
  end

  def update
    # byebug
    parent_id = Sku.find_by_product_id_and_convertion_unit(params[:product_structure]['parent_id'], 1).id
    ProductStructure.where(parent_id: parent_id).delete_all
    params[:product_structure].each{|product_structure|
      if product_structure[0] != 'parent_id'
        ps = product_structure[1]
        child = ProductStructure.where(sku_id: (Sku.find_by_product_id_and_convertion_unit(ps['sku_id'], 1).id rescue ''),
          parent_id: (Sku.find_by_product_id_and_convertion_unit(params[:product_structure]['parent_id'], 1).id)).first_or_create!
        child.update_attributes(quantity: ps['quantity'])
      end
    }
    flash[:notice] = t(:successfully_updated)
    redirect_to product_structures_url
  end

  def new
    @product_structure = ProductStructure.new
  end

  def convert_product
    @ps = Product.find(params[:id])
    if ProductStructure.find_by_parent_id(params[:id]).present?
      @product_structure_detail = ProductStructure.where(parent_id: params[:id])
    else
      @product_structure_detail = ProductStructure.joins(sku: :product).where(parent_id: Sku.find_by_product_id(params[:id]).id)
    end
  end

  def convert
    @ps = Sku.find_by_product_id(params[:id])
    input_qty = params[:qty].to_i
    if ProductStructure.convert(@ps, params[:branch_id], input_qty)
      redirect_to product_convert_product_structures_path
      flash[:notice] = "Product Structures now converted. QTY = #{input_qty}"
    end
  end

  def create
    params[:product_structure].each{|product_structure|
      if product_structure[0] != 'parent_id'
        ps = product_structure[1]
        ProductStructure.create sku_id: (Sku.find_by_product_id_and_convertion_unit(ps['sku_id'], 1).id rescue ''), product_id: ps['sku_id'],
          parent_id: (Sku.find_by_product_id_and_convertion_unit(params[:product_structure]['parent_id'], 1).id), quantity: ps['quantity'],
          code: ("PS#{sprintf '%07d', ((ProductStructure.where("code IS NOT NULL").order("code DESC").limit(1).last.code.gsub('PS', '').to_i rescue 0)+1)}")
      end
    }
    flash[:notice] = t(:successfully_created)
    redirect_to product_structures_url
  end

  def show
    @product_structure = ProductStructure.find(params[:id])
    @parent = @product_structure.parent.product
    @children = ProductStructure.where("parent_id=#{@product_structure.parent_id}")
  end

  def get_paginated_product_structures
    conditions = []
    #conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @products = Product.joins(:m_class).select("products.*, m_classes.name as m_class_name").where("products.id IN (SELECT product_id FROM skus WHERE id IN (SELECT parent_id FROM product_structures))").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 100) || []
    @products2 = Product.joins(:m_class).select("products.*, m_classes.name as m_class_name").where("products.id IN (SELECT product_id FROM skus WHERE id IN (SELECT parent_id FROM product_structures))").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')) || []
  end

 private

  def can_view_product_structure
    not_authorized unless current_user.can_view_product_structure?
  end

  def can_manage_product_structure
    not_authorized unless current_user.can_manage_product_structure?
  end

  def can_view_product_convertion
    not_authorized unless current_user.can_view_product_convertion?
  end

  def can_manage_product_convertion
    not_authorized unless current_user.can_manage_product_convertion?
  end
end
