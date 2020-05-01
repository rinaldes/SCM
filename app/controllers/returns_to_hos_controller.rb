class ReturnsToHosController < ApplicationController
  before_filter :can_view_return_to_ho, only: [:index, :show]
  before_filter :can_manage_return_to_ho, only: [:new, :create, :edit, :update, :destroy]

  def add_product_pt
    @purchase_transfer = PurchaseTransfer.find_by_code(params[:number])
    @purchase_transfer_details = @purchase_transfer.product_mutation_details
    @supplier = @purchase_transfer.product_mutation_details.first.product_size.product.brand.supplier rescue nil
    @quantities = {}
    respond_to do |format|
      format.js
    end
  end

  def add_product
    @product = Product.find params[:id]
  end

  # GET /returns_to_hos
  def index
    conditions = []
    conditions = ["origin_warehouse_id=#{current_user.branch_id}"] if current_user.branch_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @returns_to_hos = ReturnsToHo.joins("INNER JOIN offices origin ON origin.id=origin_warehouse_id INNER JOIN offices destination ON destination.id=destination_warehouse_id
        LEFT JOIN users sender ON sender.id=sender_id LEFT JOIN suppliers ON suppliers.id=product_mutations.supplier_id").where(conditions.join(' AND '))
      .select("origin.office_name AS origin_name, destination.office_name AS destination_name, to_char(mutation_date, 'DD-MM-YYYY') AS mutation_date, product_mutations.code,
        CONCAT(sender.first_name, ' ', sender.last_name) AS sender_name, no_surat_jalan, product_mutations.*, suppliers.name AS supplier_name").order(default_order('product_mutations'))
      .paginate(page: params[:page], :per_page => 20)

    respond_to do |format|
      format.html # index.html.erb
      format.js
    end
  end

  # GET /returns_to_hos/1
  def show
    @good_transfer = ReturnsToHo.find(params[:id])
    @product_mutation_details = @good_transfer.product_mutation_details
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(product_size: [:product]).group_by{|pd|pd.product_size.product_id}

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /returns_to_hos/new
  def new
    nom = ReturnsToHo.count_no(DateTime.now.strftime('%m')).count_not(DateTime.now.strftime('%Y')).count
    @products = Product.select("barcode, barcode").limit(11).order("barcode").map{|product|[product.barcode, product.barcode]}
    @receive_nos = GoodTransfer.select("code, code").limit(11).order("code").map{|product|[product.code, product.code]}

    if nom > 0
      nomor = nom + 1
      if nomor.to_s.length < 6
        b = nomor.to_s.length
        while b < 6 do
          nomor = "0" + nomor.to_s
          b += 1
        end
      end
    else
      nomor = "000001"
    end
    no = Time.now
    @returns_to_ho = ReturnsToHo.new no_surat_jalan: "SJ-#{no}"
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /returns_to_hos/1/edit
  def edit
    @returns_to_ho = ReturnsToHo.find(params[:id])
    respond_to do |format|
      format.html
    end
  end

  # POST /returns_to_hos
  # POST /returns_to_hos.json
  def create
    details = params[:returns_to_ho][:product_mutation_details_attributes].values
    @returns_to_ho = ReturnsToHo.new(
      returns_to_ho_params.merge(
        origin_warehouse_id: (Office.find_by_office_name(params[:origin_branch]).id rescue nil), destination_warehouse_id: (Office.find_by_office_name(params[:HO]).id rescue nil),
        mutation_date: Time.now, status: ProductMutation::PENDING,
        total_price: details.map{|mutation|(ProductSize.find_by_id(mutation["product_size_id"]).product.cost_of_products)}.sum,
        sender_id: current_user.id, total_quantity: details.map{|mutation|mutation["quantity"].to_i}.sum,
        sell_price: details.map{|mutation|(ProductSize.find_by_id(mutation["product_size_id"]).product.selling_price)}.sum
      )
    )
    respond_to do |format|
      if @returns_to_ho.save
        flash[:notice] = t(:successfully_created)
      else
        flash.now[:error] = @returns_to_ho.errors.full_messages.join('<br/>')
      end
      format.js
    end
  end

  def get_last_number
    render json: {
      number: (('%07d' % (((ReturnsToHo.where("supplier_id=#{params[:supplier_id]} AND extract(YEAR FROM mutation_date)=#{Time.now.year}").order("id DESC").limit(1)[0].code.last.to_i rescue 0) +1))))
    }
  end

  # PUT /returns_to_hos/1
  # PUT /returns_to_hos/1.json
  def update
    @returns_to_ho = ReturnsToHo.find(params[:id])

    respond_to do |format|
      if @returns_to_ho.update_attributes(params[:returns_to_ho])
        flash.now[:notice] = 'Return to supplier was successfully updated.'
        @returns_to_ho = ReturnsToHo.new
        format.js
      else
        flash.now[:error] = @returns_to_ho.errors.full_messages
        format.js
      end
    end
  end

  def add_by_barcode
    if GoodsSize.find_by_barcode(params[:barcode]).goods.brand.supplier.name == params[:supplier]
      @goods_size = GoodsSize.find_by_barcode(params[:barcode])
    end
    @gudang_ho = Store.cek_stock_barang(params)
    respond_to do |format|
      format.js
    end
  end

  def add_item
    respond_to do |format|
      format.js
    end
  end

  def get_receiving
    @receiving = GoodTransfer.find_by_code(params[:name])
    respond_to do |format|
      format.js
    end
  end

  def get_product
    @product = Product.find_by_barcode(params[:barcode]) if params[:barcode].present?
    @product = Product.find_by_article(params[:article]) if params[:article].present?

    @list_product = ProductDetail.where("products.id=#{@product.id}").joins(product_size: [:product])
      .sort_by{|product_detail|
      size_number = product_detail.product_size.size_detail.size_number rescue 1000000
      size_number.to_i == 0 ? size_number : size_number.to_i
    }
    respond_to do |format|
      format.js
    end
  end

  def mark_as_delivered
    returns_to_ho = ReturnsToHo.find(params[:id])
    respond_to do |format|
      format.html {
        if returns_to_ho.update_attributes(status: 'Delivered')
          flash[:notice] = "successfully Delivered."
          redirect_to returns_to_hos_path
        end
      }
    end
  end

  def search_in_modal
    search_product_manual
  end

  def search_product_manual
    conditions = []
    conditions << "LOWER(suppliers.code)=LOWER('#{params[:supplier_code]}')" if params[:supplier_code].present?
    conditions << "LOWER(brands.name) LIKE LOWER('%#{params[:brand_name]}%')" if params[:brand_name].present?
    conditions << "LOWER(article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    conditions << "LOWER(m_classes.name) LIKE LOWER('%#{params[:m_class_name]}%')" if params[:m_class_name].present?
    @products = Product.where(conditions.join(' AND ')).joins(:m_class, brand: :supplier)
  end

private
  def returns_to_ho_params
    params.require(:returns_to_ho).permit(:code, :note, :receive_no, :supplier_id, :no_surat_jalan, product_mutation_details_attributes: [:quantity, :product_size_id])
  end

  def can_view_return_to_ho
    not_authorized unless current_user.can_view_return_to_ho?
  end

  def can_manage_return_to_ho
    not_authorized unless current_user.can_manage_return_to_ho?
  end
end
