class ProductsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :product, :article
  before_filter :can_view_product, only: [:index, :show]
  before_filter :can_manage_product, only: [:new, :create, :update, :edit]

  def mutation_history
    @product = Product.find(params[:id])
    conditions = ["products.id=#{params[:id]}"]
    conditions << "warehouse_id=#{current_user.office_id}" if current_user.office_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?

    @histories = ProductMutationHistory.select("price, product_mutation_histories.created_at, office_name, mutation_type, old_quantity, moved_quantity, new_quantity, ref_code")
      .joins("INNER JOIN product_details ON product_details.id=product_mutation_histories.product_detail_id INNER JOIN products ON products.id=product_details.product_id INNER JOIN offices ON offices.id=product_details.warehouse_id")
      .order((params[:sort] || "product_mutation_histories.updated_at + INTERVAL '7 hour' ASC").to_s.gsub('-', ' '))
      .where(conditions.join(" AND ")).paginate(page: params[:page], per_page: 100) || []
  end

  def print_to_pdf
    @product = Product.find(params[:id])
    conditions = ["products.id=#{params[:id]}"]
    @histories = ProductMutationHistory.select("product_mutation_histories.created_at, office_name, mutation_type, old_quantity, moved_quantity, new_quantity")
      .joins("INNER JOIN product_details ON product_details.id=product_mutation_histories.product_detail_id INNER JOIN products ON products.id=product_details.product_id INNER JOIN offices ON offices.id=product_details.warehouse_id")
      .order((params[:sort] || "created_at ASC").to_s.gsub('-', ' '))
      .where(conditions.join(" AND ")) || []
    #tables = [['BARCODE', 'DESCRIPTION', 'QUANTITY']]
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "PM-#{@product.barcode}.pdf",
      :disposition => 'attachment'
    )
  end

  def mclass_per_department
    @cat_num = params[:cat_num].to_i rescue 4
    @cat = MClass.where("parent_id=#{params[:cat_id]}")
    if @cat.count() == 0
      @cat_num = 5
    end
  end

  def search_history
    conditions = []
    conditions << "products.id=#{params[:id]}"
    conditions << "warehouse_id=#{current_user.office_id}" if current_user.office_id.present?
    conditions << "LOWER(to_char(product_mutation_histories.created_at, 'YYYY-MM-DD')) LIKE LOWER('%#{params[:date]}%')" if params[:date].present?
    conditions << "LOWER(office_name) LIKE LOWER('%#{params[:office_name]}%')" if params[:office_name].present?
    conditions << "LOWER(mutation_type) LIKE LOWER('%#{params[:mutation_type]}%')" if params[:mutation_type].present?
    conditions << "LOWER(ref_code) LIKE LOWER('%#{params[:ref_code]}%')" if params[:ref_code].present?
    conditions << "LOWER(to_char(old_quantity, '999')) LIKE LOWER('%#{params[:old_quantity]}%')" if params[:old_quantity].present?
    conditions << "LOWER(to_char(moved_quantity, '999')) LIKE LOWER('%#{params[:moved_quantity]}%')" if params[:moved_quantity].present?
    conditions << "LOWER(to_char(new_quantity, '999')) LIKE LOWER('%#{params[:new_quantity]}%')" if params[:new_quantity].present?
    #@product = Product.find(params[:id])
    @histories = ProductMutationHistory.select("price, product_mutation_histories.created_at, office_name, mutation_type, old_quantity, moved_quantity, new_quantity, ref_code")
      .joins("INNER JOIN product_details ON product_details.id=product_mutation_histories.product_detail_id INNER JOIN products ON products.id=product_details.product_id INNER JOIN offices ON offices.id=product_details.warehouse_id").where(conditions.join(' AND ')).order("office_name, product_mutation_histories.created_at") || []
    @histories = @histories.paginate(page: params[:page])
    respond_to do |format|
      format.js
    end
  end

  def transaction_history
    @product = Product.find_by_barcode params[:barcode]
    @sales = SalesDetail.where("product_sizes.product_id IN (SELECT id FROM products WHERE barcode='#{params[:barcode]}')").joins(product_size: :product)
    respond_to do |format|
      format.js
    end
  end

  def import
    if params[:commit] == 'Upgrade Barcode'
      Product.upgrade_barcode(params[:file])
    else
  #    begin
        rows = []
        CSV.foreach(params[:file].path, headers: true, :encoding => 'ISO-8859-1') do |row|
          rows << row
        end
        import_result = Product.import(rows)
        if import_result[:error] == 1
          flash[:error] = import_result[:message]
        else
          flash[:notice] = import_result[:message]
        end
   #   rescue
    #    flash[:error] = "Import CSV failed. Please recheck the CSV file"
     # end
    end
    redirect_to products_path
  end

  def add_branch
  end

  def add_m_class
    @first_m_class = MClass.find_by_parent_id(MClass.find_by_name(params[:parent_id]).id) rescue nil
    @m_classes = MClass.where("parent_id=#{MClass.find_by_name(params[:parent_id]).id}") rescue nil
  end

  def show
    @product = Product.find params[:id]
    load_master_data_for_goods
    @m_class = MClass.find_by_id(@product.m_class_id)
    @colour_code = ''
    #@size = @product.size rescue ''
    #@size_details = @size.size_details
    @product_supplier = ProductSupplier.find_by_product_id(@product.id)
    @branch_prices = BranchPrice.where("product_id=#{@product.id}")
    @total = 0
    # @product_details = ProductDetail.joins(:product).where("product_id=#{@product.id} AND warehouse_id IN (#{current_user.current_offices.map(&:id).join(', ')})").group_by(&:product_id)
    @can_manage_product = current_user.can_manage_product?
  end

  # GET /goods
  def index
    get_paginated_products
    filename = "Product.xlsx"
    respond_to do |format|
      format.html # index.html.erb
      format.js
      format.xls
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
      if(params[:a] == "a")
        format.csv { send_data Product.all.to_csv2 }
      elsif(params[:a] == "stock")
        format.csv { send_data Product.all.to_csv3 }
      else
        format.csv { send_data @products.to_csv(@products, {}) }
      end
    end
  end

  def m_history
    get_paginated_products
    # respond_to do |format|
    #   format.html
    # end
    respond_to do |format|
      format.html
      format.js
    end
  end

  # GET /goods/add
  def add
    @goods = Product.new
    load_master_data_for_goods
    @units = Unit.all
    @branches = Branch.all
    @brands = Brand.select(:name)
    respond_to do |format|
      format.html
    end
  end

  def detail_good
    @goods = Product.find(params[:id])
    @user_branches =  Office.all.map{|x| [x.name, x.id]}
    @user_branches << ["Global", "Global"]
    @sizes = Size.all
    @size_details = SizeDetail.all
    @colours = Colour.all
    @stores = Store.all
    @units = Unit.all
    @branches = Branch.all
  end

  # GET /goods/new
  def new
    session[:ref] = params[:ref]
    @product = Product.new status4: 'Slow Moving', article: (Product.last.article.to_i+1 rescue '160000'), status1: 'Active', status2: 'Non-Konsinyasi'
    load_master_data_for_goods
    respond_to do |format|
      format.html
      format.js
    end
  end

  def get_products_modal
    search_products
  end

  def choose_product
    @product = Product.find(params[:product_id])
    @product_supplier = @product.product_suppliers.first.supplier
  end

  def search_products
    conditions = []
    conditions << "LOWER(article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    conditions << "LOWER(description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(barcode) LIKE LOWER('%#{params[:barcode]}%')" if params[:barcode].present?
    @products = Product.where(conditions.join(' AND ')).paginate(page: params[:page], per_page: 10) || []
    respond_to do |format|
      format.js
    end
  end

  def get_sales_data
    conditions = ["quantity > 0 AND goods.barcode='#{params[:barcode]}'"]
    conditions << "sales_details.created_at >= '#{params[:start_date].to_date.strftime('%Y-%m-%d')}'" if params[:start_date].present?
    conditions << "sales_details.created_at <= '#{params[:end_date].to_date.strftime('%Y-%m-%d')}'" if params[:end_date].present?
    @sales_details = SalesDetail.joins(goods_size: [:size_detail, goods: [brand: [:supplier]]], sale: [:user, store: [:branch]])
    .where(conditions.join(' AND ')).select('sales_details.created_at, bill_number, first_name, last_name, size_number, quantity, price,
        discount, price_after_discount, goods.barcode AS barcode')
    @sales_details = @sales_details.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def scan_barcode
    if params[:barcode].present?
      goods = Product.find_by_barcode(params[:barcode])
    else
      conditions = []
      conditions << "brands.name='#{params[:brand]}'" if params[:brand].present?
      conditions << "colours.name='#{params[:colour]}'" if params[:colour].present?
      conditions << "article='#{params[:article]}'" if params[:article].present?
      goods = Product.joins(:brand, :colour).last(conditions: [conditions.join(' AND ')])
    end
    brand = goods.brand

    goods_discount = goods.discounts.actives.last
    # if goods_discount.present? && goods_discount.discount_type != Discount::TidakAdaDiskon#next time TidakAdaDiskon should be deleted
    disc = goods_discount
    # else
    # disc = brand.discounts.actives.last
    brand_discount_percent = goods.brand.discounts.last.percent rescue '' #disc.id rescue ''
    # end

    render json: {
      id: (goods.id rescue 0), type: (goods.type.name), brand: (brand.name rescue ''), article: goods.article, barcode: goods.barcode,
      brand_percent: brand_discount_percent, colour: (goods.colour.name rescue ''), size: (goods.size.description rescue ''),
      status: goods.status, path_image: (goods.image.url rescue ''), unit_id: goods.unit_id, percentage_price: goods.percentage_price,
      supplier: (brand.supplier.name rescue ''), disc_type: (disc.discount_type rescue 'tidak ada diskon'),
      cost_of_goods: goods.cost_of_goods, purchase_price: goods.cost_of_goods, selling_price: goods.selling_price,
      discount_percent: (disc.percent rescue ""),
      start_date: ((disc.start_date.strftime("%d-%m-%Y") if disc.discount_type!=Discount::TidakAdaDiskon) rescue ''), end_date: (disc.end_date.strftime("%d-%m-%Y") rescue ''),
      netto: ((goods.netto - (disc.percent/100 * goods.netto)) rescue ''), last_update_cost: goods.updated_at.strftime("%d-%m-%Y"),
      last_update_sell: goods.updated_at.strftime("%d-%m-%Y"), brand_discount: (brand_discount.last.percent rescue "")
    }
  end

  def get_pmb_goods_detail
    if params[:barcode].present?
      goods = Product.find_by_barcode(params[:barcode])
      result = {error:1}
      return render json: result if goods.nil?

    else
      result = {error:1}
      return render json: result
      #      conditions = []
      #      conditions << "brands.name='#{params[:brand]}'" if params[:brand].present?
      #      conditions << "colours.name='#{params[:colour]}'" if params[:colour].present?
      #      conditions << "article='#{params[:article]}'" if params[:article].present?
      #      goods = Product.joins(:brand, :colour).last(conditions: [conditions.join(' AND ')])
    end
    result = goods.get_pmb_goods_detail

    render json: result
  end

  def get_goods_detail
    if params[:colour].present?
      goods = Product.where(:article => params[:article], :colour_id => params[:colour], :status => params[:status])
      result = {error:1}
      return render json: result if goods.first.nil?

    else
      result = {error:1}
      return render json: result
      #      conditions = []
      #      conditions << "brands.name='#{params[:brand]}'" if params[:brand].present?
      #      conditions << "colours.name='#{params[:colour]}'" if params[:colour].present?
      #      conditions << "article='#{params[:article]}'" if params[:article].present?
      #      goods = Product.joins(:brand, :colour).last(conditions: [conditions.join(' AND ')])
    end
    result = goods.first.get_pmb_goods_detail

    render json: result
  end

  def  get_goods_detail_by_colour
    if params[:colour].present?
      goods = Product.where(:article => params[:article], :colour_id => params[:colour])
      result = {error:1}
      return render json: result if goods.first.nil?

    else
      result = {error:1}
      return render json: result
      #      conditions = []
      #      conditions << "brands.name='#{params[:brand]}'" if params[:brand].present?
      #      conditions << "colours.name='#{params[:colour]}'" if params[:colour].present?
      #      conditions << "article='#{params[:article]}'" if params[:article].present?
      #      goods = Product.joins(:brand, :colour).last(conditions: [conditions.join(' AND ')])
    end
    result = goods.first.get_pmb_goods_detail

    render json: result
  end

  def get_pmb_data
    goods = Product.find(params[:id])
    data = {}
    goods_sizes = goods.goods_sizes
    if goods_sizes.present?
      goods_sizes.each do |goods_size|
        goods_receipt_details = goods_size.goods_receipt_details
        if !goods_receipt_details.blank?
          goods_receipt_details.each_with_index do |goods_receipt_detail, i|
            date = goods_receipt_detail.goods_receipt.received_date
            date_split = date.split("-")
            date = "#{date_split[1]}-#{date_split[2]}-#{date_split[0]}"
            if(data[goods_receipt_detail.goods_receipt.code].blank?)
              data[goods_receipt_detail.goods_receipt.code] = {}
            end
            if(data[goods_receipt_detail.goods_receipt.code]["data"].blank?)
              data[goods_receipt_detail.goods_receipt.code]["data"] = {}
            end
            data[goods_receipt_detail.goods_receipt.code]["data"]["#{goods_size.size_detail.size_number}"] = {"qty" => goods_receipt_detail.qty, "pbd" => goods_receipt_detail.price_before_discount, "td" => goods_receipt_detail.total_discount, "pad" => goods_receipt_detail.price_after_discount}
            data[goods_receipt_detail.goods_receipt.code]["name"] = goods_receipt_detail.goods_receipt.code
            data[goods_receipt_detail.goods_receipt.code]["received_date"] = date
            data[goods_receipt_detail.goods_receipt.code]["key"] = data[goods_receipt_detail.goods_receipt.code]["data"].keys
          end
        end
      end
    end
    data = data.sort_by{|x| x[0]}.reverse!
    key = data.map{|x| x[0]}

    respond_to do |format|
      format.json {
        render json: {
          data: data,
          key: key
        }
      }
    end
  end

  def filter_goods
    @exported_goods = Product.goods_filter params
    @_goods = @exported_goods.paginate(:page => params[:page], :per_page => 10) || []

    respond_to do |format|
      format.js
    end
  end

  def history_pmb
    goods = Product.find(params[:search_id])
    data = {}
    goods_sizes = goods.goods_sizes
    if goods_sizes.present?
      goods_sizes.each do |goods_size|
        goods_receipt_details = goods_size.goods_receipt_details
        if !goods_receipt_details.blank?
          goods_receipt_details.each_with_index do |goods_receipt_detail, i|
            date = goods_receipt_detail.goods_receipt.received_date
            date_split = date.split("-")
            date = "#{date_split[1]}-#{date_split[2]}-#{date_split[0]}"
            if(DateTime.parse(date) >= DateTime.parse(params[:product_receipt_start_date]) &&  DateTime.parse(date) <= DateTime.parse(params[:product_receipt_end_date]))
              if(data[goods_receipt_detail.goods_receipt.code].blank?)
                data[goods_receipt_detail.goods_receipt.code] = {}
              end
              if(data[goods_receipt_detail.goods_receipt.code]["data"].blank?)
                data[goods_receipt_detail.goods_receipt.code]["data"] = {}
              end
              data[goods_receipt_detail.goods_receipt.code]["data"]["#{goods_size.size_detail.size_number}"] = {"qty" => goods_receipt_detail.qty, "pbd" => goods_receipt_detail.price_before_discount, "td" => goods_receipt_detail.total_discount, "pad" => goods_receipt_detail.price_after_discount}
              data[goods_receipt_detail.goods_receipt.code]["name"] = goods_receipt_detail.goods_receipt.code
              data[goods_receipt_detail.goods_receipt.code]["received_date"] = date
              data[goods_receipt_detail.goods_receipt.code]["key"] = data[goods_receipt_detail.goods_receipt.code]["data"].keys
            end
          end
        end
      end
    end
    data = data.sort_by{|x| x[0]}.reverse!
    key = data.map{|x| x[0]}

    respond_to do |format|
      format.json {
        render json: {
          data: data,
          key: key
        }
      }
    end
  end

  def insert_price_log(params, old_price, new_price, code)
    price_log = PriceLog.new(:product_id => params, :old_price => old_price, :new_price => new_price, :code => code)
    price_log.save
  end

  def destroy
    @product = Product.find(params[:id])
    if @product.check_transaction && @product.destroy
      flash[:error] = nil
      flash[:notice] = "Successfully delete product"
    else
      flash[:notice] = nil
      flash[:error] = "Can't delete product. data in use"
    end
    get_paginated_products
    respond_to do |format|
      format.js
    end
  end

  # GET /goods/1/edit
  def edit
    @product = Product.find params[:id]
    @units = Unit.all
    @m_class = MClass.find_by_id(@product.m_class_id)
    @brand = @product.brand
    @brands = Brand.all
    @branch_prices = BranchPrice.where("product_id=#{@product.id}")
    @total = 0
    @m_classes = MClass.where("parent_id IS NOT NULL AND level=1")
    @product_details = ProductDetail.joins(:product).where("product_id=#{@product.id} AND warehouse_id IN (#{current_user.current_offices.map(&:id).join(', ')})").group_by(&:product_id)
    @can_manage_product = current_user.can_manage_product?
    @product_supplier = ProductSupplier.find_by_product_id(@product.id)

    # Product Categories
    dpt_mclass = @product.m_class.department_m_class.split(' > ')
    @cat1_name = dpt_mclass.last(2).first # Level 1 Name
    @cat2_name = dpt_mclass.last(3).first # Level 2 Name
    @cat3_name = dpt_mclass.last(4).first if dpt_mclass.count >= 4 # Level 3 Name
    @cat4_name = dpt_mclass.first if dpt_mclass.count >= 5 # Level 4 Name
    @cat1 = MClass.where(parent_id: @product.department_id) # Category Level 1
    @cat2 = MClass.where(parent_id: MClass.where(name: @cat1_name).first.id) # Category Level 2
    @cat3 = MClass.where(parent_id: MClass.where(name: @cat2_name).first.id) # Category Level 3
    @cat4 = MClass.where(parent_id: (MClass.where(name: @cat3_name).first.id rescue 1)) # Category Level 4
  end

  def set_department_m_class m_class
    department_m_class = []
    current_m_class = m_class
    while current_m_class.present? do
      department_m_class << current_m_class.name
      current_m_class = current_m_class.m_class
    end
    return department_m_class.join(' > ')
  end

  # POST /goods
  def create
    @product = Product.new(params.require(:product).permit(:article, :sku, :unit_id, :barcode, :selling_price, :box_id, :box_num,
      :box_barcode, :box2_id, :box2_num, :box2_barcode, :status1, :status2, :status3,
      :status5, :cost_of_products, :selling_price, :description, :description_2, :flag_pajak, :status_retur, :flag_barang, :fraction, :minimal_order, :short_name, :department_id, :m_class_id, :brand_id
    ).merge(supplier_id: params[:supplier]))

    respond_to do |format|
      if @product.save
        Sku.create!(product_id: @product.id, unit_id: @product.unit_id, barcode: @product.barcode, convertion_unit: 1)
        Sku.create!(product_id: @product.id, unit_id: @product.box_id, barcode: (@product.box_barcode rescue ''), convertion_unit: (@product.box_num rescue 0)) if @product.box_id != nil
        Sku.create!(product_id: @product.id, unit_id: @product.box2_id, barcode: (@product.box2_barcode rescue ''), convertion_unit: (@product.box2_num rescue 0)) if @product.box2_id != nil
        #supplier = Supplier.find_by_code(params[:supplier].split(' - ')[0])
        supplier = Supplier.find_by_id(params[:supplier])
        ProductSupplier.create product_id: @product.id, contact_person_id: (supplier.contact_people.first.id rescue supplier.id), supplier_id: supplier.id
        flash.now[:notice] = 'Product successfully created.'
        format.html{redirect_to products_url}
      else
        load_master_data_for_goods
        flash.now[:error] = @product.errors.full_messages.join('<br/>')
        format.html{render 'new'}
      end
    end
  end

  # POST /goods
  def update
    brand = Brand.find_by_name(params[:brand])
    m_class = MClass.find_by_name(params[:m_class])
    @product = Product.find(params[:id])
    respond_to do |format|
      if @product.update_attributes(
        params.require(:product).permit(
          :article, :image, :status1, :status2, :status3, :flag_pajak, :first_po, :margin_percent1, :margin_percent2, :margin_percent3, :margin_percent4, :margin_rp, :discount_percent, :margin_percent, :status5, :box_barcode,
          :box2_barcode, :box_num, :box2_num, :description, :description_2, :short_name, :barcode, :m_class_id, :department_id, :unit_id, :box_id, :box2_id, :status_retur
        ).merge(brand_id: (brand.id rescue nil), department_m_class: set_department_m_class(m_class), purchase_price: params[:floated_purchase_price], cost_of_products: params[:floated_cost_of_products],
          selling_price: params[:floated_selling_price], harga_bandrol: params[:floated_harga_bandrol], harga_eceran: params[:floated_harga_eceran],
          harga_member_eceran: params[:floated_harga_member_eceran], harga_kredit: params[:floated_harga_kredit], margin_rp: params[:floated_margin_rp], supplier_id: params[:supplier]
        )
      )
        begin
          supplier = Supplier.find_by_id(params[:supplier])
          prod_sup = ProductSupplier.find_by_product_id(@product.id)
          prod_sup.update_attributes(contact_person_id: (supplier.contact_people.first.id rescue supplier.id), supplier_id: supplier.id)
        rescue
        end

        # Update SKU untuk yang convertion unitnya 1
        begin
          @product.skus.where(convertion_unit: 1).last.update_attributes(unit_id: @product.unit_id, barcode: @product.barcode)
        rescue
          # Apabila SKU yang convertion unitnya 1 tidak ada, maka akan dibuatkan
          @product.skus.create(convertion_unit: 1, unit_id: @product.unit_id, barcode: @product.barcode)
        end

        # LOGIC : Jika box 1 sudah ada, maka update, jika tidak maka create
        # jika parameter product box_id tidak sama dengan null maka..
        if params[:product][:box_id] != ""
          # Jika sku dengan CU lebih dari 1 ada maka..
          if @product.skus.where("convertion_unit > 1").present?
          # cari SKU yang CU lebih dari 1 dan pilih yang pertama, lalu update
          @product.skus.where("convertion_unit > 1").first.try(
            :update_attributes, {
              unit_id: @product.box_id, barcode: @product.box_barcode,
              convertion_unit: (@product.box_num rescue 1)
            }
          )
          else
          # Jika sku dengan CU lebih dari 1 tidak ada maka akan dibuatkan sku yang baru
            @product.skus.create!(unit_id: @product.box_id, barcode: @product.box_barcode, convertion_unit: (@product.box_num))
          end
        else
          if @product.skus.where("convertion_unit > 1").present?
            @product.skus.where("convertion_unit > 1").first.destroy!
          end
        end

        # LOGIC : Jika box 2 sudah ada, maka update, jika tidak maka create
        # jika parameter product box2_id tidak sama dengan null maka..
        if params[:product][:box2_id] != ""
          # Jika sku dengan CU lebih dari 1 ada maka..
          if @product.skus.where("convertion_unit > 1").present?
            # Jika sku dengan CU yang lebih dari 1 hasilnya lebih dari 2 maka
            if @product.skus.where("convertion_unit > 1").count > 1
              # cari SKU yang CU lebih dari 1 dan pilih yang terakhir, lalu update
              @product.skus.where("convertion_unit > 1").last.try(
                :update_attributes, {
                  unit_id: @product.box2_id, barcode: @product.box2_barcode,
                  convertion_unit: (@product.box2_num rescue 1)
                }
              )
            else
              # Jika sku dengan CU lebih dari 1 tidak ada maka akan dibuatkan sku yang baru
              @product.skus.create!(unit_id: @product.box2_id, barcode: @product.box2_barcode, convertion_unit: (@product.box2_num rescue 0))
            end
          end
        else
          if @product.skus.where("convertion_unit > 1").present?
            if @product.skus.where("convertion_unit > 1").count > 1
              @product.skus.where("convertion_unit > 1").last.destroy!
            end
          end
        end

        format.html { redirect_to products_path, notice: 'Product successfully updated.' }
      else
        @suppliers = Supplier.all
        @brands = Brand.all
        @units = Unit.all
        flash[:error] = @product.errors.full_messages.join('<br/>')
        format.html {render :edit}
      end
    end
  end

  def copy_by_colour
    @good = Product.where(:article => params[:article], :brand_id => params[:brand_id])
    if @good.present?
      arr_state = Product::STATUS
      arr_state.each do |state|
        puts brand = Brand.find(params[:brand_id])
        puts colour = Colour.find(params[:colour_id])
        puts type_code = Type.find(params[:type_id])
        puts ar = article_code_copy.to_s.rjust(4, '0')

        @copy_good = @good.first.dup
        @copy_good.colour_id = params[:colour_id]
        @copy_good.status = state
        puts "-==============="
        puts @copy_good.barcode = [init_status(state), (type_code.code rescue ''), (brand.code rescue ''), ar , (colour.code rescue '')].compact.join('')

        @copy_good.save
      end
      @pres = true
    else
      @pres = false
    end
    render json: @good

  end

  def branch_stock
    respond_to do |format|
      format.html
    end
  end

  def setting_prices

  end

  def all_branches_stock
    goods = Product.find_by_barcode(params[:search])
    if goods.present?
      goods_sizes = goods.goods_sizes
      if goods_sizes.present?
        size_number = goods.size.size_details.map(&:size_number)
        @data = {"barang" => [goods.brand.name, goods.article, goods.colour.name, goods.selling_price, params[:search], goods.type.name], "data" => {},
          "jumlah" => {}, "size" => size_number}

        Office.all.each do |office|
          store = office.stores.map(&:id)
          @data["data"]["#{office.name}"] =  {"data_branch" => office.name, "stock" => {}, "each_cabang" => {}}
          goods_sizes.each do |goods_size|
            goods_details = goods_size.goods_details
            goods_store = goods_details.where(store_id: store)
            size_number = goods_size.size_detail.size_number
            @data["data"][office.name]["stock"]["#{size_number}"] = goods_store.sum(:quantity)
            @data["data"][office.name]["each_cabang"]["#{size_number}"] = goods_store.map{|x|"#{x.store.name}: #{x.quantity}"}.join('<br/>')
            @data["jumlah"]["#{size_number}"] = goods_details.sum(:quantity)
          end
        end
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def detail_branches
    @goods = Product.where("article LIKE '%#{params[:keyword]}%' AND brand_id = #{params[:brand_id]}")
  end

  def search
    @goods = Product.search(params[:search]).first || []
    @sizes = (@goods.goods_details.group_by(&:size_detail_id).map{|goods_details|goods_details[1].first}.map{|goods_detail|
        [goods_detail.size_detail.size_number, goods_detail.quantity]
      }.sort if @goods.present?) || []

    respond_to do |format|
      format.js
    end
  end

  def search_purchase_price_after_discount
    brand = Brand.find_by_name(params[:brand])
    purchase_price = params[:cost_of_goods]
    discount_rp = brand.discount_rp rescue 0
    discount_percent1 = brand.discount_percent1 rescue 0
    discount_percent2 = brand.discount_percent2 rescue 0
    discount_percent3 = brand.discount_percent3 rescue 0
    price_after_discount_1 = purchase_price.to_f - discount_rp.to_f
    price_after_discount_2 = price_after_discount_1.to_f*(100-discount_percent1.to_f)/100
    price_after_discount_3 = price_after_discount_2.to_f*(100-discount_percent2.to_f)/100
    end_of_price_after_discount = price_after_discount_3.to_f*(100-discount_percent3.to_f)/100

    purchase_price_after_discount = end_of_price_after_discount

    if purchase_price_after_discount <= 0
      purchase_price_after_discount = 0
    end

    respond_to do |format|
      format.json {render json: {purchase_price_after_discount: purchase_price_after_discount, d1: discount_percent1, d2: discount_percent2, d3: discount_percent3, discount_rp: discount_rp}}
    end
  end

  def get_purchase_price_after_discount_by_brand_id
    brand = Brand.find_by_id(params[:brand_id])
    purchase_price = params[:cost_of_goods]
    discount_rp = brand.discount_rp rescue 0
    discount_percent1 = brand.discount_percent1 rescue 0
    discount_percent2 = brand.discount_percent2 rescue 0
    discount_percent3 = brand.discount_percent3 rescue 0
    price_after_discount_1 = purchase_price.to_f - discount_rp.to_f
    price_after_discount_2 = price_after_discount_1.to_f*(100-discount_percent1.to_f)/100
    price_after_discount_3 = price_after_discount_2.to_f*(100-discount_percent2.to_f)/100
    end_of_price_after_discount = price_after_discount_3.to_f*(100-discount_percent3.to_f)/100

    purchase_price_after_discount = end_of_price_after_discount

    if purchase_price_after_discount <= 0
      purchase_price_after_discount = 0
    end

    render json: {purchase_price_after_discount: purchase_price_after_discount, d1: discount_percent1, d2: discount_percent2, d3: discount_percent3, discount_rp: discount_rp}
  end

  def autocomplete_goods_barcode
    hash = []
    conditions = []
    conditions << "barcode LIKE '%#{params[:term]}%'" if params[:term].present?
    conditions << "article LIKE '%#{params[:article]}%'" if params[:article].present?
    conditions << "LOWER(description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions.push("suppliers.code='#{params[:supplier_code]}'") if params[:supplier_code].present?
    goods = Product.joins(:suppliers).where(conditions.join(' AND ')).limit(25)
    goods.collect do |g|
      main_search = params[:article].present? ? g.article : (params[:description].present? ? g.description : g.barcode)
      hash << {
        "id" => g.id, "name" => main_search, "value" => main_search, department_id: g.department.id, department_name: g.department.name, m_class_id: g.m_class_id, m_class_name: g.m_class ? g.m_class.name : '',
        brand_id: g.brand_id, article: g.article, barcode: g.barcode
      }
    end

    respond_to do |format|
      format.json {render json: hash}
    end
  end

  def search_by_data
    goods = Product.cari_data(params)
    if goods.present?
      goods_sizes = goods.goods_sizes
      if goods_sizes.present?
        size_number = goods.size.size_details.map(&:size_number)
        @data = {"barang" => [goods.brand.name, goods.article, goods.colour.name, goods.selling_price, goods.barcode, goods.type.name], "data" => {},
          "jumlah" => {}, "size" => size_number}

        Office.all.each do |office|
          store = office.stores.map(&:id)
          @data["data"]["#{office.name}"] =  {"data_branch" => office.name, "stock" => {}, "each_cabang" => {}}
          goods_sizes.each do |goods_size|
            goods_details = goods_size.goods_details
            goods_store = goods_details.where(store_id: store)
            size_number = goods_size.size_detail.size_number
            @data["data"][office.name]["stock"]["#{size_number}"] = goods_store.sum(:quantity)
            @data["data"][office.name]["each_cabang"]["#{size_number}"] = goods_store.map{|x|"#{x.store.name}: #{x.quantity}"}.join('<br/>')
            @data["jumlah"]["#{size_number}"] = goods_details.sum(:quantity)
          end
        end
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def print_barcode
    render layout: false
  end

  def search_article
    goods = Product.find_by_article(params[:article]) rescue nil
    respond_to do |format|
      format.json {render json: goods}
    end
  end

  def search_filter_by_name
    @types = Type.where(:parent_id => params[:id])
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_sub_type
    @goods = Product.where(:type_id => params[:id], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_brands
    @goods = Product.where(:brand_id => params[:id], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_brands_po
    @goods = Product.where(:brand_id => params[:id], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_article_po
    @goods = Product.where(:article => params[:id], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_merk_distribusi
    @receipt_id = params[:receipt_id]
    @goods = Product.joins(:product_receipt_details).where("brand_id = '#{params[:id]}' AND  goods_receipt_details.goods_receipt_id  = '#{params[:receipt_id]}'").group("barcode").paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_article_distribusi
    @receipt_id = params[:receipt_id]
    @goods = Product.joins(:product_receipt_details).where("article = '#{params[:id]}' AND  goods_receipt_details.goods_receipt_id  = '#{params[:receipt_id]}'").group("barcode").paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      format.js
    end
  end

  def search_filter_by_article
    @article = params[:id]
    @brand_id = params[:brand_id]
    if @brand_id.present?
      @goods = Product.where(:article => @article, :brand_id => @brand_id, :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
      @goods_colour = Product.where(:article => params[:id], :brand_id => @brand_id, :status => "Putus").group(:colour_id)
      @goods_another_colour = Colour.all
      @type_id = @goods.first.type_id
    else
      @goods_colour = Product.where(:article => params[:id], :status => "Putus").group(:colour_id)
      @goods = Product.where(:article => @article, :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
      @goods_another_colour = Colour.all
      @type_id = @goods.first.type_id
    end
    @goods_colours = Colour.all

    respond_to do |format|
      format.js
    end
  end

  def detail_good_by_brand
    if params[:id].present?
      goods = Product.find(params[:id])
      @results = {error:1}
      return render json: result if goods.nil?

    else
      @results = {error:1}
      return render json: result
      #      conditions = []
      #      conditions << "brands.name='#{params[:brand]}'" if params[:brand].present?
      #      conditions << "colours.name='#{params[:colour]}'" if params[:colour].present?
      #      conditions << "article='#{params[:article]}'" if params[:article].present?
      #      goods = Product.joins(:brand, :colour).last(conditions: [conditions.join(' AND ')])
    end
    @results = goods.get_pmb_goods_detail
    # @results = @result.to_h

    render json: @results
  end

  def detail_good_by_article
    if params[:id].present?
      goods = Product.find(params[:id])
      @result = {error:1}
      return render json: result if goods.nil?

    else
      @result = {error:1}
      return render json: result
      #      conditions = []
      #      conditions << "brands.name='#{params[:brand]}'" if params[:brand].present?
      #      conditions << "colours.name='#{params[:colour]}'" if params[:colour].present?
      #      conditions << "article='#{params[:article]}'" if params[:article].present?
      #      goods = Product.joins(:brand, :colour).last(conditions: [conditions.join(' AND ')])
    end
    @result = goods.get_pmb_goods_detail

    render json: @results
  end

  def detail_colour_article
    @goods = Product.joins(:colour).where(:article => params[:article], :status => "Putus").group("colour_id").select("colour_id, colours.name, status, barcode")
    render json: @goods.to_json
  end

  def search_filter_by_colour
    if params[:id].blank?
      @goods = Product.where(:status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
    elsif params[:article].present? && params[:id].blank?
      @goods = Product.where(:article => params[:article], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
      @barcode = @goods.first.barcode unless @goods.first.nil?
    elsif params[:article].present? && params[:id].present?
      @goods = Product.where(:article => params[:article], :colour_id => params[:id], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
      @barcode = @goods.first.barcode unless @goods.first.nil?
      find_size_goods(@barcode)
    else
      @goods = Product.where(:colour_id => params[:id], :status => "Putus").paginate(:page => params[:page], :per_page => 10) || []
    end
    respond_to do |format|
      format.js
    end
  end

  def get_receipt_data
    @pmb = ProductReceipt.find(params[:receipt_id])
    @goods = Product.find_by_barcode(params[:barcode])
    # @goods = @pmb.goods_receipt_details.find_by_goods_id(@good.id)
    # ap @goods
    @detail = @goods.get_pmb_goods_in_distribution

    @goods_details = @pmb.get_pmb_goods_receipt_detail
    @pmb_id = params[:receipt_id]
    respond_to do |format|
      format.js
    end
  end

  def stock
   # return not_authorized unless current_user.can_view_stock_all_branches?
#    current_user = User.find_by_id(params[:user_id]) if current_user.blank?
    conditions = []
    @current_offices = current_user.offices
    if params[:comparison].present? && params[:quantity].present?
      conditions << "products.id IN (SELECT product_id FROM product_details WHERE available_qty #{params[:comparison]} #{params[:quantity]} AND warehouse_id IN (#{params[:search][:branch].keys.join(',')}))"
    end
    if params[:search].present?
      params[:search].each{|param|
        if param[0] == "status3" or param[0] == "status4"
          params[:search][param[0]].each{|status|
            conditions << "#{param[0]} = '#{status[1]}'"
          }
        else
          params[:search].each{|param|
            if param[0] == 'article'
              conditions << "article IN ('#{"#{param[1]}".split(',').map{|art|art.gsub(/\s+/, "")}.join("','")}')" if param[1].present?
            else
              conditions << "#{param[0]} = '#{param[1]}'" if param[1].present? && param[0] != 'branch'
            end
          }
        end
      }
      if @brand.present?
        @supplier = @brand.supplier
        conditions << "brand_id=#{@brand.id}"
      end
      if params[:supplier_id].present?
        conditions << "product_suppliers.supplier_id = #{params[:supplier_id]}"
      end
      @products = Product.joins("LEFT JOIN brands ON brands.id=products.brand_id").joins(:product_suppliers).where(conditions.join(' AND ')).uniq

      if params[:stock].nil?
        flash.now[:error] = 'Toko harus dipilih dulu!'
      else
        @offices = Office.active_store.where(id: (params[:stock][:office_id]))
      end
    else
      if current_user.branch_id.present?
        @offices = current_user.offices
      else
        @offices = Office.active_store
      end
    end

    respond_to do |format|
      format.html
      format.js
      format.xls { send_data stock_export, :filename => "CHECK_STOCK" + ".xls", :type =>  "application/vnd.ms-excel" }
    end
  end

  def stock_export
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(:name => 'Stock')

    conditions = []
    @current_offices = current_user.offices
    if params[:comparison].present? && params[:quantity].present?
      conditions << "products.id IN (SELECT product_id FROM product_details WHERE available_qty #{params[:comparison]} #{params[:quantity]} AND warehouse_id IN (#{params[:search][:branch].keys.join(',')}))"
    end
    if params[:search].present?
      # @brand = Brand.find_by_name params[:search]["brands.name"]
      params[:search].each{|param|
        if param[0] == "status3" or param[0] == "status4"
          params[:search][param[0]].each{|status|
            conditions << "#{param[0]} = '#{status[1]}'"
          }
        else
          params[:search].each{|param|
            if param[0] == 'article'
              conditions << "article IN ('#{"#{param[1]}".split(',').map{|art|art.gsub(/\s+/, "")}.join("','")}')" if param[1].present?
            else
              conditions << "#{param[0]} = '#{param[1]}'" if param[1].present? && param[0] != 'branch'
            end
          }
        end
      }
      if @brand.present?
        @supplier = @brand.supplier
        conditions << "brand_id=#{@brand.id}"
      end
      if params[:supplier_id].present?
        conditions << "product_suppliers.supplier_id = #{params[:supplier_id]}"
      end
      products = Product.joins("LEFT JOIN brands ON brands.id=products.brand_id").joins(:product_suppliers).where(conditions.join(' AND '))
      @offices = Office.where(id: (params[:search][:branch].keys rescue 0))
    else
      @offices = current_user.offices
    end

    title = ['Department', 'Category', 'SKU', 'Barcode', 'Name']
    sheet.row(0).push *title
    @offices.each_with_index do |office, i|
      sheet.row(0).push office.office_name
      sheet.row(1).insert i+5, 'Qty'
      # sheet.merge_cells(1, i+5, 1, end_col)
    end

    products.each_with_index do |product, i|
      data = []

      data << product.m_class.department.name rescue ''
      data << product.m_class.name rescue ''
      data << product.article
      data << product.barcode
      data << product.description
      @offices.each_with_index do |office, i|
        data << (product.product_details.find_by_warehouse_id(office.id).available_qty rescue '')
      end

      sheet.row(i+1 + 1).push *data
    end


    out = StringIO.new
    book.write out
    out.rewind

    return out.string
  end

  private
  def get_paginated_products
    # departments = Department.where("id IN (SELECT department_id FROM office_departments WHERE office_id IN (#{current_user.offices.map(&:id).push(0).join(' , ')}))") rescue [0]
    conditions = []
    # conditions << "products.id IN (SELECT product_id FROM selling_prices WHERE office_id=#{current_user.branch_id} AND end_date>NOW())" if current_user.branch_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1].gsub("'", "''")}%')" if param[1].present?
    } if params[:search].present?
    unless request.format.xls? || request.format.xlsx? || request.format.csv?
      @products = Product.where(conditions.join(' AND ')).joins(:m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id LEFT JOIN brands ON products.brand_id=brands.id")
        .order(default_order('products')).paginate(page: params[:page], per_page: 100) || []
    else
      @products = Product.where(conditions.join(' AND ')).joins(:m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id LEFT JOIN brands ON products.brand_id=brands.id")
        .order(default_order('products')) || []
    end
  end

  def load_master_data_for_goods
    @brands = Brand.order('name')
    @suppliers = Supplier.limit(7).order('name')
    @colours = Colour.limit(7).order('name').map(&:name)
    @units = Unit.all
    @departments = MClass.where("parent_id IS NULL").limit(7).order('name').map(&:name)
    @categories = []
    @m_classes = MClass.where("parent_id IS NOT NULL")#[[], [], [], [], []]
    @sizes = Size.limit(7).order("concat(code, ' / ', description)").select("concat(code, ' / ', description) AS name, id")
    @size = @product.size rescue ''
    @now = Time.now.strftime('%Y-%m-%d')
    @size_details = @size.size_details rescue []
  end

  def article_code_copy
    #generate code
    find_data_article = Product.where("type_id = ? and brand_id = ? and article = ? and code is not null", @good.first.type_id, @good.first.brand_id, @good.first.article).first
    return find_data_article.code if find_data_article.present?

    max_code_article = Product.where("type_id = ? and brand_id = ? and code is not null", @good.first.type_id, @good.first.brand_id).group(:code).maximum(:code).values.first
    (max_code_article.to_i rescue 0) + 1
  end

  def article_code
    #generate code
    find_data_article = Product.where("type_id = ? and brand_id = ? and article = ? and code is not null", params[:product][:type_id], params[:product][:brand_id], params[:product][:article]).first
    return find_data_article.code if find_data_article.present?

    max_code_article = Product.where("type_id = ? and brand_id = ? and code is not null", params[:product][:type_id], params[:product][:brand_id]).group(:code).maximum(:code).values.first
    (max_code_article.to_i rescue 0) + 1
  end

  def product_params
    params.require(:product).permit(
      :article, :purchase_price, :purchase_price_date, :cost_of_products, :cost_date, :selling_price, :sell_price_date, :netto, :image, :status1, :status2, :status3, :status4, :status5, :first_po, :description, :description_2, :barcode, :brand_id, :department_id,
      :margin_percent1, :margin_percent2, :margin_percent3, :margin_percent4, :margin_rp, :colour_code, :discount_percent, :harga_kredit, :harga_member_eceran, :harga_eceran,
      :harga_bandrol, :margin_percent, :status5, :flag_pajak, :flag_barang, :fraction, :minimal_order, product_sizes_attributes: [:size_detail_id, product_details_attributes: [[:min_stock, :available_qty,
      :allocated_qty, :freezed_qty, :rejected_qty, :online_qty, :defect_qty]]], branch_prices_attributes: [:branch_id, :percentage, :nominal, :additional_min_stock]
    )
  end

  def can_view_product
    not_authorized unless current_user.can_view_product?
  end

  def can_manage_product
    not_authorized unless current_user.can_manage_product?
  end

end
