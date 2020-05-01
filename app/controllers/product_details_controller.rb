class ProductDetailsController < ApplicationController
  def index
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'" if param[1].present?
    } if params[:search].present?
    @product_d = ProductDetail.joins(:warehouse,:product)
      .select("*, products.description AS product_description, product_details.id AS pd_id")
      .where(conditions.join(' AND ')).order(default_order('products'))
      .paginate(page: params[:page], per_page: 100) || []
    @product_details = ProductDetail.joins(:warehouse,:product).select(
      "*, products.description AS product_description, product_details.id AS pd_id"
      ).where(conditions.join(' AND ')).order(default_order('products'))
      .paginate(page: params[:page], per_page: 100) || []
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls { headers["Content-Disposition"] = "attachment; filename=\"Product Stock.xls\""}
      if(params[:a] == "a")
        format.csv { send_data ProductDetail.all.to_csv2 }
      else
        format.csv { send_data ProductDetail.all.to_csv }
      end
    end
  end

  def get_product_details_modal
    conditions = []
    # conditions << "warehouse_id = #{current_user.office_id}" if current_user.office_id.present?
    @products = Product.where(conditions.join(' AND ')).order(default_order('products'))
      .paginate(page: params[:page], per_page: PER_PAGE) || []
  end

  def search_product_details
    conditions = []
    conditions << "warehouse_id = #{current_user.office_id}" if current_user.office_id.present?
    conditions << "products.article LIKE '%#{params[:article]}%'" if params[:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "barcode LIKE LOWER('%#{params[:barcode]}%')" if params[:barcode].present?
    @products = Product.where(conditions.join(' AND ')).order(default_order('products'))
      .paginate(page: params[:page], per_page: PER_PAGE) || []
    respond_to do |format|
      format.js
    end
  end

  def new
    @product_detail = ProductDetail.new
    respond_to do |format|
      format.html
    end
  end

  def import
    import_result = ProductDetail.import(params[:file])
    if params[:file].present?
      if import_result[:error] == 1
        flash[:error] = import_result[:message]
      else
        flash[:notice] = import_result[:message]
      end
    else
      flash[:error] = "Please attach CSV File"
    end
    redirect_to product_details_path
  end

  def show
    @product_detail = ProductDetail.find(params[:id])
    @product_mutation_histories = @product_detail.product_mutation_histories
    @product = @product_detail.product
    @office = current_user.office || Branch.first
  end

  def edit
    @product_detail = ProductDetail.find params[:id]
  end

  def update
    @product_detail = ProductDetail.find(params[:id])
    respond_to do |format|
      if @product_detail.update_attributes(params.require(:product_detail).permit(:min_stock, :rop_stock, :max_stock))
        flash.now[:notice] = 'Product detail successfully updated.'
        format.html{redirect_to product_details_url}
      else
        flash[:error] = @product_detail.errors.full_messages.join('<br/>')
        format.html {render :edit}
      end
    end
  end

  def destroy
    @product_detail = ProductDetail.find(params[:id])
    if @product_detail.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete product detail"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete product detail. Data in use"
    end
    format.html{redirect_to edit_product_details_url}
  end
end
