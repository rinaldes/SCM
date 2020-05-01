class GoodTransfersController < ApplicationController
  skip_before_filter :verify_authenticity_token, only: [:destroy]
  autocomplete :good_transfer, :code
  before_filter :get_last_data, only: [:new, :create]
  before_filter :can_view_product_mutation, only: [:index, :show]
  before_filter :can_manage_product_mutation, only: [:new, :create]

  def add_product
    @product = Product.find(params[:id])
    @supplier = @product.brand.supplier
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue params[:branch_id])} AND products.id=#{@product.id}").joins(product_size: [:product])
      .sort_by{|pd|(pd.product_size.size_detail.size_number.to_i rescue 9999999)}
    respond_to do |format|
      format.js
    end
  end

  def print_to_pdf
    @product_mutation = ProductMutation.find params[:id]
    #tables = [['BARCODE', 'DESCRIPTION', 'QUANTITY']]
    html = render_to_string(:layout => "pdf_layout.html")
    pdf = WickedPdf.new.pdf_from_string(html, :orientation => 'Landscape')
    send_data(pdf,
      :filename    => "PM-#{@product_mutation.code}.pdf",
      :disposition => 'attachment'
    )
    # @product_mutation.product_mutation_details.each{|pmd|
    #   product = pmd.product
    #   tables << [
    #     product.barcode, product.description, pmd.quantity
    #   ]
    # }
    # Prawn::Document.generate("#{Rails.root.to_s}/public/ActiveLicense.pdf") do |pdf|
    #   pdf.text "<b>MUTASI BARANG</b>", :style => :normal, :inline_format => true, :align => :center
    #   pdf.move_down(7)
    #   pdf.text "Transfer Date            : #{@product_mutation.mutation_date.strftime('%d-%m-%Y')}", :style => :normal, :inline_format => true
    #   pdf.move_down(7)
    #   pdf.text "No. Transfer Barang  : #{@product_mutation.code}", :style => :normal, :inline_format => true
    #   pdf.move_down(7)
    #   pdf.text "Dari                           : #{@product_mutation.origin_warehouse.office_name}", :style => :normal, :inline_format => true
    #   pdf.move_down(7)
    #   pdf.text "Tujuan                       : #{@product_mutation.destination_warehouse.office_name}", :style => :normal, :inline_format => true
    #   pdf.text "\n"
    #   pdf.table tables
    #   pdf.text "\n"
    #   send_data pdf.render, :type => "application/pdf", :filename => "Product Mutation #{@product_mutation.code}.pdf"
    # end
  end

  # GET /good_transfers
  # GET /good_transfers.json
  def index
    get_paginated_good_transfers
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
    @good_transfer = GoodTransfer.find(params[:id])
    load_auto
    @list_product = ProductDetail.where("warehouse_id=#{(current_user.branch.id rescue Branch.first.id)}").group_by{:product_id}
    @product_mutation_details = @good_transfer.product_mutation_details
  end

  def new
    time_now = Time.now
    @suppliers = Supplier.limit(7)

    @good_transfer = GoodTransfer.new(code: "TI#{Time.now.year}#{sprintf('%06d', (GoodTransfer.last.id rescue 0)+1)}")

    load_auto
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /good_transfers/1/edit
  def edit
    @good_transfer = GoodTransfer.find(params[:id])
    @supplier = @good_transfer.supplier
    @list_product = ProductDetail.where("warehouse_id=#{@good_transfer.origin_warehouse_id}").group_by{:product_id}
    load_auto
    respond_to do |format|
      format.html
    end
  end

  # POST /good_transfers
  # POST /good_transfers.json
  def create
    @good_transfer = GoodTransfer.new(good_transfer_params.merge(mutation_date: Time.now, sender_id: current_user.id, status: ProductMutation::PENDING))
    respond_to do |format|
      if @good_transfer.save
        flash[:notice] = 'Transfer was successfully created'
      else
        @products = Product.select("barcode, barcode").limit(11).order("barcode").map{|product|[product.barcode, product.barcode]}
        flash[:error] = @good_transfer.errors.full_messages.join('<br/>')
      end
      format.js
    end
  end

  # PUT /good_transfers/1
  # PUT /good_transfers/1.json
  def update
    @good_transfer = GoodTransfer.find(params[:id])
    old_details = @good_transfer.product_mutation_details.map(&:id)
    if @good_transfer.is_pending? && @good_transfer.update_attributes(good_transfer_params)
      ProductMutationDetail.where(id: old_details).each{|pmd|
        product_detail = ProductDetail.find_by_warehouse_id_and_product_size_id(@good_transfer.origin_warehouse_id, pmd.product_size_id)
        product_detail.update_attributes(available_qty: product_detail.available_qty.to_i+pmd.quantity)
        ProductMutationHistory.find_by_product_detail_id_and_product_mutation_detail_id(product_detail.id, pmd.id).delete rescue nil
      }
      flash[:notice] = 'Transfer was successfully updated.'
      respond_to do |format|
        format.js
      end
    else
      @list_product = ProductDetail.where("warehouse_id=#{@good_transfer.origin_warehouse_id}").joins(product_size: [:product]).group_by{|pd|pd.product_size.product_id}
      flash[:error] = @good_transfer.errors.full_messages
      # format.js
      render "edit"
    end
  end

  def destroy
    @good_transfer = GoodTransfer.find(params[:id])
    if @good_transfer.is_pending? && @good_transfer.destroy
      get_paginated_good_transfers
    else
      flash[:error] = t(:data_already_in_used)
    end
    respond_to do |format|
      format.js
    end
  end

  def search
    @good_transfers = GoodTransfer.search(params[:search]).uniq.paginate(:page => params[:page], :per_page => 10) || []
    respond_to do |format|
      @good_transfer = GoodTransfer.new
      format.js
    end
  end

  def get_number
    @good_transfer_number = GoodTransfer.number(params)
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

  def import
    @product = []
    case params["0"].content_type
    when "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet" # xlsx
      sheet = RubyXL::Parser.parse(params["0"].tempfile)[0]
      sheet.each_with_index do |row, i|
        next if i == 0 or (row[3].value.to_s rescue '').blank?
        @product << [row[2].value.to_i, # qty
                     row[3].value.to_s.gsub(".0", '')] # barcode
      end
    when "application/vnd.ms-excel"
      sheet = Spreadsheet.open(params["0"].tempfile).worksheet(0)
      sheet.each_with_index do |row, i|
        next if i == 0 or row[3].to_s == ""
        @product << [(row[2].value.to_i rescue row[2].to_i), # qty
                     row[3].to_s.gsub(".0", '')] # barcode
      end
    end

    respond_to do |format|
      format.js
    end
  end

  def get_last_data
    @last_goods_transfer = GoodTransfer.last
  end

  def load_auto
    @offices = current_user.offices
    @products = Product.select("barcode, barcode").limit(11).order("barcode").map{|product|[product.barcode, product.barcode]}
  end

  def add_brand
    @product = Product.find_by_id(params[:product_id])
    @product_details = ProductDetail.where("warehouse_id=#{params[:warehouse_id]} AND products.id=#{params[:product_id]}").joins(product_size: [:product, :size_detail])
      .order("size_number")
    @good_transfer = GoodTransfer.find_by_id(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def get_product
    @product = Product.find_by_barcode(params[:barcode])
    @list_product = ProductDetail.where("warehouse_id=#{(params[:origin_warehouse_id])} AND product_id=#{@product.id}").sort_by{|pd|
      pd.product_size.size_detail.size_number.to_i rescue '99999999999999'
    }
    @list_product_in_branch = ProductDetail.where("warehouse_id=#{(params[:destination_warehouse_id])} AND products.id=#{@product.id}").joins(product_size: [:product])
    @supplier = @product.brand.supplier
    respond_to do |format|
      format.js
    end
  end

  def get_last_number
    render json: {
      number: (('%07d' % (((GoodTransfer.where("supplier_id=#{params[:supplier_id]} AND extract(YEAR FROM mutation_date)=#{Time.now.year}").order("id DESC").limit(1)[0].code.last.to_i rescue 0) +1))))
    }
  end

  def get_template
    book = Spreadsheet::Workbook.new

    title = ['NO', 'NAMA ITEM', 'QTY/ EA', 'BARCODE']
    sheet = book.create_worksheet
    sheet.row(0).push *title

    f_top = Spreadsheet::Format.new
    f_top.top = :medium
    f_top.bottom = :medium
    f_top.left = :medium
    f_top.right = :medium

    f_mid = Spreadsheet::Format.new
    f_mid.top = :none
    f_mid.bottom = :none
    f_mid.left = :medium
    f_mid.right = :medium

    f_bottom = Spreadsheet::Format.new
    f_bottom.top = :none
    f_bottom.bottom = :medium
    f_bottom.left = :medium
    f_bottom.right = :medium

    widths = []
    title.each_with_index do |str, i|
      widths << str.length
    end

    @product_details = ProductDetail.where("available_qty > 0 AND warehouse_id = #{params[:from]}")
    @product_details.each_with_index do |pd, i|
      next if pd.product.blank?
      data = [i + 1, pd.product.description, nil, pd.product.barcode]
      sheet.row(i + 1).push *data

      widths.each_with_index do |width, j|
        widths[j] = [width, data[j].to_s.length].max
        sheet.row(i + 1).set_format(j, f_mid)
      end
    end

    widths.each_with_index do |width, i|
      sheet.column(i).width = width + 5
      sheet.row(0).set_format(i, f_top)
      sheet.row(@product_details.count).set_format(i, f_bottom)
    end

    out = StringIO.new
    book.write out
    out.rewind

    send_data out.string, :filename => "TEMPLATE_TAT_#{Office.find(params[:from]).office_name rescue ""}.xls", :type =>  "application/vnd.ms-excel"
  end

private
  def get_paginated_good_transfers
    conditions = []
    conditions = ["origin_warehouse_id=#{current_user.branch_id}"] if current_user.branch_id.present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')"
    } if params[:search].present?
    @good_transfers = GoodTransfer.where(conditions.join(' AND ')).order(default_order('product_mutations'))
      .joins("INNER JOIN offices origin ON origin.id=origin_warehouse_id INNER JOIN offices destination ON destination.id=destination_warehouse_id
        LEFT JOIN users sender ON sender.id=sender_id")
      .select("origin.office_name AS origin_name, destination.office_name AS destination_name, to_char(mutation_date, 'DD-MM-YYYY') AS mutation_date, product_mutations.code,
        product_mutations.id, CONCAT(sender.first_name, ' ', sender.last_name) AS sender_name, no_surat_jalan, product_mutations.status")
      .paginate(:page => params[:page], :per_page => PER_PAGE) || []
  end

  def good_transfer_params
    params.require(:good_transfer).permit(
      :code, :origin_warehouse_id, :destination_warehouse_id, :status, :no_surat_jalan, :supplier_id, product_mutation_details_attributes: [:quantity, :product_id, :_destroy]
    )
  end

  def can_view_product_mutation
    not_authorized unless current_user.can_view_goods_transfer?
  end

  def can_manage_product_mutation
    not_authorized unless current_user.can_manage_product_mutation?
  end
end
