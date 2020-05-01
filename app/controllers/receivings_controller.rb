class ReceivingsController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  before_filter :find_receipt, only: [:show, :mark_as_inspected, :print_to_pdf]
  before_filter :can_view_receiving, only: [:index, :show]
  before_filter :can_manage_receiving, only: [:new, :create, :edit, :update, :destroy]

  def autocomplete_receiving_number
    hash = []
    conditions = ["status<>'#{Receiving::CLOSED}'"]
    conditions << "supplier_id=#{params[:supplier_id]}" if params[:supplier_id].present?
    conditions << "LOWER(number) LIKE LOWER('%#{params[:term]}%')" if params[:term].present?
    conditions << "LOWER(consigment_number) LIKE LOWER('%#{params[:consignment_number]}%')" if params[:consignment_number].present?
    conditions << "number NOT IN (#{params[:present_receiving]})" if params[:present_receiving].present?
    conditions << "head_office_id=#{params[:head_office_id]}" if params[:head_office_id].present?
    conditions << "head_office_id=#{current_user.office_id}" if current_user.office_id.present?
    receivings = Receiving.where(conditions.join(" AND ")).limit(25)
    receivings.collect do |receiving|
      supplier = receiving.supplier
      hash << {
        id: receiving.id, label: params[:consignment_number].present? ? receiving.consigment_number : receiving.number,
        value: params[:consignment_number].present? ? receiving.consigment_number : receiving.number, date: receiving.date,
        supplier_code: supplier.code, supplier_name: supplier.name, supplier_address: supplier.address, supplier_id: supplier.id, consignment_number: receiving.consigment_number,
        number: receiving.number, head_office_id: receiving.head_office_id
      }
    end
    render json: hash
  end

  def index
    get_paginated_receivings
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def add_product
    @product = params[:barcodes].present? ? Product.where(barcode: params[:barcodes].split(' ')) : Product.where(id: params[:id])
    product = @product.first
    params[:hpp] = SellingPrice.where("product_id=#{product.id} AND now() BETWEEN start_date AND end_date").limit(1).order('id DESC').last.hpp rescue 0
    @discount = PurchasePrice.where("product_id = #{product.id} AND now() BETWEEN start_date AND end_date").limit(1).order('id DESC').last.purchase_price_discounts.last.disc_percentage rescue 0
    @supplier = product.brand.supplier rescue nil
    respond_to do |format|
      format.js
    end
  end

  def add_product_po
    @purchase_order = PurchaseOrder.find_by_number(params[:number])
    @supplier = @purchase_order.supplier rescue nil
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(product_size: [:product]).group_by{|product_detail|product_detail.product_size.product_id}
    @received_products = Receiving.where("purchase_order_id=?", @purchase_order.id)
    @quantities = {}
    respond_to do |format|
      format.js
    end
  end

  def mark_as_inspected
    if @receiving.status != Receiving::INSPECTED && @receiving.update_attributes(status: Receiving::INSPECTED)
      @receiving.receiving_details.map{|detail|[detail.product_size_id, detail.quantity]}.each{|receipt_detail|
        product_detail = ProductDetail.find_by_warehouse_id_and_product_size_id(current_user.head_office_id, receipt_detail[0])
        product_detail.update_attributes(available_qty: product_detail.available_qty+receipt_detail[1]) if receipt_detail[1].present?
      }
      flash[:notice] = t(:successfully_inspected)
    else
      flash[:error] = t(:already_inspected_by_another_user)
    end
    redirect_to receivings_url
  end

  def show
    @receiving = Receiving.find params[:id]
    @purchase_order = @receiving.purchase_order
    @supplier = @receiving.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{|pd|pd.product_id}
    @receiving_details = @receiving.receiving_details.where("quantity>0").includes(:product).order(default_order('receiving_details'))
    #load_master
  end

  def print_to_pdf
    # if @receiving.has_printed
      # flash[:error] = "Can't print more than once!"
      # return redirect_to @receiving
    # else
      @supplier = @receiving.supplier
      @purchase_order = @receiving.purchase_order
      html = render_to_string(:layout => "pdf_layout.html")
      pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
      send_data(pdf,
        :filename    => "Receiving #{@receiving.number}.pdf",
        :disposition => 'attachment',
      )
    # end
  end

  def export_to_xls
    @receiving = Receiving.find params[:id]
    @purchase_order = @receiving.purchase_order
    @supplier = @receiving.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{|pd|pd.product_id}
    load_master
    @filenames = "Goods Receipt"
    @filenames << "_" + @receiving.number
    respond_to do |format|
      format.xls { headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xls\""}
    end
  end

  def print_rog_pdf
    @receiving = Receiving.find params[:id]
    @supplier = @receiving.supplier
    @purchase_order = @receiving.purchase_order
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "Receipt of goods #{@receiving.number}.pdf",
      :disposition => 'attachment',
    )
  end

  def print_dpe_pdf
    @receiving = Receiving.find params[:id]
    if @receiving.has_printed_dpe
      flash[:error] = "Can't print more than once!"
      return redirect_to @receiving
    else
      @supplier = @receiving.supplier
      @purchase_order = @receiving.purchase_order
      html = render_to_string(:layout => "pdf_layout.html")
      pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
      send_data(pdf,
        :filename    => "Proof Data Processing #{@receiving.number}.pdf",
        :disposition => 'attachment',
      )
    end
  end

  def new
    @receiving = Receiving.new date: Time.now.strftime('%d-%m-%Y')
    #, number: "R#{Time.now.year}#{sprintf('%06d', (Receiving.last.id rescue 0)+1)}"
    load_master
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @receiving = Receiving.find params[:id]
    @purchase_order = @receiving.purchase_order
    @supplier = @receiving.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{|pd|pd.product_id}
    load_master
    respond_to do |format|
      format.html
    end
  end

  def get_last_number
    render json: {
      number: sprintf("R#{Time.now.year}#{sprintf('%06d', Receiving.last.number.gsub("R#{Time.now.year}", '').to_i+1)}")
    }
  end

  def create
    quantity = params[:receiving][:receiving_details_attributes].values.map{|rc|rc['quantity'].to_i}.sum
    @purchase_order = PurchaseOrder.find_by_id(params[:receiving][:purchase_order_id])
    supplier = Supplier.find_by_id params[:receiving][:supplier_id]
    outstanding_qty = @purchase_order.total_qty.to_f-quantity.to_f-@purchase_order.receivings.map(&:received_qty).sum if @purchase_order.present?
    @receiving = Receiving.new(
      receiving_params.merge(
        number: "R#{Time.now.year}#{sprintf('%06d', (Receiving.last.id rescue 0)+1)}",
        due_date: (Time.now+supplier.long_term.to_i.days rescue Time.now+7.days),
        date: Time.now,
        outstanding_amount: params[:receiving][:total],
        received_qty: quantity,
        outstanding_qty: (outstanding_qty < 0 ? 0 : outstanding_qty rescue nil)
      )
    )
    respond_to do |format|
      if @receiving.save
        hash = {}
        params[:receiving][:receiving_details_attributes].values.map{|a|
          hash = hash.merge(a.values[1] => a.values[0])
          hpp_ave = Product.find_by_id(a['product_id']).get_hpp_average
          rd = ReceivingDetail.find_by_receiving_id_and_product_id(@receiving.id, a['product_id'])
          rd.update_attributes(hpp_average: hpp_ave)
          SellingPrice.where("end_date > now() AND product_id=#{a['product_id']}").update_all("hpp_average=#{hpp_ave}")
          SellingPrice.where("end_date > now() AND product_id=#{a['product_id']} AND selling_price>0")
            .update_all("margin_amount=selling_price-hpp_average, margin_percent=(selling_price-hpp_average)/selling_price*100")
        }
        po = PurchaseOrder.find_by_number(params[:pr_name])
        if po.present?
          detail = po.purchase_order_details
          po_closed = false
          Receiving.where("purchase_order_id=#{po.id}").group_by(&:product_size_id).each{|b|
            if detail.find_by_product_size_id(b[0]).quantity >= b[1].map(&:quantity).compact.sum+hash["#{b[0]}"].to_i
              po_closed = false
              break
            end
            po_closed = true
          }
          po.update_attributes(status: po_closed ? 'CLOSED' : PurchaseRequest::TRANSFER_ON_PROGRESS)
        end
        # flash[:notice] = t(:successfully_created)
        begin
          DatabaseLain.establish_connection
          save_to_the_other_world# if DatabaseLain.connected?
          flash[:notice] = "GR Dibuat, berhasil untuk mengirimnya ke ERP."
        rescue
          flash[:warning] = "GR Dibuat, namun gagal untuk mengirimnya ke ERP."
        end
      else
        flash.now[:error] = @receiving.errors.full_messages.join('<br/>')
      end
      format.js
    end
  end

  def save_to_the_other_world
    if DatabaseLain.connected?
      total = @receiving.receiving_details.where("quantity>0").map(&:subtotal).sum
      total_price = total / 1.1
      total_ppn = total - total_price
      ptnr_id = PtnrMstr.find_by_ptnr_name(Supplier.find(@receiving.supplier_id).name).ptnr_id rescue 0
      unless GrMstr.find_by_gr_code(@receiving.number).present?
        @gr_mstr = GrMstr.new(gr_oid: SecureRandom.uuid, gr_dom_id: 1, gr_branch_id: 10001, gr_en_id: 1, gr_add_by: current_user.username, gr_add_date: DateTime.now, gr_ptnr_id: ptnr_id, gr_code: @receiving.number, gr_date: @receiving.date, gr_tax_basis_amount: total_price, gr_tax_amount: total_ppn, gr_total: total, gr_ptnr_code: Supplier.find(@receiving.supplier_id).code)
        @gr_mstr.save
      else
        @gr_mstr = GrMstr.find_by_gr_code(@receiving.number)
        @gr_mstr.update_attributes(gr_upd_by: current_user.username, gr_upd_date: DateTime.now, gr_ptnr_id: ptnr_id, gr_date: @receiving.date, gr_tax_basis_amount: total_price, gr_tax_amount: total_ppn, gr_total: total, gr_ptnr_code: Supplier.find(@receiving.supplier_id).code)
      end
      @receiving.update_attributes(sent_to_erp: Time.now())
    end
  end

  def update
    @receiving = Receiving.find(params[:id])
    r_quantity = params[:receiving][:receiving_details_attributes].values.map{|rc|rc['quantity'].to_i}.sum
    save_to_the_other_world
    if @receiving.update_attributes(params.require(:receiving).permit(
      :purchase_order_id, :date, :number, :supplier_id, :note, :received_qty, :purchased_qty, :total, :consigment_number, :head_office_id
    ).merge(status: params[:receiving][:status]))
      receiving_details = ReceivingDetail.where(receiving_id: (@receiving.id rescue nil))
      params[:receiving][:receiving_details_attributes].each{|rd, i|
        quantity = params[:receiving][:receiving_details_attributes][rd][:quantity]
        product_id = params[:receiving][:receiving_details_attributes][rd][:product_id]
        key = "#{Time.now.to_i}#{i}#{i}";
        #raise rd.inspect
        @receiving.update_attributes(received_qty:r_quantity)
        # product_size_id
        # warehouse_id
        # product_id
        @rede = ReceivingDetail.find_by_product_id_and_receiving_id(product_id.to_i, @receiving.id)
        @pede = ProductDetail.find_by_product_id_and_warehouse_id(product_id, @receiving.head_office_id)
        old_avai_qty = @pede.available_qty
        old_qty = @rede.quantity
        #raise old_avai_qty.inspect
        real_qty = old_avai_qty.to_i - old_qty.to_i

        ReceivingDetail.find_by_product_id_and_receiving_id(product_id, @receiving.id).update_attributes(quantity: quantity)
        @pede.update_attributes(available_qty: real_qty)

      }
      begin
        DatabaseLain.establish_connection
        save_to_the_other_world# if DatabaseLain.connected?
        flash[:notice] = "GR Diubah, berhasil untuk mengirimnya ke ERP."
      rescue
        flash[:warning] = "GR Diubah, namun gagal untuk mengirimnya ke ERP."
      end
      redirect_to receivings_path
    else
      @purchase_order = @receiving.purchase_order
      @supplier = @receiving.supplier
      @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").joins(product_size: [:product]).group_by{|pd|pd.product_size.product_id}
      flash[:error] = @receiving.errors.full_messages.join('</br>')
      render "edit"
    end
  end

  def destroy
    @receiving = Receiving.find(params[:id])
    @receiving.destroy
    get_paginated_receivings
    respond_to do |format|
      format.js
    end
  end

  def search
    @receivings = Receiving.search(params[:search]).paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @receiving = Receiving.new
      format.js
    end
  end

  def get_number
    @receiving_number = Receiving.number(params)
    respond_to do |format|
      format.js
    end
  end

  def render_404
    respond_to do |format|
      format.html { render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found }
      format.xml  { head :not_found }
      format.any  { head :not_found }
    end
  end

  def load_master
    load_supplier
    @products = Product.select("barcode, id").limit(7).order("barcode").map{|product|[product.barcode, product.id]}
    @orders = PurchaseOrder.select("number, id").limit(7).order("number").map{|product|[product.number, product.id]}
  end

  def get_purchase_order
    @order = PurchaseOrder.find_by_number(params[:number])
    respond_to do |format|
      format.js
    end
  end

  def get_product_details
    @purchase_order = PurchaseOrder.find(params[:purchase_orders_id])
    respond_to do |format|
      format.js
    end
  end

private
  def get_paginated_receivings
    conditions = []
    conditions << "receivings.head_office_id=#{current_user.office_id}" if current_user.office_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @receivings = Receiving.where(conditions.join(' AND ')).order(default_order('receivings')).joins(:supplier, :head_office)
      .joins("LEFT JOIN purchase_orders ON purchase_orders.id=receivings.purchase_order_id")
      .select("office_name, receivings.*, suppliers.name AS supplier_name, purchase_orders.number AS po_number, purchase_orders.total_qty as total_qty")
      .paginate(:page => params[:page], :per_page => 100) || []
      #.joins('left outer join receiving_details on receiving_details.receiving_id = receivings.id')
      #.group('receivings.id, suppliers.id, purchase_orders.id, office_name')
  end

  def find_receipt
    @receiving = Receiving.find(params[:id])
  end

  def receiving_params
    params.require(:receiving).permit(
      :purchase_order_id, :date, :number, :supplier_id, :note, :received_qty, :purchased_qty, :total, :consigment_number, :head_office_id, receiving_details_attributes: [
        :product_id, :quantity, :hpp, :hpp_average, :unit_type, :_destroy, :total_price, :fraction
      ]
    )
  end

  def can_view_receiving
    not_authorized unless current_user.can_view_receiving?
  end

  def can_manage_receiving
    not_authorized unless current_user.can_manage_receiving?
  end
end
