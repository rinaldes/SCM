class MobileBackendsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy, :check_new_order]
  before_filter :can_view_po, only: [:index, :show]
  before_filter :can_manage_po, only: [:new, :create, :edit, :update, :destroy]
  before_filter :find_po, only: [:edit, :update, :destroy, :approve, :show, :sendemail, :print_to_pdf, :print_for_supplier]

  def check_new_order
    ordernya = ["mobile_order = true"]
    ordernya << "LOWER(status) = 'new'"
    ordernya << "store_id = #{current_user.office_id}" if(current_user.office_id.present?)
    ordernya << "notif_mobile is not true"
    @check_ordernya = Sale.where(ordernya.join(' AND '))
    if @check_ordernya.present?
      @check_ordernya.update_all(notif_mobile: true)
      get_paginated_purchase_orders
      respond_to do |format|
        format.js
      end
    end
  end

  def show
    @idnya = params[:id]
    variable_show
    filename = "Mobile Transaction " + @mo.first.sale.code + ".xlsx"
    respond_to do |format|
      format.html
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  def print_to_pdf
    @idnya = params[:id]
    variable_show
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "Mobile POS Order #{@mo.first.sale.code}.pdf",
      :disposition => 'attachment',
    )
  end

  def variable_show
    @mo = SalesDetail.joins(product: :unit).select("sales_details.*, description, selling_price, image, article, units.short_name as uom_short_name").where(sale_id: @idnya).order(:id)
    @kasir = SodEod.where(machine_id: @mo.last.sale.client_id).last.user.fullname
  end

  def kirim_pesan
    mobile_detail = SalesDetail.find(params[:id])
    mobile_detail.update_attributes(note: params[:note])
    `curl --header "Authorization: key=AIzaSyDy_vyP7Gsra5UnN-m7fX2XW4FcNpZL9u0" --header Content-Type:"application/json"  https://android.googleapis.com/gcm/send -d "{\"registration_ids\":[\"⁠⁠⁠786978841754\"], \"data\":{\"message_text\":\"#{params[:note]}\"}}"`
  end

  def kirim_pesanan
    if params[:status] == 'tunda'
      Sale.find(params[:id]).update_attributes(status: 'PENDING')
      flash[:notice] = 'Transaction pending'
    elsif params[:status] == 'terima'
      id_terima = params[:chek].to_s.split(';')
      id_tolak = params[:unchek].to_s.split(';')
      id_terima.each do |idnya|
        SalesDetail.find(idnya).update_attributes(status: 'FINISHED')
      end
      id_tolak.each do |idnya|
        SalesDetail.find(idnya).update_attributes(status: 'REJECT')
      end
      if id_terima.blank?
        Sale.find(params[:id]).update_attributes(status: 'REJECT')
      else
        Sale.find(params[:id]).update_attributes(status: 'FINISHED')
      end
      flash[:notice] = 'Transaction Finished'
    end
    respond_to do |format|
      format.js
    end
  end

  def search_sale
    @group_by = params[:group_by]
    @type = params[:type]
    get_paginated_purchase_orders
    respond_to do |format|
      format.js
    end
  end

  def get_template
    office = Office.find(params[:from])
    file_name = "TEMPLATE_PO_" + office.office_name + ".csv"
    if params[:from].present?
      product_details = Product.where("products.id IN (SELECT product_id FROM selling_prices WHERE office_id=#{params[:from]} AND end_date>NOW())")
    end
    if params[:supplier_id].present?
      product_details = Product.where("id IN (SELECT product_id FROM product_suppliers WHERE supplier_id=#{params[:supplier_id]})") rescue []
    end
    respond_to do |format|
      format.csv { send_data PurchaseOrder.all.to_csv3({}, product_details),:filename => file_name}
    end
  end

  def print_for_supplier
    @supplier = @purchase_order.supplier
    @purchase_order_details = @purchase_order.purchase_order_details
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    # PdfForSupplier.send_report(@supplier, pdf).deliver
    redirect_to purchase_order_url(@purchase_order)
    flash[:notice] = "Successfully Send Email to #{@purchase_order.supplier.name}"
  end

  def approve
    if @purchase_order.update_attributes(status: params[:purchase_order][:status])
      purchase_order_detail = PurchaseOrderDetail.where(purchase_order_id: (@purchase_order.id rescue nil))
      purchase_order_detail.each{|pod|
        PurchaseOrderDetail.find_by_product_size_id_and_purchase_order_id(pod['product_size_id'], @purchase_order.id).update_attributes(quantity: params[:pod][pod.product_size_id.to_s]) rescue nil
      }
      flash[:notice] = "Successfully #{params[:purchase_order][:status]}"
      redirect_to purchase_order_url(@purchase_order)
    end
  end

  def add_product_pr
    @purchase_request = PurchaseRequest.find_by_number(params[:number])
    @supplier = @purchase_request.purchase_request_details.first.product_size.product.brand.supplier rescue nil
    respond_to do |format|
      format.js
    end
  end

  def add_product
    @product = Product.find_by_id(params[:id])
  end

  def index
    get_paginated_purchase_orders
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    time_now = Time.now
    @purchase_order = PurchaseOrder.new date: time_now.strftime('%Y-%m-%d'), number: "PO#{Time.now.year}#{sprintf('%06d', (PurchaseOrder.last.id rescue 0)+1)}"
    load_master
  end

  def get_size
    @product = Product.find_by_id(params[:product_id])
    @list_product = ProductDetail.where("warehouse_id=#{current_user.branch.id} AND products.id=#{@product.id}").joins(product_size: [:product])
    respond_to do |format|
      format.js
    end
  end

  def get_last_number
    render json: {
      number: (('%07d' % (((PurchaseOrder.where("supplier_id=#{params[:supplier_id]} AND extract(YEAR FROM date)=#{Time.now.year}").order("id DESC").limit(1)[0].number.last.to_i rescue 0) +1))))
    }
  end

  def create
    if params[:commit] == 'Upload Data Product'
      @purchase_order = PurchaseOrder.new(purchase_order_params.merge(date: Time.now, top: Supplier.find_by_id(params[:purchase_order][:supplier_id]).long_term || 30, status: PurchaseOrder::WAITING_APPROVAL,
        number: "PO#{Time.now.year}#{sprintf('%06d', (PurchaseOrder.last.id rescue 0)+1)}"))
      CSV.foreach(params[:import_excel].path, headers: true) do |row|
        params = row.to_hash
      end
      respond_to do |format|
        if @purchase_order.save
          begin
            import = @purchase_order.import(params[:import_excel]) rescue "Failed Import. Please recheck CSV File"
            flash[:error] = t(:successfully_created)
            format.html{redirect_to purchase_order_url(@purchase_order.id)}
          rescue
            flash[:error] = "failed import. Please recheck CSV file"
            format.html{redirect_to purchase_order_url(@purchase_order.id)}
          end
        else
          raise @purchase_order.errors.full_messages.inspect
        end
      end
    else
      values_details = params[:purchase_order][:purchase_order_details_attributes].values
      @purchase_order = PurchaseOrder.new(purchase_order_params.merge(date: Time.now, total_qty: values_details.map{|po|po[:quantity].to_i}.sum,
        grand_total: values_details.map{|po|po[:hpp].to_f*po[:quantity].to_i*po[:fraction].to_i}.sum))
      respond_to do |format|
        if @purchase_order.save
          if params[:purchase_request_list].present? && params[:purchase_request_list] != '-'
            PurchaseRequest.where("number IN ('#{params[:purchase_request_list].gsub(',', "','")}')").update_all("status='#{PurchaseOrder::APPROVED}', purchase_order_id=#{@order.id}")
            values_details.each{|a|
              PurchaseRequestDetail.find_by_id(a['purchase_request_detail_id']).update_attributes(approved_qty: a['quantity']) rescue nil
            }
          end
          flash[:notice] = "#{t(:successfully_created)}"
        else
          flash[:error] = @purchase_order.errors.full_messages.join('<br/>')
        end
        format.js
      end
    end
  end

  def edit
    params[:transaction_header] = 'purchase_order'
    @supplier = @purchase_order.supplier
    @list_product = ProductDetail.where("warehouse_id=#{@purchase_order.head_office_id}").group_by{|pd|pd.product_id}
  end

  def destroy
    respond_to do |format|
      if @purchase_order.is_waiting_approval? && @purchase_order.destroy
        get_paginated_purchase_orders
        flash.now[:notice] = "PO was successfully deleted"
      else
        flash.now[:error] = t(:already_in_used)
      end
      format.js
    end
  end

  def load_master
    load_supplier
    @products = Product.select("barcode, id").limit(7).order("barcode").map{|product|[product.barcode, product.id]}
    @requests = PurchaseRequest.select("number, id").limit(7).order("number").map{|request|[request.number, request.id]}
  end

  def get_purchase_request
    @request = PurchaseRequest.find_by_number(params[:number])
    respond_to do |format|
      format.js
    end
  end

  def get_supplier
    @supplier = Supplier.find_by_name(params[:name])
    respond_to do |format|
      format.js
    end
  end

  def load_outstanding_pb
    @products = Product.where(id: ProductDetail.where("warehouse_id=#{params[:head_office_id]} AND available_qty<rop_stock").map(&:product_id)) #TO DO: filter by supplier
  end

  def autocomplete_purchase_order
    hash = []
    conditions = []
    conditions << "LOWER(number) like LOWER('%#{params[:term]}%')" if params[:term].present?
    conditions << "supplier_id=#{params[:supplier_id]}" if params[:supplier_id].present?
    conditions << "status IN (#{params[:status]})" if params[:status].present?
    @po = PurchaseOrder.where(conditions.join(' AND ')).limit(200).order('number')
    @po.collect do |p|
      supplier = p.supplier
      hash << {
        id: p.id, label: p.number, "value" => p.number, date: p.date, po_note: p.note, supplier_code: (supplier.code rescue ''), supplier_name: (supplier.name rescue ''), address: (supplier.address rescue '')
      }
    end
    respond_to do |format|
      format.js
      format.json {render json: hash}
    end
  end

  def search_product_manual
    conditions = []
    conditions << "LOWER(suppliers.name) LIKE LOWER('%#{params[:sup_code]}%')" if params[:sup_code].present?
    conditions << "LOWER(to_char(date, 'DD-MM-YYYY')) LIKE LOWER('%#{params[:date]}%')" if params[:date].present?
    conditions << "LOWER(number) LIKE LOWER('%#{params[:number]}%')" if params[:number].present?
    conditions << "status IN (#{params[:status]})" if params[:status].present?
    @po = PurchaseOrder.joins(:supplier).where(conditions.join(' AND ')).limit(100).order('number') || []
  end

  def update
    values_details = params[:purchase_order][:purchase_order_details_attributes].values rescue nil
    if @purchase_order.update_attributes(purchase_order_params.merge(total_qty: values_details.map{|po|po[:quantity].to_i}.sum, grand_total: values_details.map{|po|po[:hpp].to_i*po[:quantity].to_i}.sum))
      flash[:notice] = t(:successfully_updated)
    else
      flash[:error] = @purchase_order.errors.full_messages.join('<br/>')
    end
    respond_to do |format|
      format.js
    end
  end

  def search_in_modal
    search_product_manual
  end

  def search_supplier
    conditions = []
    conditions << "LOWER(code) LIKE LOWER('%#{params[:supplier_code]}%')" if params[:supplier_code].present?
    conditions << "LOWER(name) LIKE LOWER('%#{params[:supplier_name]}%')" if params[:supplier_name].present?
    conditions << "LOWER(address) LIKE LOWER('%#{params[:supplier_address]}%')" if params[:supplier_address].present?
    conditions << "LOWER(city) LIKE LOWER('%#{params[:supplier_city]}%')" if params[:supplier_city].present?
    @suppliers_list2 = Supplier.where(conditions.join(' AND ')).paginate(page: params[:page], per_page: 10) || []
    respond_to do |format|
      format.js
    end
  end

  private
    def purchase_order_params
      params.require(:purchase_order).permit(
        :due_date, :expected_delivery_date, :date, :number, :supplier_id, :note,
        :number, :head_office_id, :top, :status, :purchase_request_id,
        purchase_order_details_attributes: [:id, :quantity, :product_id, :hpp, :unit_type, :fraction]
      )
    end

    def get_paginated_purchase_orders
      conditions = ["sales.mobile_order = true"]
      conditions << "sales.store_id = #{params[:store]}" if(params[:store].present? && params[:store] != "0")
      conditions << "sales.store_id = #{current_user.branch_id}" if(current_user.branch_id.present?)
      conditions << "sales.transaction_date < (to_date('#{params[:to]}', 'DD-MM-YYYY') + '1 day'::interval)" if params[:to].present?
      conditions << "sales.transaction_date >= to_date('#{params[:start]} 00:00:00', 'DD-MM-YYYY HH24:MI:SS')" if params[:start].present?
      conditions << "LOWER(sales.code) like LOWER('%#{params[:struck]}%')" if params[:struck].present?
      conditions << "LOWER(products.article) like LOWER('%#{params[:sku]}%')" if params[:sku].present?
      conditions << "LOWER(products.description) like LOWER('%#{params[:description]}%')" if params[:description].present?
      conditions << "LOWER(sales_details.status) like LOWER('%#{params[:status]}%')" if params[:status].present?
      conditions << "LOWER(members.name) like LOWER('%#{params[:member]}%')" if params[:member].present?
      conditions << "LOWER(members.city) like LOWER('%#{params[:city]}%')" if params[:city].present?
      conditions << "LOWER(members.kelurahan) like LOWER('%#{params[:kelurahan]}%')" if params[:kelurahan].present?
      conditions << "LOWER(members.kecamatan) like LOWER('%#{params[:kecamatan]}%')" if params[:kecamatan].present?
      conditions << "LOWER(sales.code) like LOWER('%#{params[:no_struck]}%')" if params[:no_struck].present?
      conditions << "LOWER(concat(users.first_name, ' ', users.last_name)) like LOWER('%#{params[:sales]}%')" if params[:sales].present?
      case @group_by
      when "Cashier"
        @purchase_orders = Sale.joins(:user, :store).select("user_id, store_id, count(*) as receipt_count, sum(total_price) as total_price")
        .where(conditions.join(' AND ')).where.not(status: "Cart").order(params[:sort].to_s.gsub('-', ' '))
          .group(:user_id, :store_id)
          .paginate(page: params[:page], per_page: PER_PAGE) || []
      when "Member-Price"
        @purchase_orders = Sale.joins(:member).select("member_id, sum(total_price) as total_price")
        .where(conditions.join(' AND ')).where.not(status: "Cart").order(params[:sort].to_s.gsub('-', ' '))
          .group(:member_id)
          .paginate(page: params[:page], per_page: PER_PAGE) || []
      when "Member-Item"
        @purchase_orders = SalesDetail.joins(:product, sale: :member).where(conditions.join(' AND ')).where.not("sales.status = 'Cart'")
          .select("product_id, sales.member_id, sales_details.sku_id, sum(sales_details.total_price) as sale_total_price, sum(sales_details.quantity) as qty")
          .group("member_id, product_id, sku_id")
          .paginate(page: params[:page], per_page: PER_PAGE) || []
      when "Sales-Summary Item"
        @purchase_orders = SalesDetail.joins(:product, sale: :user).where(conditions.join(' AND ')).where.not("sales.status = 'Cart'")
          .select("product_id, sales.user_id, sales_details.sku_id, sum(sales_details.total_price) as sale_total_price, sum(sales_details.quantity) as qty")
          .group("user_id, product_id, sku_id")
          .paginate(page: params[:page], per_page: PER_PAGE) || []
      else
        @purchase_orders = Sale.joins(:user)
          .select("sales.*, sales.code as sales_code, transaction_date, concat(first_name) as name")
          .where(conditions.join(' AND ')).where.not(status: "Cart").order('sales.transaction_date desc')
          .paginate(page: params[:page], per_page: PER_PAGE) || []
      end
    end

    def can_view_po
      not_authorized unless current_user.can_view_po?
    end

    def can_manage_po
      not_authorized unless current_user.can_manage_po?
    end

    def find_po
      @purchase_order = Sale.joins(:store, :user).select("sales.*, concat(first_name) as name, office_name").find(params[:id])
    end
end
