class ReportsController < ApplicationController

  def stock_group_by_store_per_month
    conditions = ["year=#{params[:year]} AND month=#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}"]
    conditions << "LOWER(office_name) LIKE LOWER('%#{params[:office_name]}%')" if params[:office_name].present?
    conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:store_code]}%')" if params[:store_code].present?
    @product_mutations = MonthlySalesInventory.where(conditions.join(' AND ')).order('start_amount DESC').joins(:office).select("offices.id, code, office_name, SUM(start_amount) AS start_amount, SUM(start_qty) AS start_qty, SUM(sales_amount) AS sales_amount, SUM(sales_qty) AS sales_qty, SUM(retur_sales_amount) AS retur_sales_amount, SUM(retur_sales_qty) AS retur_sales_qty, SUM(gr_amount) AS gr_amount, SUM(gr_qty) AS gr_qty, SUM(tat_in_amount) AS tat_in_amount, SUM(tat_in_qty) AS tat_in_qty, SUM(tat_out_amount) AS tat_out_amount, SUM(tat_out_qty) AS tat_out_qty, SUM(retur_amount) AS retur_amount, SUM(retur_qty) AS retur_qty, SUM(so_amount) AS so_amount, SUM(so_qty) AS so_qty, SUM(end_qty) AS end_qty, SUM(end_amount) AS end_amount, SUM(last_cost) AS last_cost").group("offices.id, code, office_name")
