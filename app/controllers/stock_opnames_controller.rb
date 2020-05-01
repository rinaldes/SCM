class StockOpnamesController < ApplicationController
  before_filter :can_view_stock_opname, only: [:index, :show]
  before_filter :can_manage_stock_opname, only: [:new, :create]

  def offices_per_rack
    @rack = PlanogramsStore.joins(:planogram).select("planograms_stores.id, planogram_id, planograms.rack_number as rack_number").where("branch_id=#{params[:office_id]}")
  end

  def rack_selected
    conditions = ["rak_id = #{params[:rack_id]}"]
    conditions << "planos.end >= to_date('#{params[:so_date]}', 'DD-MM-YYYY')"
    conditions << "planos.start <= to_date('#{params[:so_date]}', 'DD-MM-YYYY')"
    planos = Plano.where(conditions.join(' AND '))
    #byebug
    rack_pro = ''
    planos.each do |plano|
      rack_pro += plano.product_id.to_s + "," if (plano.product_id.present?)
    end
    @rack = rack_pro.chop
  end

  def update
    if params[:diklik] == "revisi"
      @status = "REVISI"
    else
      @status = "COMPLETED"
    end
    end_stock_opname_data
    unless params[:diklik] == "revisi"
      redirect_to stock_opname_path
    else
      redirect_to edit_stock_opname_path(params[:id])
    end
  end

  def edit
    @stock_opname = StockOpname.find params[:id]
    @stock_opname_details = @stock_opname.stock_opname_details
    @office_id = @stock_opname.office_id
    @office_class = @stock_opname.office.class.to_s
    @departments = Department.where(parent_id: nil).order(default_order('m_classes'))
    get_products
  end

  def index
    get_paginated_stock_opnames
    respond_to do |format|
      format.js
      format.html
    end
  end

  def new
    @cabang = Branch.active_store.map{|x| [x.office_name, x.id]}
    @office_id = current_user.office_id
    @departments = Department.where(parent_id: nil).order(default_order('m_classes'))
    @stock_opname = StockOpname.find_by_id(params[:id]) || StockOpname.new
    get_products
    respond_to do |format|
      format.js
      format.html
    end
  end

  def end_stock_opname_data
    office_id = current_user.office_id if current_user.office_id.present?
    office_id = params[:stock_opname][:office_id] rescue params[:office_id] if params[:stock_opname][:office_id].present? || params[:office_id].present?
    @stock_opname = StockOpname.where(office_id: office_id).last

    if @stock_opname.so_type == 'All Item'
      product_detail = ProductDetail.where("warehouse_id=#{office_id}").select("available_qty AS qty")
    elsif @stock_opname.so_type == 'By Item'
      p_id = @stock_opname.stock_opname_details.map(&:product_id)
      product_detail = ProductDetail.where("warehouse_id=#{office_id}").where(product_id: p_id).select("available_qty AS qty")
    elsif @stock_opname.so_type == 'By Rack'
      product_detail = ProductDetail.where("warehouse_id=#{office_id}").select("available_qty AS qty")
    end


    receiving_conditions = ["head_office_id=#{office_id}"]
    receiving_conditions << "receivings.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?
    received_total = ReceivingDetail.where(receiving_conditions.join(' AND ')).joins(:receiving).map(&:calculated_qty).compact.sum

    # if @stock_opname.office.class.to_s == 'Branch'
      mutation_out_conditions = ["origin_warehouse_id=#{office_id} AND type='GoodTransfer'"]
      mutation_out_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

      retur_conditions = ["origin_warehouse_id=#{office_id} AND type='ReturnsToHo'"]
      retur_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

      mutation_in_conditions = ["destination_warehouse_id=#{office_id} AND status='#{ProductMutation::RECEIVED}' AND type='GoodTransfer'"]
      mutation_in_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

      sold_conditions = ["store_id=#{office_id} AND sales.status='FINISHED'"]
      sold_conditions << "sales.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

      receive_transfer_conditions = ["destination_warehouse_id=#{office_id} AND status='#{ProductMutation::RECEIVED}' AND type='PurchaseTransfer'"]
      receive_transfer_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

      @stock_opname.update_attributes(
        sold: SalesDetail.where(sold_conditions.join(' AND ')).joins(:sale).map(&:quantity).compact.sum,
        received_from_transfer: ProductMutationDetail.where(receive_transfer_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum+received_total,
        mutation_in: ProductMutationDetail.where(mutation_in_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
        mutation_out: ProductMutationDetail.where(mutation_out_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
        last_stock: product_detail.map(&:qty).compact.sum, retur: ProductMutationDetail.where(retur_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum, end_date: Time.now,
        status: @status, actual_stock: (params["qty_actual"].map{|a|a[1].to_i}.sum rescue 0)
      )
    # else
    #   retur_conditions = ["head_office_id=#{office_id}"]
    #   retur_conditions << "returns_to_suppliers.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

    #   mutation_in_conditions = ["destination_warehouse_id=#{office_id} AND status='#{ProductMutation::RECEIVED}' AND type IN ('ReturnsToHo', 'GoodTransfer')"]
    #   mutation_in_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

    #   mutation_out_conditions = ["origin_warehouse_id=#{office_id} AND type IN ('PurchaseTransfer', 'GoodTransfer')"]
    #   mutation_out_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

    #   sold_conditions = ["store_id=#{office_id} AND sales.status='FINISHED'"]
    #   sold_conditions << "sales.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?

    #   @stock_opname.update_attributes(
    #     received_from_transfer: received_total,
    #     mutation_in: ProductMutationDetail.where(mutation_in_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
    #     mutation_out: ProductMutationDetail.where(mutation_out_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
    #     last_stock: product_detail.map(&:qty).compact.sum, retur: ReturnsToSupplier.where(retur_conditions.join(' AND ')).map(&:quantity).compact.sum, end_date: Time.now, status: @status,
    #     actual_stock: params["qty_actual"].map{|a|a[1].to_i}.sum
    #   )
    # end
    @stock_opname.stock_opname_details.each{|sod|
      #begin
        if sod.product.present?
          return_to_ho_conditions = ["origin_warehouse_id=#{@stock_opname.office_id} AND type='ReturnsToHo' AND product_id=#{sod.product_id}"]
          return_to_ho_conditions << "product_mutations.created_at > '#{@stock_opname.start_date}'" if @stock_opname.present?
          if ((params["qty_store"][sod.id.to_s].present?) || (params["qty_warehouse"][sod.id.to_s].present?))
            store_dan_warehouse = "store:" + params["qty_store"][sod.id.to_s].to_i.to_s + ", warehouse:" + params["qty_warehouse"][sod.id.to_s].to_i.to_s
          end
          pdd = ProductDetail.where("warehouse_id=#{office_id} AND product_id=#{sod.product_id}").select("available_qty AS qty")
          if @stock_opname.so_type == "All Item"
            sod.update_attributes(qty_actual: (params["qty_actual"][sod.id.to_s] rescue 0), explanation: (store_dan_warehouse rescue ''), qty_virtual: pdd.map(&:qty).compact.sum, hpp: (sod.product.product_price(Time.now).hpp_average rescue 0))
          else
            sod.update_attributes(qty_actual: (params["qty_actual"][sod.id.to_s] rescue 0),
              explanation: (store_dan_warehouse rescue ''),
              sold: SalesDetail.where("product_id = #{sod.product_id}").where(sold_conditions.join(' AND ')).joins(:sale).map(&:quantity).compact.sum,
              received_from_transfer: ReceivingDetail.where("product_id = #{sod.product_id}").where(receiving_conditions.join(' AND ')).joins(:receiving).map(&:calculated_qty).compact.sum,
              mutation_in: ProductMutationDetail.where(mutation_in_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
              mutation_out: ProductMutationDetail.where(mutation_out_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
              retur: ProductMutationDetail.where(return_to_ho_conditions.join(' AND ')).joins(:product_mutation).map(&:quantity).compact.sum,
              qty_virtual: pdd.map(&:qty).compact.sum, hpp: (SellingPrice.where("product_id=#{sod.product_id} AND office_id = #{@stock_opname.office_id} AND end_date>NOW()").last.hpp_average rescue 0))
          end
          pd = ProductDetail.find_by_product_id_and_warehouse_id(sod.product_id, @stock_opname.office_id)
          sod.generate_history if @status == "COMPLETED"
        end
      #rescue
      #end
    }
  end

  def start_stock_opname_data
    @stock_opname = StockOpname.where(office_id: params[:office_id], status: 'ONPROCESS').first
    rack_item = ''
    so_item = params[:so_item]
    if (Planogram.find(params[:rack_number]).present? rescue false)
      Planogram.find(params[:rack_number]).planos.order(:shelving).each do |plano|
        rack_item << plano.product_id.to_s + ", "
      end
      so_item = rack_item.chop.chop
    end

    if @stock_opname.blank?
      unless params[:so_type] == 'All Item'
        product_details = ProductDetail.where("warehouse_id=#{params[:office_id]} AND product_id IN(#{so_item})").joins(:product).select("available_qty, available_qty AS qty, product_details.id, product_id")
      else
        product_details = ProductDetail.where("warehouse_id=#{params[:office_id]}").where(products: {department_id: params[:so_dept]}).joins(:product).select("available_qty, available_qty AS qty, product_details.id, product_id")
      end

      @stock_opname = StockOpname.new office_id: params[:office_id], warehouse_id: params[:warehouse_id], status: 'ONPROCESS', inspector_id: current_user.id, start_date: Time.now,
        system_stock: product_details.map(&:qty).compact.sum, opname_number: sprintf('%06d', StockOpname.count+1), so_type: params[:so_type]
      if @stock_opname.save
        product_details.each{|product_detail|
          @stock_opname.stock_opname_details.create system_stock: product_detail.available_qty, product_id: product_detail.product_id
        }
      end
    end
  end

  def select_stock_opname_data
    @stock_opname = StockOpname.find_by_office_id_and_status(params[:office_id], 'ONPROCESS')
    @office_id = current_user.office_id || params[:office_id]
  end

  def get_quantity_data
    @product = Product.find_by_id(params[:product_id])
    @product_details = ProductDetail.where("warehouse_id=#{params[:warehouse_id]} AND products.id=#{params[:product_id]}").joins(product_size: [:product, :size_detail])
      .order("size_number")
    respond_to do |format|
      format.js
    end
  end

  def show
    @stock_opname = StockOpname.find(params[:id])
    @stock_opname_details = StockOpnameDetail.where("stock_opname_id = ? AND qty_actual IS NOT NULL", @stock_opname.id)
    @qty_virtual = @stock_opname_details.map(&:qty_virtual).compact.sum
    @stock_opname.update_attributes(sold: @stock_opname_details.map(&:sold).compact.sum) if @stock_opname.sold.blank?
    @stock_opname.update_attributes(received_from_transfer: @stock_opname_details.map(&:received_from_transfer).compact.sum) if @stock_opname.received_from_transfer.blank?
    filename = "Stock Opname " + @stock_opname.opname_number + ".xlsx"

    respond_to do |format|
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
      format.html # show.html.erb
      format.xls {headers["Content-Disposition"] = "attachment; filename=SO-#{@stock_opname.opname_number}.xls" }
    end
  end

  def print_to_pdf
    @stock_opname = StockOpname.find(params[:id])
    @stock_opname_details = StockOpnameDetail.where("stock_opname_id = ? AND qty_actual IS NOT NULL", @stock_opname.id)
    @qty_virtual = @stock_opname_details.map(&:qty_virtual).compact.sum
    @stock_opname.update_attributes(sold: @stock_opname_details.map(&:sold).compact.sum) if @stock_opname.sold.blank?
    @stock_opname.update_attributes(received_from_transfer: @stock_opname_details.map(&:received_from_transfer).compact.sum) if @stock_opname.received_from_transfer.blank?
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "Stock Opname #{@stock_opname.opname_number}.pdf",
      :disposition => 'attachment',
    )
  end

  def print_lkso
    @stock_opname = StockOpname.find(params[:id])

    @so_details_pos = StockOpnameDetail.joins(:product).where("stock_opname_id = ? AND qty_actual IS NOT NULL", @stock_opname.id).where("(qty_actual - qty_virtual) > 0")
    @so_details_neg = StockOpnameDetail.joins(:product).where("stock_opname_id = ? AND qty_actual IS NOT NULL", @stock_opname.id).where("(qty_actual - qty_virtual) < 0")

    @variance_pos = []
    @so_details_pos.each do |sod|
      @variance_pos << sod.diff.to_f*sod.hpp.to_f
    end

    @variance_neg = []
    @so_details_neg.each do |sod|
      @variance_neg << sod.diff.to_f*sod.hpp.to_f
    end

    @total_var_pos = @so_details_pos.sum(:qty_actual) - @so_details_pos.sum(:qty_virtual)
    @total_var_neg = @so_details_neg.sum(:qty_actual) - @so_details_neg.sum(:qty_virtual)

    @total_amount_pos = @variance_pos.sum.to_f# * @total_var_pos.to_f
    @total_amount_neg = @variance_neg.sum.to_f# * @total_var_neg.to_f

    @total_amount = @total_amount_neg + @total_amount_pos

    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "LHSO #{@stock_opname.opname_number}.pdf",
      :disposition => 'attachment',
    )
  end

  def create
    @stock_opname = StockOpname.new(stock_opname_params)
    respond_to do |format|
      if @stock_opname.save
        flash.now[:notice] = 'Stock opname was successfully created'
        format.html { redirect_to stock_opnames_path}
      else
        @cabang = current_user.branches.map{|x| [x.name, x.id]}
        flash.now[:error] = @stock_opname.errors.full_messages
        format.html { render "new" }
      end
    end
  end

  def form_import_packing_list

    respond_to do |format|
      format.html { render :layout => false }
    end
  end

  def add_by_barcode
    @goods_size = Product.find_by_barcode(params[:barcode])
    respond_to do |format|
      format.js
    end
  end

  def import_packing_list
    @data = StockOpname.import(params)
    @cabang = current_user.branches.map{|x| [x.name, x.id]}
    ho = current_user.head_offices.map{|x| [x.name, x.id]}
    ho.each do |x|
      @cabang << x
    end
    no = StockOpname.number
    number = "OP/#{romanian_month} - #{('000000'.last(6-no.to_s.length)) + no.to_s }"
    @stock_opname = StockOpname.new opname_number: number

    render :new

  end

  def to_excel_example
    respond_to do |format|
      format.xls {render 'stock_opnames/to_excel_example.xls.writeexcel'}
    end
  end

  def get_products
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?

    @products = Product.where(conditions.join(' AND ')).paginate(:page => params[:page], :per_page => 10) || []
  end

  def buka_gudang
    if params[:cabang].present?
      @store = Store.where(branch_id: params[:cabang]).map{|x| [x.name, x.id]}
    else
      @store = Store.where(head_office_id: params[:head_office]).map{|x| [x.name, x.id]}
    end
    respond_to do |format|
      format.js
    end
  end

  def get_stock
    goods_size = Product.find(params[:id])
    last_stock = goods_size.goods_details.sum(:quantity) rescue goods_size.goods_details.map{|x| x.goods_quantity_logs.sum(:new_quantity) }.sum
    respond_to do |format|
      format.json {render json: {
        last_stock: last_stock
      }}
    end
  end

=begin
  def search
    conditions = []
    conditions << "stock_opnames.date >= DATE('#{params[:start_date]}')" if params[:start_date].present?
    conditions << "stock_opnames.date <= DATE('#{params[:end_date]}')" if params[:end_date].present?
    conditions << "stock_opnames.opname_number = '#{params[:number]}'" if params[:number].present?
    conditions << "stock_opnames.store_id = #{params[:store_id]}" if params[:store_id].present?
    conditions << "stock_opnames.inspector_id = #{params[:inspector_id]}" if params[:inspector_id].present?
    conditions << "stock_opname_details.explanation = '#{params[:explanation]}'" if params[:explanation].present?
    @stock_opnames = StockOpname.joins(:stock_opname_details).joins(:offices).where(conditions.join(' and ')).order("id DESC").paginate(:page => params[:page], :per_page => 5) || []
    respond_to do |format|
      format.js
    end
  @stock_opnames = StockOpname.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @stock_opnames = StockOpname.new
      format.js
    end
  end
=end

   def stock_opname_params
    params.require(:stock_opname).permit(
      :date, :opname_number, :inspector_id, :branch_id, stock_opname_details_attributes: [:product_size_id, :qty_virtual, :qty_actual, :explanation]
    )
  end

  def can_view_stock_opname
    not_authorized unless current_user.can_view_stock_opname?
  end

  def can_manage_stock_opname
    not_authorized unless current_user.can_manage_stock_opname?
  end

  private
  def get_paginated_stock_opnames
=begin
    conditions = []
    conditions << "office_id=#{current_user.office_id}" if current_user.office_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @stock_opnames = StockOpname.where(conditions.join(' AND ')).order(default_order('stock_opnames'))
      .joins("INNER JOIN offices ON offices.id=office_id")
      .select("offices.office_name AS office_name, stock_opnames.*")
      .paginate(:page => params[:page], :per_page => 10) || []
=end
    conditions = []
    conditions << "office_id=#{current_user.office_id}" if current_user.office_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?
    @stock_opnames = StockOpname.includes(:office).where(conditions.join(' AND ')).joins(:office).select("stock_opnames.*, offices.office_name AS office_name").order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 25) || []


  end
end