#    raise @product_mutations_ungrouped.inspect
  end

  def stock_group_by_item_per_month
    conditions = ["year=#{params[:year]} AND month=#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}"]
    conditions << "LOWER(products.article) LIKE LOWER('%#{params[:article]}%')" if params[:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:store_code]}%')" if params[:store_code].present?
    @product_mutations = MonthlySalesInventory.where(conditions.join(' AND ')).order('start_amount DESC').joins(:product, :office).group("products.id, article, products.description")
      .select("products.id, article, products.description, SUM(start_amount) AS start_amount, SUM(start_qty) AS start_qty, SUM(sales_amount) AS sales_amount, SUM(sales_qty) AS sales_qty,
        SUM(retur_sales_amount) AS retur_sales_amount, SUM(retur_sales_qty) AS retur_sales_qty, SUM(gr_amount) AS gr_amount, SUM(gr_qty) AS gr_qty, SUM(tat_in_amount) AS tat_in_amount,
        SUM(tat_in_qty) AS tat_in_qty, SUM(tat_out_amount) AS tat_out_amount, SUM(tat_out_qty) AS tat_out_qty, SUM(retur_amount) AS retur_amount, SUM(retur_qty) AS retur_qty, SUM(so_amount) AS so_amount,
        SUM(so_qty) AS so_qty, SUM(end_qty) AS end_qty, SUM(end_amount) AS end_amount, SUM(last_cost) AS last_cost")
  end

  def monthly_stock
    if params[:all_stores].present?
      conditions = []
      if params[:all_stores] == 'Store'
        stock_group_by_store_per_month
      elsif params[:all_stores] == 'Item'
        stock_group_by_item_per_month
        @first_sale = Sale.where("to_char(transaction_date, 'YYYY-MM')='#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}'").limit(1).first
      end

      respond_to do |format|
        format.html
        format.xls { send_data stock_xls, :filename => "REPORT_STOCK_#{Office.where(:code => params[:store_code]).first.office_name rescue "ALL"}.xls", :type =>  "application/vnd.ms-excel" }
        format.js
      end
    else
      flash[:error] = "Please Choose Group By" if params[:format] == 'xls'
      respond_to do |format|
        format.html
        format.xls {redirect_to '/reports/stock'}
      end
    end
  end

  def brd
    conditions = []
    conditions = ["origin_warehouse_id=#{current_user.branch_id}"] if current_user.branch_id.present?
    conditions << "mutation_date>='#{params[:start_date]} 00:00:00'" if params[:start_date].present?
    conditions << "mutation_date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @details = ProductMutationDetail.where(conditions.join(' AND ')).order(default_order('product_mutations'))
      .joins("INNER JOIN product_mutations ON product_mutations.id=product_mutation_details.product_mutation_id AND product_mutations.type='GoodTransfer'
        INNER JOIN offices origin ON origin.id=origin_warehouse_id INNER JOIN offices destination ON destination.id=destination_warehouse_id LEFT JOIN users sender ON sender.id=sender_id
        INNER JOIN products ON products.id=product_mutation_details.product_id")
      .select("origin.office_name AS origin_name, destination.office_name AS destination_name, to_char(mutation_date, 'DD-MM-YYYY') AS mutation_date, product_mutations.code,
        product_mutations.id, CONCAT(sender.first_name, ' ', sender.last_name) AS sender_name, no_surat_jalan, product_mutations.status, article, products.description, quantity, product_mutation_details.created_at, product_id, received_date, received_qty")
      .paginate(:page => params[:page], :per_page => PER_PAGE) || []

    respond_to do |format|
      format.html
      format.js
      format.xls do
        send_data brd_xls, :filename => "REPORT_BRD.xls", :type =>  "application/vnd.ms-excel"
      end
    end
  end

  def brd_xls
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet(name: 'BRD')

    conditions = []
    conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?
    conditions << "mutation_date>='#{params[:start_date]} 00:00:00'" if params[:start_date].present?
    conditions << "mutation_date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    conditions << "to_char(mutation_date, 'YYYY-MM-DD')='#{params[:transaction_date]}'" if params[:transaction_date].present?

    header = ['No', 'Article', 'Descrition', 'Store', 'TI Number', 'TI Date', 'Qty', 'HPP', 'Amount', 'Store', 'TI Number', 'TI Date', 'Qty', 'HPP', 'Amount','Qty','Amount']

    recon = ProductMutationDetail.where(conditions.join(' AND ')).order(default_order('product_mutations'))
          .joins("INNER JOIN product_mutations ON product_mutations.id=product_mutation_details.product_mutation_id AND product_mutations.type='GoodTransfer'
            INNER JOIN offices origin ON origin.id=origin_warehouse_id INNER JOIN offices destination ON destination.id=destination_warehouse_id LEFT JOIN users sender ON sender.id=sender_id
            INNER JOIN products ON products.id=product_mutation_details.product_id")
          .select("origin.office_name AS origin_name, destination.office_name AS destination_name, to_char(mutation_date, 'DD-MM-YYYY') AS mutation_date, product_mutations.code,
            product_mutations.id, CONCAT(sender.first_name, ' ', sender.last_name) AS sender_name, no_surat_jalan, product_mutations.status, article, products.description, quantity, product_mutation_details.created_at, product_id, received_date, received_qty")

    sheet.row(1).insert 1, 'Location :'
    sheet.row(1).insert 2, Office.first.office_name

    sheet.row(2).insert 1, 'Periode :'
    sheet.row(2).insert 2, "#{Date.today.beginning_of_month} - #{Date.today.end_of_month}"
    sheet.row(3).insert 3, 'Transfer Issue'
    sheet.row(3).insert 9, 'Transfer Receipt'
    sheet.merge_cells(3, 3, 3, 8)
    sheet.merge_cells(3, 9, 3, 14)
    sheet.row(3).insert 15, 'Selisih'
    sheet.merge_cells(3,15,3,16)

    sheet.row(4).push *header

    recon.each_with_index do |brd, i|
      data = []
      data << i+1
      data << brd.article
      data << brd.description
      data << brd.origin_name
      data << brd.code
      data << brd.mutation_date
      data << brd.quantity
      data << brd.hpp
      data << (brd.quantity.to_f*brd.hpp.to_f)
      data << brd.destination_name
      data << brd.code
      data << brd.received_date
      data << brd.received_qty
      data << brd.hpp
      data << (brd.received_qty.to_f*brd.hpp.to_f)
      data << (brd.quantity - brd.received_qty rescue brd.quantity)
      data << (brd.quantity.to_f*brd.hpp.to_f) - (brd.received_qty.to_f*brd.hpp.to_f)

      # Push
      sheet.row(5+i).push *data
    end

    # (0..data.length-1).each do |i|
    #   sheet.column(i).width = widths[i] + 5
    #   sheet.row(sales.length + 1).set_format(i, f_all)
    # end

    out = StringIO.new
    book.write out
    out.rewind

    return out.string
  end

  def pl_xls_sheet(book, category)
    conditions = []
    title = ["PROFIT & LOST REPORT"]
    subtitle = [Branch.find(params[:branch_id]).office_name]
    sheet = book.create_worksheet(:name => category)
    period = params[:period].to_date rescue Time.now.beginning_of_month
    prev_period = params[:prev_period].to_date rescue (Time.now-1.month).end_of_month

    sheet.row(0).push *title
    sheet.row(1).push *subtitle
    sheet.row(2).push *[period.strftime('%B %d, %Y')]
    sheet.row(3).push *[]
    sheet.row(4).push *['', "YTD 2016", (period-1.month).end_of_month.strftime('%B'), '%', period.end_of_month.strftime('%B'), '%']
    sheet.row(5).push *['Net Sales']
    sheet.row(6).push *['Sales']
    sheet.row(7).push *['HPP']
    sheet.row(8).push *['Gross Margin']
    sheet.row(9).push *['EXPENSES']
    num = 10
    ## disini terjadi bug, karena tidak diketahui jenis pengeluaran ada berapa, sehingga perhitungan rownya jadi ngaco
    CashOut.where("created_at BETWEEN '#{params[:start_date]} 00:00:00' AND '#{params[:end_date]} 23:59:59' AND cash_out_type!='CASH IN'").each_with_index do |co|
      sheet.row(num+i).push *[co.description, format_currency(co.amount)]
    end


    sheet.row(10).push *['Penjualan Bersih', SalesDetail.where("to_char(transaction_date, 'YYYY')='#{period.strftime('%Y')}'").joins(:sale).sum(:total_price)]
    sheet.row(11).push *[SalesDetail.where("to_char(transaction_date, 'YYYY-MM')='#{prev_period.strftime('%Y-%m')}'").joins(:sale).sum(:total_price)]
    sheet.row(12).push *[SalesDetail.where("to_char(transaction_date, 'YYYY-MM')='#{period.strftime('%Y-%m')}'").joins(:sale).sum(:total_price)]

    f_all = Spreadsheet::Format.new
    f_all.top = :none
    f_all.bottom = :none
    f_all.left = :none
    f_all.right = :none

    f_mid = Spreadsheet::Format.new
    f_mid.top = :none
    f_mid.bottom = :none
    f_mid.left = :none
    f_mid.right = :none

    widths = []
    title.each_with_index do |str, i|
      # merge empty cell
      sheet.merge_cells(0, i - 1, 0, i) if str == ''
      sheet.merge_cells(0, i, 1, i) if subtitle[i] == ''

      widths << subtitle[i].length
      sheet.row(0).set_format(i, f_all)
      sheet.row(1).set_format(i, f_all)
    end

    total_awal_qty = 0
    total_awal_price = 0
    total_sales_qty = 0
    total_sales_price = 0
    total_sales_ppn = 0
    total_receiving_qty = 0
    total_receiving_price = 0
    total_receiving_ppn = 0
    total_gtr_qty = 0
    total_gtr_price = 0
    total_gtr_ppn = 0
    total_gt_qty = 0
    total_gt_price = 0
    total_gt_ppn = 0
    total_akhir_qty = 0
    total_akhir_price = 0

  end

  def pl_xls
    book = Spreadsheet::Workbook.new
    pl_xls_sheet(book, 'Item')

    out = StringIO.new
    book.write out
    out.rewind

    return out.string
  end

  def pl
    ###Parameter
    params[:start_date] = Time.now.strftime('%Y-%m-01') if params[:start_date].blank?
    params[:end_date] = Time.now.end_of_month.strftime('%Y-%m-%d') if params[:end_date].blank?
    params[:branch_id] = Branch.first.id if params[:branch_id].blank?
    params[:period] = Date.today.beginning_of_month.to_date if params[:period].blank?
    params[:prev_period] = params[:period].to_date-1.month if params[:prev_period].blank?
    period = params[:period].to_date
    prev_period = params[:prev_period].to_date

    @cash_outs = CashOut.where("created_at BETWEEN '#{params[:start_date]} 00:00:00' AND '#{params[:end_date]} 23:59:59' AND cash_out_type!='CASH IN'")

    @cash_outs_ytd = CashOut.where("created_at BETWEEN '#{prev_period.beginning_of_month} 00:00:00' AND '#{period.end_of_month} 23:59:59' AND cash_out_type!='CASH IN'")
    @cash_outs_prev_period = CashOut.where("created_at BETWEEN '#{prev_period.beginning_of_month} 00:00:00' AND '#{prev_period.end_of_month} 23:59:59' AND cash_out_type!='CASH IN'")
    @cash_outs_period = CashOut.where("created_at BETWEEN '#{period.beginning_of_month} 00:00:00' AND '#{period.end_of_month} 23:59:59' AND cash_out_type!='CASH IN'")

    @cash_ins = CashOut.where("created_at BETWEEN '#{params[:start_date]} 00:00:00' AND '#{params[:end_date]} 23:59:59' AND cash_out_type='CASH IN'")

    @cash_ins_ytd = CashOut.where("created_at BETWEEN '#{prev_period.beginning_of_month} 00:00:00' AND '#{period.end_of_month} 23:59:59' AND cash_out_type='CASH IN'")
    @cash_ins_prev_period = CashOut.where("created_at BETWEEN '#{prev_period.beginning_of_month} 00:00:00' AND '#{prev_period.end_of_month} 23:59:59' AND cash_out_type='CASH IN'")
    @cash_ins_period = CashOut.where("created_at BETWEEN '#{period.beginning_of_month} 00:00:00' AND '#{period.end_of_month} 23:59:59' AND cash_out_type='CASH IN'")

    @sales_details = SalesDetail.joins(:sale).where("transaction_date BETWEEN '#{params[:start_date]} 00:00:00' AND '#{params[:end_date]} 23:59:59' AND store_id = #{params[:branch_id]}")

    @sales_details_ytd = SalesDetail.joins(:sale).where("transaction_date BETWEEN '#{prev_period.beginning_of_month} 00:00:00' AND '#{period.end_of_month} 23:59:59' AND store_id = #{params[:branch_id]}")
    @sales_details_prev_period = SalesDetail.joins(:sale).where("transaction_date BETWEEN '#{prev_period.beginning_of_month} 00:00:00' AND '#{prev_period.end_of_month} 23:59:59' AND store_id = #{params[:branch_id]}")
    @sales_details_period = SalesDetail.joins(:sale).where("transaction_date BETWEEN '#{period.beginning_of_month} 00:00:00' AND '#{period.end_of_month} 23:59:59' AND store_id = #{params[:branch_id]}")

    filename = "Profit/Lost_#{params[:start_date]}_to_#{params[:end_date]}.xls"

    #if params[:format] == 'xls'
    #  book = Spreadsheet::Workbook.new
    #  pl_xls_sheet(book, 'Item')
    #end
    respond_to do |format|
      format.html
      format.js
      format.xls #{ send_data pl_xls, :filename => "REPORT_SALE_#{Office.where(:code => params[:store_code]).first.office_name rescue "ALL"}.xls", :type =>  "application/vnd.ms-excel" }
      format.pdf do
        render pdf: 'profit_lost',
        :template => 'reports/pl.pdf.erb',
        :print_media_type => true,
        :page_size => "A4",
        :disable_smart_shrinking => true,
        :footer => {
          :center => "Profit & Lost Reports",
          :right => "Lottemart Wholesale"
        }
      end
    end
  end

  def store
    conditions = []
    params[:search].each{|param|
        next if param[1] == ""
    conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    # conditions << "r.number not null"
    @stores = Branch.select("code AS kode_toko, office_name AS nama_toko,
              address AS alamat_toko, phone_number AS telepon,
              (SELECT number FROM receivings WHERE head_office_id=offices.id ORDER BY id DESC LIMIT 1) AS no_barang_terima,
              (SELECT number FROM returns_to_suppliers WHERE head_office_id=offices.id ORDER BY id DESC LIMIT 1) AS no_barang_kembali,
              (SELECT opname_number FROM stock_opnames WHERE office_id=offices.id ORDER BY id DESC LIMIT 1) AS no_stok_opname,
              npwp")
              .joins("LEFT JOIN receivings AS r ON r.head_office_id=r.id")
              .joins("LEFT JOIN returns_to_suppliers AS rs ON rs.head_office_id=offices.id")
              .joins("LEFT JOIN stock_opnames AS opname ON opname.office_id=office_id")
              .where(conditions.join(' AND '))
              .paginate(:page => params[:page], :per_page => 2) || []
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def supplier
    conditions = []
    params[:search].each{|param|
    conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @product_suppliers = ProductSupplier.where(conditions.join(' AND ')).joins(:supplier, :product).paginate(:page => params[:page], :per_page => 10) || []
    @product_suppliers2 = ProductSupplier.where(conditions.join(' AND ')).joins(:supplier, :product) || []
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def eod
  end

  def product
    conditions = []
    params[:search].each{|param|
      next if param[1] == ""
    conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    @selling_price = SellingPrice.where(conditions.join(' AND ')).joins("INNER JOIN products ON products.id=selling_prices.product_id").paginate(:page => params[:page], :per_page => 10) || []
    # raise params.inspect
    respond_to do |format|
      format.html do
        # @selling_price = SellingPrice.where(conditions.join(' AND ')).joins("INNER JOIN products ON products.id=selling_prices.product_id").paginate(:page => params[:page], :per_page => 10) || []
      end
      format.js
      format.xls do
        @product = Product.all
      end
    end
  end

  def receiving
    @branches = Branch.all
    @receivings = Receiving.all
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def return_all_branch
    @branches = Branch.all
    @returns_to_hos = ReturnsToHo.all.group_by{|rth|rth.origin_warehouse_id}
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def stock_group_by_store
    conditions = []
    end_day = (Time.now.month == Date::MONTHNAMES.index(params[:month]) ? Time.now.day-1 : "#{params[:year]}-#{params[:month]}-01".to_date.end_of_month.day)
    params[:start_date] = "#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}-01"
    params[:end_date] = "#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}-#{end_day}"
    conditions << "daily_sales_inventories.date>='#{params[:start_date]}'" if params[:start_date].present?
    conditions << "daily_sales_inventories.date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    conditions << "LOWER(office_name) LIKE LOWER('%#{params[:office_name]}%')" if params[:office_name].present?
    conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:store_code]}%')" if params[:store_code].present?
    @product_mutations_ungrouped = DailySalesInventory.where(conditions.join(' AND ')).order('start_amount DESC').joins(:office)
    @start_stock = @product_mutations_ungrouped.where("date='#{params[:start_date]}'").group_by{|pmh|pmh.office_id}
    @end_stocks = @product_mutations_ungrouped.where("date='#{params[:end_date]}'")
    @end_stock = @product_mutations_ungrouped.where("date='#{params[:end_date]}'").group_by{|pmh|pmh.office_id}
    @product_mutations = @product_mutations_ungrouped.group_by{|pmh|pmh.office_id}
  end

  def stock
    if params[:all_stores].present?
      conditions = []
      if params[:all_stores] == 'Date'
        stock_group_by_date
      elsif params[:all_stores] == 'Store'
        stock_group_by_store
      elsif params[:all_stores] == 'Item'
        stock_group_by_item
        @first_sale = Sale.where("to_char(transaction_date, 'YYYY-MM')='#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}'").limit(1).first
      elsif params[:all_stores] == 'Month'
        @product_mutation_histories = @product_mutations.group_by{|pmh|pmh.created_at.strftime('%Y-%m-%d')}
      else
        conditions << "to_char(product_mutation_histories.created_at, 'YYYY-MM-DD')='#{params[:transaction_date]}'" if params[:transaction_date].present?
        conditions << "product_mutation_histories.created_at>='#{params[:start_date]}'" if params[:start_date].present?
        conditions << "product_mutation_histories.created_at<='#{params[:end_date]}'" if params[:end_date].present?
        conditions << "LOWER(office_name) LIKE LOWER('%#{params[:office_name]}%')" if params[:office_name].present?
        conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:store_code]}%')" if params[:store_code].present?
        conditions << "LOWER(products.article) LIKE LOWER('%#{params[:product_code]}%')" if params[:product_code].present?
        conditions << "LOWER(products.description) LIKE LOWER('%#{params[:product_name]}%')" if params[:product_name].present?
        conditions << "LOWER(to_char(product_mutation_histories.created_at, 'YYYY-MM-DD')) LIKE LOWER('%#{params[:date]}%')" if params[:date].present?
        conditions << "offices.id='#{current_user.branch_id}'" if current_user.branch_id.present?
        @product_mutations = ProductMutationHistory.joins(product_detail: [:warehouse, :product]).where(conditions.join(' AND ')).order('created_at')
        get_product_mutation_histories(params[:all_stores]) if params[:all_stores].present?
      end

      respond_to do |format|
        format.html
        format.xls { send_data stock_xls, :filename => "REPORT_STOCK_#{Office.where(:code => params[:store_code]).first.office_name rescue "ALL"}.xls", :type =>  "application/vnd.ms-excel" }
        format.js
      end
    else
      flash[:error] = "Please Choose Group By" if params[:format] == 'xls'
      respond_to do |format|
        format.html
        format.xls {redirect_to '/reports/stock'}
      end
    end
  end

  def sales_report
    @sales = SalesDetail.joins(:product).joins(sale: [:session, :store]).order('created_at')
    respond_to do |format|
      format.xls
      end
  end

  def bpb_report
    @sales = ReceivingDetail.joins(:product).joins(receiving: :supplier).joins(receiving: :head_office).order('created_at')
    respond_to do |format|
      format.xls
      end
  end

  def rekap_report
    @sales = SalesDetail.joins(:product).joins(sale: [:session, :store]).order('created_at')
    respond_to do |format|
      format.xls
      end
  end

  def planogram
    conditions = []
    conditions << "branch_id = #{params[:all_store]}" if params[:all_store].present?

    @planogram = Planogram.select("
      products.article AS article, products.description AS product_name,m_classes.name AS category,
      product_details.min_stock AS min_stock, product_details.rop_stock AS rop_stock,
      product_details.max_stock AS max_stock, planos.shelving AS shelving, planos.kir_ka AS left_right,
      planos.at_ba AS up_down, planos.de_be AS front_back, planos.min AS min_display, planograms.rack_number AS rack_number
      ").
    where(conditions.join(' AND ')).
    joins("INNER JOIN planograms_stores ON planograms_stores.planogram_id = planograms.id").
    joins("INNER JOIN planos ON planos.rak_id = planograms.id").
    joins("INNER JOIN products ON planos.product_id = products.id").
    joins("INNER JOIN product_details ON product_details.product_id = products.id").
    joins("INNER JOIN m_classes ON products.department_id = m_classes.id").
    paginate(:page => params[:page], :per_page => 10) || []

    respond_to do |format|
      format.html
      format.xls #{ send_data stock_xls, :filename => "REPORT_STOCK_#{Office.where(:code => params[:store_code]).first.office_name rescue "ALL"}.xls", :type =>  "application/vnd.ms-excel" }
      format.js
    end
  end

  def pb
    conditions = []
    if params[:start_date].blank?
      params[:start_date] = Time.now.beginning_of_month.strftime('%Y-%m-%d')
      params[:end_date] = Time.now.end_of_month.strftime('%Y-%m-%d')
    end
    conditions << "product_mutation_histories.created_at BETWEEN '#{params[:start_date]}' AND '#{params[:end_date]}'"
    conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?

    @product_mutations = ProductMutationHistory.joins(product_detail: :warehouse).where(conditions.join(' AND ')).order('created_at')
    get_product_mutation_histories(params[:all_stores]) if params[:all_stores].present?

    respond_to do |format|
      format.html
      format.xls { send_data stock_xls, :filename => "REPORT_STOCK_#{Office.where(:code => params[:store_code]).first.office_name rescue "ALL"}.xls", :type =>  "application/vnd.ms-excel" }
      format.js
    end
  end

  def sale
    conditions = []
    conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?
    conditions << "to_char(transaction_date, 'YYYY-MM-DD')='#{params[:transaction_date]}'" if params[:transaction_date].present?
    conditions << "transaction_date>='#{params[:start_date]} 00:00:00'" if params[:start_date].present?
    conditions << "transaction_date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    conditions << "quantity>0" if params[:search].present? && params[:all_stores] != 'Date'
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    if params[:all_stores] == 'Store'
      @sales = Sale.select("offices.code AS kode_toko, office_name, SUM(sales_details.total_price)+SUM(sales_details.claim_amt) AS total_price, SUM(sales_details.quantity) AS total_quantity, SUM(ppn) AS total_ppn,
        SUM(capital_price*quantity) AS capital_price, sum(claim_amt) AS total_claim").joins(:store, :sales_details).group("offices.code, office_name").where(conditions.join(' AND ')).order("total_price DESC")
    elsif params[:all_stores] == 'Item'
      @sales = SalesDetail.select("DISTINCT ON (product_suppliers.product_id) article, products.description, SUM(sales_details.total_price) AS total_price, SUM(sales_details.ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
        SUM(quantity) AS quantity, suppliers.name AS supplier_name").joins(product: :product_suppliers, sale: :store).joins("INNER JOIN suppliers ON suppliers.id = product_suppliers.supplier_id").group("article, products.description, supplier_name, product_suppliers.product_id").where(conditions.join(' AND '))
      #@sales = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
      #  SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("total_price DESC")
    elsif params[:all_stores] == 'Category'
      conditions << "LOWER(name) LIKE LOWER('%#{params[:m_class_name]}%')" if params[:m_class_name].present?
      @sales = SalesDetail.select("m_class_id, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
        SUM(quantity) AS quantity").joins(:product, sale: :store).group("m_class_id").where(conditions.join(' AND ')).order("total_price DESC")
    elsif params[:all_stores] == 'Member'
      @sales = SalesDetail
        .select("member_id, members.name AS member_name, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price, SUM(quantity) AS quantity")
        .joins(:product, sale: [:store, :member]).group("member_id, members.name").where(conditions.join(' AND ')).order("total_price DESC").paginate(:page => params[:page], :per_page => 10) || []
    elsif params[:all_stores] == 'Date'
      @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, (SUM(sales_details.total_price)) AS total_price, SUM(ppn) AS total_ppn,
          SUM(capital_price*quantity) AS capital_price, SUM(claim_amt) AS total_claim").joins(
            :store, :sales_details
          ).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
          .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
      @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(sales_details.ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
        SUM(quantity) AS quantity, suppliers.name AS supplier_name").joins(product: :product_suppliers, sale: :store).joins("INNER JOIN suppliers ON suppliers.id = product_suppliers.supplier_id").group("article, products.description, supplier_name").where(conditions.join(' AND ')).order("total_price DESC")
      # @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
      #   SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
    elsif params[:all_stores] == 'Hour'
      @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
        SUM(capital_price*quantity) AS capital_price, SUM(claim_amt) AS total_claim").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
        .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
      @sales_per_hour = Sale.select("to_char(transaction_date, 'HH24 YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
        SUM(capital_price*quantity) AS capital_price, SUM(claim_amt) AS total_claim").joins(:store, :sales_details).group("to_char(transaction_date, 'HH24 YYYY-MM-DD')").where(conditions.join(' AND '))
        .order("to_char(transaction_date, 'HH24 YYYY-MM-DD') ASC")
      @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(sales_details.ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
        SUM(quantity) AS quantity, suppliers.name AS supplier_name").joins(product: :product_suppliers, sale: :store).joins("INNER JOIN suppliers ON suppliers.id = product_suppliers.supplier_id").group("article, products.description, supplier_name").where(conditions.join(' AND ')).order("total_price DESC")
      # @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
        # SUM(quantity) AS quantity, SUM(claim_amt) AS total_claim").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")

    elsif params[:all_stores] == 'Month'
      @condition = conditions
      @month = params[:months]
      month_report
    end
    tgl_xls = ""
    tgl_xls << "_FROM_" + params[:start_date] if params[:start_date].present?
    tgl_xls << "_UNTIL_" + params[:end_date] if params[:end_date].present?
    respond_to do |format|
      format.html
      format.js
      format.xls { send_data sale_xls, :filename => "REPORT_SALE_#{Office.where(:code => params[:store_code]).first.office_name rescue "ALL"}" + tgl_xls +".xls", :type =>  "application/vnd.ms-excel" }
    end
  end

  def sales_online
    conditions = []
    conditions << "branch_id = #{current_user.branch_id}" if current_user.branch_id.present?
    conditions << "LOWER(offices.office_name) LIKE LOWER('%#{params[:kode_toko]}%')" if params[:kode_toko].present?
    conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?
    conditions << "LOWER(tipe) LIKE LOWER('%#{params[:tipe]}%')" if params[:tipe].present?
    conditions << "idpel = '#{params[:idpel]}'" if params[:idpel].present?
    conditions << "to_char(pay_date, 'YYYY-MM-DD') = '#{params[:pay_date]}'" if params[:pay_date].present?
    conditions << "sales.transaction_date>='#{params[:start_date]} 00:00:00'" if params[:start_date].present?
    conditions << "sales.transaction_date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?

    if params[:all_stores] == 'Store'
      @sales_onlines = SalesOnline.select("offices.code AS kode_toko, office_name, SUM(sales_details.total_price)+SUM(sales_details.claim_amt) AS total_price, SUM(sales_details.quantity) AS total_quantity, SUM(ppn) AS total_ppn,
        SUM(capital_price*quantity) AS capital_price, sum(claim_amt) AS total_claim").joins(:sales, :store).group("offices.code, office_name").where(conditions.join(' AND ')).order("total_price DESC")
    else
      @sales_onlines = SalesOnline.select("sales_onlines.*, offices.office_name AS office_name").joins(:branch).where(conditions.join(' AND ')).paginate(:page => params[:page], :per_page => PER_PAGE) || []
    end
    filename = "Sales Online Report " + ".xlsx"

    respond_to do |format|
      format.html
      format.js
      format.xlsx { headers["Content-Disposition"] = "attachment; filename=\"#{filename}\"" }
    end
  end

  def month_report
    conditions = @condition if @condition.present?
    conditions = [] if @condition.blank?
    @month = '' if @month.blank?
    case @month
          when 'Januari'
            puts "FILTER BULAN JANUARI"
            year = Date.today.year
            eof = Date.new(year,1).end_of_month.strftime("%d")
            conditions << "transaction_date BETWEEN '#{Date.new(year,1)}' AND '#{Date.new(year,1,eof.to_i)}'"

            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Februari'
            puts "FILTER BULAN FEBRUARI"
            year = Date.today.year
            eof = Date.new(year,2).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,2)}' AND '#{Date.new(year,2,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Maret'
            puts "FILTER BULAN MARET"
            year = Date.today.year
            eof = Date.new(year,3).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,3)}' AND '#{Date.new(year,3,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'April'
            puts "FILTER BULAN APRIL"
            year = Date.today.year
            eof = Date.new(year,4).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,4)}' AND '#{Date.new(year,4,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Mei'
            puts "FILTER BULAN MEI"
            year = Date.today.year
            eof = Date.new(year,5).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,5)}' AND '#{Date.new(year,5,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Juni'
            puts "FILTER BULAN JUNI"
            year = Date.today.year
            eof = Date.new(year,6).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,6)}' AND '#{Date.new(year,6,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Juli'
            puts "FILTER BULAN JULI"
            year = Date.today.year
            eof = Date.new(year,7).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,7)}' AND '#{Date.new(year,7,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Agustus'
           puts "FILTER BULAN AGUSTUS"
            year = Date.today.year
            eof = Date.new(year,8).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,8)}' AND '#{Date.new(year,8,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'September'
            puts "FILTER BULAN SEPTEMBER"
            year = Date.today.year
            eof = Date.new(year,9).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,9)}' AND '#{Date.new(year,9,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'Oktober'
            puts "FILTER BULAN OKTOBER"
            year = Date.today.year
            eof = Date.new(year,10).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,10)}' AND '#{Date.new(year,10,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'November'
            puts "FILTER BULAN NOVEMBER"
            year = Date.today.year
            eof = Date.new(year,11).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,11)}' AND '#{Date.new(year,11,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when 'November'
            puts "FILTER BULAN DESEMBER"
            year = Date.today.year
            eof = Date.new(year,12).end_of_month.strftime("%d")

            conditions << "transaction_date BETWEEN '#{Date.new(year,12)}' AND '#{Date.new(year,12,eof.to_i)}'"
            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
          when ''
            puts "FILTER BULAN"

            @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
              SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
              .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
            @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
              SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")
        end
  end

  def sale_item_reports
    @dari = params[:dari]
    conditions = []
    conditions << "quantity>0"
    conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?
    conditions << "transaction_date>='#{params[:start_date]} 00:00:00'" if params[:start_date].present?
    conditions << "transaction_date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    conditions << "LOWER(article) LIKE '%#{params[:article]}%'" if params[:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(to_char(total_price, '999999')) LIKE '%#{params[:total_price]}%'" if params[:total_price].present?
    conditions << "LOWER(to_char(quantity, '999999')) LIKE '%#{params[:quantity]}%'" if params[:quantity].present?
    conditions << "LOWER(to_charz(total_quantity, '999999')) LIKE '%#{params[:total_quantity]}%'" if params[:total_quantity].present?
    conditions << "LOWER(to_char(retur, '999999')) LIKE '%#{params[:retur]}%'" if params[:retur].present?
    conditions << "LOWER(to_char(ppn, '999999')) LIKE '%#{params[:ppn]}%'" if params[:ppn].present?
    conditions << "LOWER(to_char(total_ppn, '999999')) LIKE '%#{params[:total_ppn]}%'" if params[:total_ppn].present?
    conditions << "LOWER(to_char(sales_net, '999999')) LIKE '%#{params[:sales_net]}%'" if params[:sales_net].present?
    conditions << "LOWER(to_char(hpp, '999999')) LIKE '%#{params[:hpp]}%'" if params[:hpp].present?
    conditions << "LOWER(to_char(margin_rp, '999999')) LIKE '%#{params[:margin_rp]}%'" if params[:margin_rp].present?
    conditions << "LOWER(to_char(margin_persen, '999999')) LIKE '%#{params[:margin_persen]}%'" if params[:margin_persen].present?
    conditions << "LOWER(m_classes.name) LIKE LOWER('%#{params[:m_classes_name]}%')" if params[:m_classes_name].present?
    conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:kode_toko]}%')" if params[:kode_toko].present?
    conditions << "LOWER(members.name) LIKE LOWER('%#{params[:member_name]}%')" if params[:member_name].present?
    conditions << "LOWER(office_name) LIKE '%#{params[:office_name]}%'" if params[:office_name].present?
    conditions << "LOWER(suppliers.name) LIKE LOWER('%#{params[:supplier_name]}%')" if params[:supplier_name].present?
    conditions << "LOWER(to_char(capital_price, '999999')) LIKE '%#{params[:capital_price]}%'" if params[:capital_price].present?
    conditions << "LOWER(to_char(transaction_date, 'YYYY-MM-DD')) LIKE LOWER('%#{params[:transaction_date]}%')" if params[:transaction_date].present?
    conditions << "member_id = #{params[:member_id]}" if params[:member_id].present?
    if @dari == "category"
      @sales = SalesDetail.select("m_class_id, name, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
            SUM(quantity) AS quantity").joins(product: :m_class, sale: :store).group("m_class_id, name").where(conditions.join(' AND ')).order("total_price DESC")#.paginate(:page => params[:page], :per_page => 10) || []
    elsif @dari == "item"
      @sales = SalesDetail.select("DISTINCT ON (product_suppliers.product_id) article, products.description, SUM(sales_details.total_price) AS total_price, SUM(sales_details.ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
            SUM(quantity) AS quantity, suppliers.name AS supplier_name").joins(product: :product_suppliers, sale: :store).joins("INNER JOIN suppliers ON suppliers.id = product_suppliers.supplier_id").group("article, products.description, supplier_name, product_suppliers.product_id").where(conditions.join(' AND '))
      #@sales = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
      #      SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("total_price DESC")#.paginate(:page => params[:page], :per_page => 10) || []
    elsif @dari == "store"
      @sales = Sale.select("offices.code AS kode_toko, office_name, SUM(sales_details.total_price) AS total_price, SUM(sales_details.quantity) AS total_quantity, SUM(ppn*quantity) AS total_ppn,
          SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("offices.code, office_name").where(conditions.join(' AND ')).order("total_price DESC")#.paginate(:page => params[:page], :per_page => 10) || []
    elsif @dari == "member"
      @sales = SalesDetail.select("member_id, members.name AS member_name, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
          SUM(quantity) AS quantity").joins(:product, sale: [:store, :member]).group("member_id, members.name").where(conditions.join(' AND ')).order("total_price DESC").paginate(:page => params[:page], :per_page => 10) || []
    elsif @dari == "month"
      @condition = conditions
      @month = params[:months]
      month_report
    elsif @dari == "tanggal"
      @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
          SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
          .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
      @sales_per_item = SalesDetail.select("article, products.description, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
          SUM(quantity) AS quantity").joins(:product, sale: :store).group("article, products.description").where(conditions.join(' AND ')).order("products.description ASC")

    elsif @dari == "hour"
     # @sales_per_hour = Sale.select("to_char(transaction_date, 'HH24 YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
     #   SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'HH24 YYYY-MM-DD')").where(conditions.join(' AND '))
     #   .order("to_char(transaction_date, 'HH24 YYYY-MM-DD') ASC")
        @sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, SUM(sales_details.total_price) AS total_price, SUM(ppn) AS total_ppn,
          SUM(capital_price*quantity) AS capital_price").joins(:store, :sales_details).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
          .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
    end
    respond_to do |format|
      format.js
    end
  end

  def sales
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def cashier
    conditions = []
    conditions2 = []
    conditions << "office_id=#{current_user.branch_id}" if current_user.branch_id.present?
    params[:search].each{|param|
      if param[0] == "COUNT(sales)"
        conditions2 << "CAST(#{param[0]} as text) LIKE '%#{param[1]}%'" if param[1].present?
      else
        if param[0] == "to_char(start_amount, '99999999D99')" || param[0] == "to_char(credit, '99999999D99')" || param[0] == "to_char(debit, '99999999D99')"
          parampa = param[1].split(",").join("")
          param[1] = parampa
        end
        conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
      end
    } if params[:search].present?
    @cashiers = SodEod.joins(:user)
      .select("sod_eods.user_id, sod_eods.created_at as ss_created_at, session, machine_id, start_amount, debit, credit, to_char(sod_eods.created_at, 'DD-MM-YYYY') as s_created_at, to_char(start_time, 'HH24:MI') as start_time, to_char(end_time, 'HH24:MI') as end_time, concat(first_name, ' ', last_name) AS username, sod_eods.receipt_count, cash")
      .where(conditions.join(' AND ')).order(default_order('sod_eods')).paginate(page: params[:page], :per_page => PER_PAGE)
    respond_to do |format|
      format.html
      format.js
      format.xls
    end
  end

  def cancelitem
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def profit_and_lost
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def terima_kembali_stok_opname
    @receiving_details = ReceivingDetail.get_stock_movement(params[:date_start], params[:date_end])
    @returns_to_supplier_details = ReturnsToSupplierDetail.get_stock_movement(params[:date_start], params[:date_end])
    @stock_opname_details = StockOpnameDetail.get_stock_movement(params[:date_start], params[:date_end])
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def unsold
    conditions = []
    conditions = []
    params[:search].each{|param|
    conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?

    respond_to do |format|
      format.html do
        @products = Product.where(conditions.join(' AND ')).get_product_unsold_for_three_months.joins(:brand, :m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id")
        .paginate(:page => params[:page], :per_page => 10) || []
      end
      format.js do
        @products = Product.where(conditions.join(' AND ')).get_product_unsold_for_three_months.joins(:brand, :m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id")
        .paginate(:page => params[:page], :per_page => 10) || []
      end
      format.xls do
        @products = Product.where(conditions.join(' AND ')).get_product_unsold_for_three_months.joins(:brand, :m_class).joins("INNER JOIN m_classes departments ON products.department_id=departments.id")
      end
    end
  end

  def file_backup_harian
  end

  def best_seller
    show_data = 10
    show_data = params[:show_data] if params[:show_data].present?
    conditions = []
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE '%#{param[1]}%'"
    } if params[:search].present?
    conditions << "transaction_date >= '%#{params[:start_date].to_date.strftime('%Y-%m-%d')}%'" if params[:start_date].present?
    conditions << "transaction_date <= '%#{params[:end_date].to_date.strftime('%Y-%m-%d')}%'" if params[:end_date].present?
    if params[:group_by] == 'Quantity'
      @products = Product.get_best_seller.joins(:m_class, sales_details: :sale).select("products.*, sum(sales_details.quantity) as total_quantity, sum(sales_details.total_price) as total_amount")
        .group("products.id").limit(show_data).order("total_quantity DESC").where(conditions.join(' AND '))
    elsif params[:group_by] == 'Amount'
      @products = Product.get_best_seller.joins(:m_class, sales_details: :sale).select("products.*, sum(sales_details.quantity) as total_quantity, sum(sales_details.total_price) as total_amount")
        .group("products.id").limit(show_data).order("total_amount DESC").where(conditions.join(' AND '))
    else
      @products = Product.get_best_seller.joins(:m_class, sales_details: :sale).select("products.*, sum(sales_details.quantity) as total_quantity, sum(sales_details.total_price) as total_amount")
        .group("products.id").limit(show_data).where(conditions.join(' AND '))
    end

    @filenames = "best_seller"
    @filenames << '_' + params[:group_by] if params[:group_by].present?
    @filenames << '_from_' + params[:start_date] if params[:start_date].present?
    @filenames << '_until_' + params[:end_date] if params[:end_date].present?
    respond_to do |format|
      format.html
      format.js
      format.xls{ headers["Content-Disposition"] = "attachment; filename=\"#{@filenames}.xls\""}
    end
  end

  def file_backup_bulanan
    respond_to do |format|
      format.html
      format.xls
    end
  end

  def sale_xls
    book = Spreadsheet::Workbook.new
    sale_xls_sheet(book, 'Toko') if params[:all_stores] == "Store"
    sale_xls_sheet(book, 'Item') if params[:all_stores] == "Item"
    sale_xls_sheet(book, 'Tanggal') if params[:all_stores].nil? || (params[:all_stores] != "Item")


    out = StringIO.new
    book.write out
    out.rewind

    return out.string
  end

  def sale_xls_sheet(book, category)
    sheet = book.create_worksheet(:name => category)

    conditions = ["quantity>0"]
    conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?
    conditions << "transaction_date>='#{params[:start_date]} 00:00:00'" if params[:start_date].present?
    conditions << "transaction_date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    conditions << "to_char(transaction_date, 'YYYY-MM-DD')='#{params[:transaction_date]}'" if params[:transaction_date].present?
    conditions << "article='#{params[:article]}'" if params[:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:description]}%')" if params[:description].present?
    conditions << "LOWER(suppliers.name) LIKE LOWER('%#{params[:supplier_name]}%')" if params[:supplier_name].present?

    case category
    when 'Toko'
      title = ['Kode Toko', 'Nama Toko', 'Sales Price', 'Sales Qty', 'Retur Sales', 'PPN', 'Sales Net', 'HPP', 'Claim', 'Margin Rp', 'Margin %', 'Struk', 'APC']
      sales = Sale.select("offices.code AS kode_toko, office_name, (SUM(sales_details.total_price)) AS total_price, SUM(sales_details.quantity) AS total_quantity, SUM(ppn*quantity) AS total_ppn,
        SUM(capital_price*quantity) AS capital_price, SUM(claim_amt) as total_claim").joins(:store, :sales_details).group("offices.code, office_name").where(conditions.join(' AND ')).order("total_price DESC")
    when 'Item'
      title = ['Kode Item', 'Nama Item', 'Supplier Name', 'Sales Price', 'Sales Qty', 'Retur Sales', 'PPN', 'Sales Net', 'HPP', 'Margin Rp', 'Margin %']
      sales = SalesDetail.select("DISTINCT ON (product_suppliers.product_id) article, products.description, SUM(sales_details.total_price) AS total_price, SUM(sales_details.ppn) AS ppn, SUM(capital_price*quantity) AS capital_price,
            SUM(quantity) AS quantity, suppliers.name AS supplier_name").joins(product: :product_suppliers, sale: :store).joins("INNER JOIN suppliers ON suppliers.id = product_suppliers.supplier_id").group("article, products.description, supplier_name, product_suppliers.product_id").where(conditions.join(' AND '))
    when 'Tanggal'
      title = ['DATE', 'SALES PRICE', 'SALES QTY', 'RETUR SALES', 'PPN', 'SALES NET', 'HPP', 'CLAIM', 'MARGIN RP', 'MARGIN %', 'RECEIPT', 'APC']
      sales = Sale.select("to_char(transaction_date, 'YYYY-MM-DD') AS transaction_date, SUM(quantity) AS total_quantity, (SUM(sales_details.total_price)) AS total_price, SUM(ppn) AS total_ppn,
          SUM(capital_price*quantity) AS capital_price, SUM(claim_amt) AS total_claim").joins(
            :store, :sales_details
          ).group("to_char(transaction_date, 'YYYY-MM-DD')").where(conditions.join(' AND '))
          .order("to_char(transaction_date, 'YYYY-MM-DD') ASC")
    end

    sheet.row(0).push *title

    f_all = Spreadsheet::Format.new
    f_all.top = :medium
    f_all.bottom = :medium
    f_all.left = :medium
    f_all.right = :medium

    f_mid = Spreadsheet::Format.new
    f_mid.top = :none
    f_mid.bottom = :none
    f_mid.left = :medium
    f_mid.right = :medium

    widths = []
    title.each_with_index do |str, i|
      widths << title[i].length
      sheet.row(0).set_format(i, f_all)
    end

    sales_counts = 0
    retur_counts = 0
    apc = 0
    sales.each_with_index do |sale, i|
      data = []
      case category
      when 'Toko'
        sales_count = Sale.where("offices.code='#{sale.kode_toko}'").joins(:store).count
        retur_count = SalesDetail.where("offices.code='#{sale.kode_toko}' AND quantity<0").joins(sale: :store).map(&:quantity).sum*-1

        data << sale.kode_toko
        data << sale.office_name
        data << sale.total_price+(sale.total_claim || 0) # Sales Price
        data << sale.total_quantity
        data << retur_count
        data << sale.total_ppn
        data << sale.total_price-sale.total_ppn
        data << sale.capital_price
        data << sale.total_claim #CLAIM
        data << sale.total_price-sale.total_ppn-sale.capital_price
        data << ((sale.total_price-sale.total_ppn-sale.capital_price)/sale.capital_price.to_f*100).to_s + " %"
        data << sales_count
        data << sale.total_price/sales_count

        sales_counts += sales_count
        apc += sale.total_price/sales_count
        retur_counts += retur_count
      when 'Item'
        retur_count = SalesDetail.where("article='#{sale.article}' AND quantity<0").joins(:product).map(&:quantity).sum*-1
        net_sales = sale.total_price-sale.ppn
        data << sale.article
        data << sale.description
        data << sale.supplier_name
        data << sale.total_price
        data << sale.quantity
        data << retur_count
        data << sale.ppn
        data << net_sales
        data << sale.capital_price
        data << sale.total_price.to_f-sale.ppn.to_f-sale.capital_price.to_f
        data << ((sale.total_price-sale.ppn-sale.capital_price.to_f)/net_sales*100).round(2).to_s + " %"
        retur_counts += retur_count
      when 'Tanggal'
        conditions = []
        conditions << "to_char(transaction_date, 'YYYY-MM-DD')='#{sale.transaction_date}'"
        conditions << "offices.code='#{params[:store_code]}'" if params[:store_code].present?
        sales_count = Sale.where(conditions.join(' AND ')).joins(:store).count rescue 0
        retur = SalesDetail.where("to_char(transaction_date, 'YYYY-MM-DD')='#{sale.transaction_date}' AND quantity<0").joins(:sale).map(&:quantity).sum*-1 rescue 0


        data << sale.transaction_date # Tanggal
        data << sale.total_price+(sale.total_claim || 0) # Sales Price
        data << sale.total_quantity # Sales Qty
        data << retur # Retur Sales
        data << sale.total_ppn # PPN
        data << sale.total_price-sale.total_ppn #Sales NET
        data << sale.capital_price #HPP
        data << sale.total_claim #CLAIM
        # data << sale.total_debit #sale.debit_amt + sale.credit_amt #DEBIT
        data << sale.total_price-sale.total_ppn-sale.capital_price rescue 0 #Margin RP.
        data << ((sale.total_price-sale.total_ppn-sale.capital_price)/(sale.total_price-sale.total_ppn).to_f*100 rescue 0).round(2)
        data << sales_count # Struk
        data << (sales_count == 0 ? 0 : (sale.total_price-sale.total_ppn)/sales_count) rescue 0 # APC

        sales_counts += sales_count
        retur_counts += retur
      end
      sheet.row(i + 1).push *data

      (0..data.length-1).each do |j|
        widths[j] = [widths[j], data[j].to_s.length].max
        sheet.row(i + 1).set_format(j, f_mid)
      end
    end

    data = ['Total']
    if category == 'Item'
      total_net_sales = sales.map{|sale|sale.total_price-sale.ppn}.sum
      data << ''
      data << ''
      data << sales.map(&:total_price).sum
      data << sales.map(&:quantity).sum
      data << retur_counts
      data << sales.map(&:ppn).sum
      data << total_net_sales
      data << sales.map(&:capital_price).compact.sum
      data << sales.map{|sale|sale.total_price.to_f-sale.ppn.to_f-sale.capital_price.to_f}.sum
      data << (sales.map{|sale|sale.total_price.to_f-sale.ppn.to_f-sale.capital_price.to_f}.sum/total_net_sales*100).round(2).to_s + " %"
    else
      data << '' unless category == 'Tanggal'
      data << sales.map(&:total_price).sum
      data << sales.map(&:total_quantity).sum
      data << retur_counts
      data << sales.map(&:total_ppn).sum
      data << sales.map{|sale|sale.total_price-sale.total_ppn}.sum
      data << sales.map(&:capital_price).sum
      data << (sales.map(&:total_claim).sum || 0)
      # data << sales.map(&:total_debit).sum
      data << sales.map{|sale|sale.total_price-sale.total_ppn-sale.capital_price}.sum
      data << (@sales.map{|sale|sale.total_price-sale.total_ppn-sale.capital_price}.sum/@sales.map{|sale|sale.total_price-sale.total_ppn}.sum*100 rescue 0).round(2)
      data << sales_counts
      if category == 'Toko'
        data << apc
      else
        data << sales.map{|sale|sale.total_price-sale.total_ppn}.sum/sales_counts rescue 0
      end
    end
    sheet.row(sales.length + 1).push *data
    sheet.merge_cells(sales.length + 1, 0, sales.length + 1, 1) unless category == 'Tanggal'

    (0..data.length-1).each do |i|
      sheet.column(i).width = widths[i] + 5
      sheet.row(sales.length + 1).set_format(i, f_all)
    end
  end

  def stock_group_by_item
    conditions = []
    end_day = (Time.now.month == Date::MONTHNAMES.index(params[:month]) ? Time.now.day-1 : "#{params[:year]}-#{params[:month]}-01".to_date.end_of_month.day)
    params[:start_date] = "#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}-01"
    params[:end_date] = "#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}-#{end_day}"
    conditions << "daily_sales_inventories.date>='#{params[:start_date]}'" if params[:start_date].present?
    conditions << "daily_sales_inventories.date<='#{params[:end_date]} 23:59:59'" if params[:end_date].present?
    conditions << "LOWER(office_name) LIKE LOWER('%#{params[:office_name]}%')" if params[:office_name].present?
    conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:store_code]}%')" if params[:store_code].present?
    conditions << "LOWER(article) LIKE '%#{params[:search][:article]}%'" if params[:search].present? && params[:search][:article].present?
    conditions << "LOWER(products.description) LIKE LOWER('%#{params[:search][:description]}%')" if params[:search].present? && params[:search][:description].present?
    @product_mutations_ungrouped = DailySalesInventory.where(conditions.join(' AND ')).order('start_amount DESC').joins(:office, :product)
    @start_stock = @product_mutations_ungrouped.where("date='#{params[:start_date]}'").group_by{|pmh|pmh.product_id}
    @end_stocks = @product_mutations_ungrouped.where("date='#{params[:end_date]}'")
    @end_stock = @end_stocks.group_by{|pmh|pmh.product_id}
    @product_mutations = @product_mutations_ungrouped.group_by{|pmh|pmh.product_id}
  end

  def stock_group_by_date
    conditions = []
    params[:start_date] = "#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month]))}-01"
    params[:end_date] = "#{params[:year]}-#{sprintf('%02d', Date::MONTHNAMES.index(params[:month])+1)}-01 00:00:00"
    conditions << "daily_sales_inventories.date>='#{params[:start_date]}'" if params[:start_date].present?
    conditions << "daily_sales_inventories.date<'#{params[:end_date]}'" if params[:end_date].present?
    conditions << "LOWER(office_name) LIKE LOWER('%#{params[:office_name]}%')" if params[:office_name].present?
    conditions << "LOWER(offices.code) LIKE LOWER('%#{params[:store_code]}%')" if params[:store_code].present?
    @product_mutations_ungrouped = DailySalesInventory.where(conditions.join(' AND ')).order('date ASC').joins(:office)
    @product_mutations = @product_mutations_ungrouped.group_by{|pmh|pmh.date}
    @start_stock = @product_mutations_ungrouped.where("date='#{params[:start_date]}'").group_by{|pmh|pmh.office_id}
    @end_stocks = @product_mutations_ungrouped.where("date='#{params[:end_date]}'")
    @end_stock = @product_mutations_ungrouped.where("date='#{params[:end_date]}'").group_by{|pmh|pmh.office_id}
  end

  def stock_dsi_xls_sheet book, category
    stock_group_by_item_per_month if params[:all_stores].present? && params[:all_stores] == 'Item'
    stock_group_by_store_per_month if params[:all_stores].present? && params[:all_stores] == 'Store'
    title = ['Awal', '', 'Sales', '', 'Retur sls', '', 'BPB', '', 'TaT In', '', 'TaT Out', '', 'Retur', '', 'SO', '', 'Penyesuaian', 'HPP Satuan', 'Akhir', '']
    title << 'DSI' unless params[:all_stores] == 'Date'
    subtitle = ['Qty', 'Rp', 'Qty', 'Rp', 'Qty', 'Rp', 'Qty', 'Rp', 'Qty', 'Rp', 'Qty', 'Rp', 'Qty', 'Rp', 'Qty', 'Rp', '', '', 'Qty', 'Rp', '']
    sheet = book.create_worksheet(:name => category)

    case category
    when 'Toko'
      title.prepend(*['Kode Toko', 'Nama Toko'])
      subtitle.prepend(*['', ''])
    when 'Item'
      title.prepend(*['Department','Kode Item', 'Nama Item'])
      subtitle.prepend(*['', ''])
    when 'Tanggal'
      title.prepend('Tanggal')
      subtitle.prepend('')
    end

    sheet.row(0).push *title
    sheet.row(1).push *subtitle

    f_all = Spreadsheet::Format.new
    f_all.top = :medium
    f_all.bottom = :medium
    f_all.left = :medium
    f_all.right = :medium

    f_mid = Spreadsheet::Format.new
    f_mid.top = :none
    f_mid.bottom = :none
    f_mid.left = :medium
    f_mid.right = :medium

    widths = []
    title.each_with_index do |str, i|
      # merge empty cell
      sheet.merge_cells(0, i - 1, 0, i) if str == ''
      sheet.merge_cells(0, i, 1, i) if subtitle[i] == ''

      widths << subtitle[i].length
      sheet.row(0).set_format(i, f_all)
      sheet.row(1).set_format(i, f_all)
    end
    if params[:all_stores].present? && params[:all_stores] == 'Item'
      @product_mutations.each_with_index{|pmh, i|
        count_day = (Time.now.month == Date::MONTHNAMES.index(params[:month]) ? Time.now.day-1 : "#{params[:year]}-#{params[:month]}-01".to_date.end_of_month.day)
        sheet.row(2+i).push *[pmh.article, pmh.description, pmh.start_qty, pmh.start_amount,pmh.sales_qty, pmh.sales_amount, pmh.retur_sales_qty, pmh.retur_sales_amount, pmh.gr_qty, pmh.gr_amount,
          pmh.tat_in_qty, pmh.tat_in_amount, pmh.tat_out_qty, pmh.tat_out_amount, pmh.retur_qty, pmh.retur_amount, pmh.so_qty, pmh.so_amount,
          pmh.end_amount-(pmh.start_amount-pmh.sales_amount+pmh.retur_sales_amount+pmh.gr_amount-pmh.retur_amount+pmh.tat_in_amount-pmh.tat_out_amount+pmh.so_amount), pmh.last_cost, pmh.end_qty, pmh.end_amount,
          (pmh.end_qty/pmh.sales_qty*count_day rescue 0)]
      }
    else
      count_day = (Time.now.month == Date::MONTHNAMES.index(params[:month]) ? Time.now.day-1 : "#{params[:year]}-#{params[:month]}-01".to_date.end_of_month.day)
      @product_mutations.each_with_index{|pmh, i|
        sheet.row(2+i).push *[pmh.code, pmh.office_name, pmh.start_qty, pmh.start_amount, pmh.sales_qty, pmh.sales_amount, pmh.retur_sales_qty, pmh.retur_sales_amount, pmh.gr_qty, pmh.gr_amount, pmh.tat_in_qty,
          pmh.tat_in_amount, pmh.tat_out_qty, pmh.tat_out_amount, pmh.retur_qty, pmh.retur_amount, pmh.so_qty, pmh.so_amount,
          pmh.end_amount-(pmh.start_amount-pmh.sales_amount+pmh.retur_sales_amount+pmh.gr_amount-pmh.retur_amount+pmh.tat_in_amount-pmh.tat_out_amount+pmh.so_amount), pmh.last_cost, pmh.end_qty, pmh.end_amount,
          (pmh.end_qty/pmh.sales_qty*count_day)]
      }
    end
  end

  def stock_xls
    book = Spreadsheet::Workbook.new
    if params[:all_stores] == 'Store'
      stock_dsi_xls_sheet(book, 'Toko')
    elsif params[:all_stores] == 'Item'
      stock_dsi_xls_sheet(book, 'Item')
    elsif params[:all_stores].present? && params[:all_stores] == 'Date'
      stock_dsi_xls_sheet(book, 'Tanggal')
    end

    out = StringIO.new
    book.write out
    out.rewind

    return out.string
  end

  def convertion_history
    conditions = []
    #conditions << "updated_at >= '#{params[:last_update]}'" if params[:last_update].present?
    # conditions << "product_structures.created_at = '#{params[:start_date]}'" if params[:start_date].present?
    params[:search].each{|param|
      conditions << "LOWER(#{param[0]}) LIKE LOWER('%#{param[1]}%')" if param[1].present?
    } if params[:search].present?

    conditions << "article = '#{params[:clicked_article]}'" if params[:clicked_article].present?
    if params[:show_details].present?
      convertion_history_detail
      @selected_product = params[:clicked_article] if params[:clicked_article].present?
    end

    @products = Product.joins(:m_class).select("products.*, m_classes.name as m_class_name").where("products.id IN (SELECT product_id FROM skus WHERE id IN (SELECT parent_id FROM product_structures))").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')).paginate(page: params[:page], per_page: 100) || []
    @products2 = Product.joins(:m_class).select("products.*, m_classes.name as m_class_name").where("products.id IN (SELECT product_id FROM skus WHERE id IN (SELECT parent_id FROM product_structures))").where(conditions.join(' AND ')).order(params[:sort].to_s.gsub('-', ' ')) || []

    respond_to do |format|
      format.html
      format.js
    end
  end

  def convertion_history_detail
    conditions = []
    conditions << "warehouse_id = #{current_user.branch_id}" if current_user.branch_id.present?
    conditions << "products.article = '#{params[:clicked_article]}'" if params[:clicked_article].present?
    conditions << "code = '#{params[:code]}'" if params[:code].present?
    conditions << "moved_qty = '#{params[:quantity]}'" if params[:quantity].present?
    conditions << "LOWER(offices.office_name) LIKE '%#{params[:store]}'" if params[:store].present?
    conditions << "to_char(zfoods.created_at, 'YYYY-MM-DD') = '#{params[:date]}'" if params[:date].present?
    conditions << "products.article = '#{params[:clicked_article]}'" if params[:clicked_article].present?
    @selected_product = params[:clicked_article] if params[:clicked_article].present?
    @zf = Zfood.where(conditions.join(' AND ')).joins(product_detail: :warehouse, zfood_details: [sku: :product]).includes(product_detail: :warehouse).includes(zfood_details: :sku).distinct()
  end

  private
  def get_product_mutation_histories(category)
    if category == 'Store'
      @product_mutation_histories = @product_mutations.group_by{|pmh|pmh.product_detail.warehouse}
    elsif category == 'Item'
      @product_mutation_histories = @product_mutations.group_by{|pmh|pmh.product_detail.product}
    elsif category == 'Month'
      @product_mutation_histories = @product_mutations.group_by{|pmh|pmh.created_at.strftime('%Y-%m-%d')}
    elsif category == 'Date'
      @product_mutation_histories = @product_mutations.group_by{|pmh|pmh.created_at.strftime('%Y-%m-%d')}
      if params[:transaction_date].present?
        @product_mutation_per_item = @product_mutations.group_by{|pmh|pmh.product_detail.product}
        @stocks_per_item = {}
        @product_mutation_per_item.each{|pmh|
          pmh[1].each_with_index{|p, i|
            if @stocks_per_item["qty_#{pmh[0]}_#{p.mutation_type}"].present?
              @stocks_per_item["qty_#{pmh[0]}_#{p.mutation_type}"] += p.moved_quantity.to_i
              @stocks_per_item["price_#{pmh[0]}_#{p.mutation_type}"] += p.price.to_f
              @stocks_per_item["ppn_#{pmh[0]}_#{p.mutation_type}"] += p.ppn.to_f
              if p.mutation_type == 'Sales' && p.discount.to_f > 0
                @stocks_per_item["price_#{pmh[0]}_Discount"] += p.discount.to_f
                @stocks_per_item["qty_#{pmh[0]}_Discount"] += p.moved_quantity.to_i
              end
            else
              @stocks_per_item["qty_#{pmh[0]}_#{p.mutation_type}"] = p.moved_quantity.to_i
              @stocks_per_item["price_#{pmh[0]}_#{p.mutation_type}"] = p.price.to_f
              @stocks_per_item["ppn_#{pmh[0]}_#{p.mutation_type}"] = p.ppn.to_f
              if p.mutation_type == 'Sales' && p.discount.to_f > 0
                @stocks_per_item["price_#{pmh[0]}_Discount"] = p.discount.to_f
                @stocks_per_item["qty_#{pmh[0]}_Discount"] = p.moved_quantity.to_i
              end
            end
          }
        }
      end
    elsif params[:all_stores] == 'Jam'
      @product_mutation_histories = @product_mutations.group_by{|pmh|pmh.created_at.strftime('%Y-%m-%d')}
    end

    @stocks = {}
    @last_stock = {}
    @product_mutation_histories.each{|pmh|
      pmh[1].each_with_index{|p, i|
        if @stocks["qty_#{pmh[0]}_#{p.mutation_type}"].present?
          @stocks["qty_#{pmh[0]}_#{p.mutation_type}"] += p.moved_quantity.to_i
          @stocks["price_#{pmh[0]}_#{p.mutation_type}"] += p.price.to_f
          @stocks["ppn_#{pmh[0]}_#{p.mutation_type}"] += p.ppn.to_f
          if p.mutation_type == 'Sales' && p.discount.to_f > 0
            @stocks["price_#{pmh[0]}_Discount"] += p.discount.to_f
            @stocks["qty_#{pmh[0]}_Discount"] += p.moved_quantity.to_i
          end
        else
          @stocks["qty_#{pmh[0]}_#{p.mutation_type}"] = p.moved_quantity.to_i
          @stocks["price_#{pmh[0]}_#{p.mutation_type}"] = p.price.to_f
          @stocks["ppn_#{pmh[0]}_#{p.mutation_type}"] = p.ppn.to_f
          if p.mutation_type == 'Sales' && p.discount.to_f > 0
            @stocks["price_#{pmh[0]}_Discount"] = p.discount.to_f
            @stocks["qty_#{pmh[0]}_Discount"] = p.moved_quantity.to_i
          end
        end
      }
      @last_stock[pmh[0]] = pmh[1].map(&:product_detail).uniq.map(&:available_qty).compact.sum
    } if @product_mutation_histories.present?
  end
end
