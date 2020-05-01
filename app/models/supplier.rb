class Supplier < ActiveRecord::Base
#  include Filter
  JOIN = ''
  ORDER = 'suppliers.id'
  SELECTED = 'suppliers.*'
  GROUP_BY = 'suppliers.id'

  before_validation :upcase_save

  before_destroy :check_transaction

  has_many :brands
  has_many :purchase_orders
  has_many :returns_to_suppliers
  has_many :returns_to_supplier_details, :through => :returns_to_suppliers
  has_many :goods, through: :brands
  has_many :goods_receipts
  has_many :composite_purchase_orders
  has_many :contact_people
  has_many :bank_accounts
  has_many :purchase_requests
  has_many :inventory_requests
  has_many :stock_opnames
  has_many :supplier_departments
  has_many :departments, class_name: 'MClass', through: :supplier_departments
  has_many :account_payables
  has_many :products, through: :contact_people
  has_many :contact_person

  attr_accessor :is_import

  accepts_nested_attributes_for :supplier_departments, reject_if: :all_blank, allow_destroy: true
  # accepts_nested_attributes_for :contact_person, reject_if: :all_blank, allow_destroy: true
  # accepts_nested_attributes_for :bank_accounts, reject_if: :all_blank, allow_destroy: true


  validates :name, presence: true, uniqueness: true
  validates :address, :presence => true
  validates :city, :presence => true
  # validates :phone, presence: true
  # validates_format_of :name, :with => /^[a-zA-Z\d\s.()]*$/i, :multiline => true, :message => "can be inputted by alphabet only"
  #validates_format_of :address, :with => /^[a-zA-Z\d\s.,-]*$/i, :multiline => true, :message => "can be inputted by alphabet . , only"
  #validates_format_of :city, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates_format_of :phone, :with => /^[\d\s(),^\/-]*$/i, :multiline => true, :message => "Only numeric with (),- and backslash"
  validates_format_of :fax, :with => /^[\d\s(),^\/-]*$/i, :multiline => true, :message => "Only numeric with (),- and backslash"

  #validates :long_term, numericality: {only_integer: true}, on: :create
  validate :at_least_one_cp
  validate :at_least_one_ba

  accepts_nested_attributes_for :contact_people, reject_if: :all_blank, allow_destroy: true
  accepts_nested_attributes_for :bank_accounts, reject_if: :all_blank, allow_destroy: true

  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ? OR name LIKE ? OR send_address LIKE ? OR city LIKE ? OR phone LIKE ? OR hp1 LIKE ? OR pinbb LIKE ? OR email LIKE ?',
      "%#{search.first}%", "%#{search.first}%", "%#{search.first}%", "%#{search.first}%", "%#{search.first}%", "%#{search.first}%",
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def at_least_one_cp
    errors.add(:contact_person, "can't be blank") if contact_people.blank? && is_import.blank?
  end

  def at_least_one_ba
    errors.add(:bank_account, "can't be blank") if bank_accounts.blank? && is_import.blank?
  end

  def check_transaction
    return false if ProductSupplier.where(contact_person_id: contact_people.map(&:id)).present? || Brand.find_by_supplier_id(id)
    true
  end

  def self.number(params)
    number = (Supplier.first(:conditions => "name like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:supplier][:name][0]
    number = (Supplier.first(:conditions => "name like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end


  def self.get_supplier_id(supplier)
    id = (Supplier.first(:conditions => "code = '#{supplier}' or name = '#{supplier}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def upcase_save
    self.name = name.titleize rescue nil
    self.address = address.titleize rescue nil
    self.city = city.titleize rescue nil
    self.long_term = nil if suptype == 'Konsinyasi'
  end

  def self.to_csv(product_st, options = {})
    CSV.generate(options) do |csv|
      csv << ["Code", "Name", "Address", "City", "Send Address", "Phone", "Fax", "Long Term", "Suptype", "Contact Person", "No HP", "Pin BB", "Email", "Nama Rekening Bank", "No Rekening", "Bank", "Cabang", "Kota", "Department"]
      product_st.each do |supplier|
        phone = (supplier.phone.first rescue nil) == '0' ? "'#{supplier.phone}" : supplier.phone
        first_cp = supplier.contact_people.first

        if first_cp.present?
          cp_phone = first_cp.phone.to_s.first == '0' ? "'#{first_cp.phone}" : first_cp.phone
        end
        supp = [supplier.code, supplier.name, supplier.address, supplier.city, supplier.send_address, phone, supplier.fax, supplier.long_term, supplier.suptype]
        supp += [(first_cp.name rescue ''), cp_phone, (first_cp.pinbb rescue ''), (first_cp.email rescue nil)]
        first_ba = supplier.bank_accounts.first
        supp += [(first_ba.name rescue ''), (first_ba.account_number rescue ''), (first_ba.bank_name rescue ''), (first_ba.branch rescue ''), (first_ba.city rescue '')]
        supp += [(supplier.departments.first.name rescue nil)]

        csv << supp
        1.upto([supplier.bank_accounts.length, supplier.contact_people.length, supplier.departments.length].max-1) do |i|
          cp = supplier.contact_people[i]
          ba = supplier.bank_accounts[i]
          sd = supplier.departments[i]
          supp = ['', '', '', '', '', '', '', '']
            cp_phone = cp.phone.first == '0' ? "'#{cp.phone}" : cp.phone rescue 0
          if cp.present?
          end
          supp += [(cp.name rescue ''), (cp.phone rescue ''), (cp.pinbb rescue ''), (cp.email rescue '')]
          supp += [(ba.name rescue ''), (ba.account_number rescue ''), (ba.bank_name rescue ''), (ba.branch rescue ''), (ba.city rescue '')]
          supp += [sd.name] if sd.present?
          csv << supp
        end
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["name", "address", "city", "send_address", "phone", "fax", "long_term", "Suptype", "Contact Person", "No HP", "Pin BB", "Email", "Nama Rekening Bank", "No Rekening", "Bank", "Cabang", "Kota",
        "Department"]
    end
  end

  def self.import(file)
    line = 0
    $NAMANYA = ''
    CSV.foreach(file.path, headers: true) do |row|
      params = ActionController::Parameters.new(row.to_hash)
      if params["name"].present?
        $NAMANYA = params["name"]
        $SUPPLIER = Supplier.new(name: params["name"], address: params["address"], city: params["city"], send_address: params["send_address"], phone: params["phone"], fax: params["fax"],
          long_term: params["long_term"], code: params["code"] || "S#{('%03d' % ((Supplier.last.code.gsub('S', '').to_i rescue 0)+1))}", status_pkp: params['status_pkp'] != 'NON PKP', is_import: true)
        if $SUPPLIER.save

          ContactPerson.create(name: params['Contact Person'], division_name: params['Contact Person'], phone: params['No HP'], pinbb: params['Pin BB'], email: params['Email'], supplier_id: $SUPPLIER.id)

          BankAccount.create(name: params['Nama Rekening Bank'], account_number: params['No Rekening'], bank_name: params['Bank'], branch: params['Cabang'], city: params['Kota'], supplier_id: $SUPPLIER.id)
          SupplierDepartment.create(supplier_id: $SUPPLIER.id, department_id: Department.where(name: params['Department'].titleize).first_or_create.id) if params['Department'].present?
          line += 1
        else
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{$SUPPLIER.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{$SUPPLIER.errors.full_messages.join('<br/>')}"}
        end
      else
        id_sup = $SUPPLIER.id
        ContactPerson.create(name: params['Contact Person'], division_name: params['Contact Person'], phone: params['No HP'], pinbb: params['Pin BB'], email: params['Email'], supplier_id: id_sup)
        BankAccount.create(name: params['Nama Rekening Bank'], account_number: params['No Rekening'], bank_name: params['Bank'], branch: params['Cabang'], city: params['Kota'], supplier_id: id_sup)
        SupplierDepartment.create(supplier_id: id_sup, department_id: Department.where(name: params['Department'].titleize).first_or_create.id) if params['Department'].present?
      end
    end
    return {error: 0, message: "Successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end

  def self.import_data_to_other_database
    begin
      unless DatabaseLain.connected? 
        DatabaseLain.connection
      end
    rescue
      print "failed to connect server database"
    end
    if DatabaseLain.connected?
      supplier_data = Supplier.all
      unless supplier_data.present?
        print "Semua data supplier telah terkirim"
      else
        supplier_count = 0
        supplier_data.each do |data_supplier|
          if PtnrMstr.find_by_ptnr_code(data_supplier.code).nil?
            ptnr_id = PtnrMstr.order(:ptnr_id).last.ptnr_id
            if ptnr_id.to_s.slice(0) == '2'
              ptnr_id = (("#{('%06d')}" % ((PtnrMstr.order(:ptnr_id).last.ptnr_id)+1)).to_i)
            else
              ptnr_id = (("#{('2%06d')}" % ((PtnrMstr.order(:ptnr_id).last.ptnr_id)+1)).to_i)
            end
            ptnr_mstr = PtnrMstr.new(ptnr_oid: SecureRandom.uuid, ptnr_dom_id: 1, ptnr_en_id: 1, ptnr_add_by: "", ptnr_add_date: DateTime.now, ptnr_id: ptnr_id, ptnr_code: data_supplier.code, ptnr_name: data_supplier.name, ptnr_ptnrg_id: 10174, ptnr_is_cust: 'N', ptnr_is_vend: 'Y', ptnr_active: 'Y', ptnr_dt: DateTime.now, ptnr_ac_ar_id: 0, ptnr_sb_ar_id: 0, ptnr_cc_ar_id: 0, ptnr_ac_ap_id: 0, ptnr_sb_ap_id: 0, ptnr_cc_ap_id: 0, ptnr_cu_id: 1, ptnr_limit_credit: 0, ptnr_institution_id: 1000100, ptnr_branch_id: 10001, ptnr_type_id: 991440, ptnr_credit_terms_id: 991025, ptnr_sales_id: 0, ptnr_tax_class: 0, ptnr_tax_include: 'N', ptnr_bk_id: 0)
            ptnr_mstr.save
          else
            ptnr_mstr = PtnrMstr.find_by_ptnr_code(data_supplier.code)
            if ((ptnr_mstr.ptnr_upd_date < data_supplier.sent_to_erp) rescue true)
              ptnr_mstr.update_attributes(ptnr_upd_by: "", ptnr_upd_date: DateTime.now, ptnr_add_by: "", ptnr_name: data_supplier.name)
            end
          end
          #== address ==#
          if PtnraAddr.find_by_ptnra_line_1_and_ptnra_ptnr_oid(data_supplier.address, ptnr_mstr.ptnr_oid).nil?
            ptnra_id = PtnraAddr.order(:ptnra_id).last.ptnra_id
            if ptnra_id.to_s.slice(0) == '2'
              ptnra_id = (("#{('%07d')}" % ((PtnraAddr.order(:ptnra_id).last.ptnra_id)+1)).to_i)
            else
              ptnra_id = (("#{('2%07d')}" % ((PtnraAddr.order(:ptnra_id).last.ptnra_id)+1)).to_i)
            end
            ptnra_addr = PtnraAddr.new(ptnra_oid: SecureRandom.uuid, ptnra_dom_id: 1, ptnra_en_id: 1, ptnra_add_by: "", ptnra_add_date: DateTime.now, ptnra_id: ptnra_id, ptnra_line_1: data_supplier.address, ptnra_line_2: data_supplier.city, ptnra_phone_1: data_supplier.phone, ptnra_fax_1: data_supplier.fax, ptnra_ptnr_oid: ptnr_mstr.ptnr_oid, ptnra_addr_type: 993, ptnra_active: 'Y', ptnra_dt: DateTime.now)
            ptnra_addr.save
          else
            ptnra_addr = PtnraAddr.find_by_ptnra_line_1_and_ptnra_ptnr_oid(data_supplier.address, ptnr_mstr.ptnr_oid)
            if ((ptnr_mstr.ptnra_upd_date < data_supplier.sent_to_erp) rescue true)
              ptnra_addr.update_attributes(ptnra_upd_by: "", ptnra_upd_date: DateTime.now, ptnra_line_1: data_supplier.address, ptnra_line_2: data_supplier.city, ptnra_phone_1: data_supplier.phone, ptnra_fax_1: data_supplier.fax)
            end
          end
          #== contact ==#
          data_supplier.contact_people.each do |su_cp|
            if PtnracCntc.find_by_ptnrac_contact_name_and_addrc_ptnra_oid((ContactPerson.find(su_cp.id.to_i).name rescue ''), ptnra_addr.ptnra_oid).nil?
              ptnrac_cntc = PtnracCntc.new(ptnrac_oid: SecureRandom.uuid, addrc_ptnra_oid: ptnra_addr.ptnra_oid, ptnrac_add_by: "", ptnrac_add_date: DateTime.now, ptnrac_seq: 1, ptnrac_function: 9945, ptnrac_contact_name: su_cp.name, ptnrac_phone_1: su_cp.phone, ptnrac_email: su_cp.email, ptnrac_dt: DateTime.now)
              ptnrac_cntc.save
            else
              update_cp = ContactPerson.find(su_cp.id.to_i).name
              ptnrac_cntc = PtnracCntc.find_by_ptnrac_contact_name_and_addrc_ptnra_oid(update_cp, ptnra_addr.ptnra_oid)
              if ((ptnrac_mstr.ptnr_upd_date < data_supplier.sent_to_erp) rescue true)
                ptnrac_cntc.update_attributes(ptnrac_upd_by: "", ptnrac_upd_date: DateTime.now, ptnrac_contact_name: su_cp.name, ptnrac_phone_1: su_cp.phone, ptnrac_email: su_cp.email)
              end
            end
          end
          supplier_count += 1
          if ((ptnr_mstr.ptnr_upd_date < data_supplier.sent_to_erp) rescue true)
            data_supplier.update_attributes(sent_to_erp: Time.now())
          end
        end
        print supplier_count.to_s + " data telah ditransfer"
      end
    else
      print "Koneksi ke database server, gagal, tunda transfer data.."
    end
  end

  def self.import_data_to_other_database_retur
    begin
      unless DatabaseLain.connected? 
        DatabaseLain.connection
      end
    rescue
      print "failed to connect server database"
    end
    if DatabaseLain.connected?
      returns_to_suppliers = ReturnsToSupplier.all
      unless returns_to_suppliers.present?
        print "Data Retur, telah tertransfer semua.."
      else
        returns_to_suppliers.each do |returns_to_supplier|
          total, total_ppn, total_price = 0, 0, 0
          returns_to_supplier.returns_to_supplier_details.each do |prd|
            product = prd.product
            next if product.blank?
            total_price += prd.subtotal.to_f
            ppn = prd.subtotal*0.1
            total_ppn += ppn if product.flag_pajak == 'BKP' && (returns_to_supplier.supplier.status_pkp rescue false)
          end
          total = total_price + total_ppn
          ptnr_id = PtnrMstr.find_by_ptnr_name(Supplier.find(returns_to_supplier.supplier_id).name).ptnr_id rescue 0
          unless GrMstr.find_by_gr_code(returns_to_supplier.number).present?
            gr_mstr = GrMstr.new(gr_oid: SecureRandom.uuid, gr_dom_id: 1, gr_branch_id: 10001, gr_en_id: 1, gr_add_by: "", gr_add_date: DateTime.now, gr_ptnr_id: ptnr_id, gr_code: returns_to_supplier.number, gr_date: returns_to_supplier.date, gr_tax_basis_amount: -total_price, gr_tax_amount: -total_ppn, gr_total: total, gr_ptnr_code: (Supplier.find(returns_to_supplier.supplier_id).code rescue ""))
            gr_mstr.save
          else
            gr_mstr = GrMstr.find_by_gr_code(returns_to_supplier.number)
            #if ((gr_mstr.gr_upd_date < returns_to_supplier.sent_to_erp) rescue true)
            #  gr_mstr.update_attributes(gr_upd_by: "", gr_upd_date: DateTime.now, gr_ptnr_id: ptnr_id, gr_date: returns_to_supplier.date, gr_tax_basis_amount: -total_price, gr_tax_amount: -total_ppn, gr_total: -total, gr_ptnr_code: Supplier.find(returns_to_supplier.supplier_id).code)
            #end
          end
          #if ((gr_mstr.gr_upd_date < returns_to_supplier.sent_to_erp) rescue true)
          #  returns_to_supplier.update_attributes(sent_to_erp: Time.now())
          #end
        end
      end
    else
      print "Koneksi ke database server, gagal, tunda transfer data.."
    end
  end

  def self.import_data_to_other_database_gr
    begin
      unless DatabaseLain.connected? 
        DatabaseLain.connection
      end
    rescue
      print "failed to connect server database"
    end
    if DatabaseLain.connected?
      receiving_data2 = Receiving.all
      unless receiving_data2.present?
        print "Data GR, telah tertransfer semua.."
      else
        receiving_data2.each do |receiving_data|
          total, total_ppn, total_price = 0, 0, 0
          receiving_data.receiving_details.each do |prd|
            product = prd.product
            next if product.blank?
            total_price += prd.subtotal.to_f
            ppn = prd.subtotal*0.1
            total_ppn += ppn if product.flag_pajak == 'BKP' && receiving_data.supplier.status_pkp
          end
          total = total_price + total_ppn
          ptnr_id = PtnrMstr.find_by_ptnr_name(Supplier.find(receiving_data.supplier_id).name).ptnr_id rescue 0
          unless GrMstr.find_by_gr_code(receiving_data.number).present?
            gr_mstr = GrMstr.new(gr_oid: SecureRandom.uuid, gr_dom_id: 1, gr_branch_id: 10001, gr_en_id: 1, gr_add_by: "", gr_add_date: DateTime.now, gr_ptnr_id: ptnr_id, gr_code: receiving_data.number, gr_date: receiving_data.date, gr_tax_basis_amount: total_price, gr_tax_amount: total_ppn, gr_total: total, gr_ptnr_code: Supplier.find(receiving_data.supplier_id).code)
            gr_mstr.save
          else
            gr_mstr = GrMstr.find_by_gr_code(receiving_data.number)
            #if ((gr_mstr.gr_upd_date < receiving_data.sent_to_erp) rescue true)
            #  gr_mstr.update_attributes(gr_upd_by: "", gr_upd_date: DateTime.now, gr_ptnr_id: ptnr_id, gr_date: receiving_data.date, gr_tax_basis_amount: total_price, gr_tax_amount: total_ppn, gr_total: total, gr_ptnr_code: Supplier.find(receiving_data.supplier_id).code)
            #end
          end
          #if ((gr_mstr.gr_upd_date < receiving_data.sent_to_erp) rescue true)
          #  receiving_data.update_attributes(sent_to_erp: Time.now())
          #end
        end
      end
    else
      print "Koneksi ke database server, gagal, tunda transfer data.."
    end
  end

  def self.import_data_to_other_database_sale
    begin
      unless DatabaseLain.connected? 
        DatabaseLain.connection
      end
    rescue
      print "failed to connect server database"
    end
    if DatabaseLain.connected?
      sales = SodEod.where(session_type: 'DAY')
      if sales.present?
        sales.each do |sale_data|
          slip_code = "SL" + sale_data.office.code + sale_data.sod_eod_date.strftime("%y").to_s + sale_data.sod_eod_date.strftime("%m").to_s + sale_data.sod_eod_date.strftime("%d").to_s
          unless SlipSale.find_by_slip_code(slip_code).present?
            #netSales
            slip_total = sale_data.total_cash_sales
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "S"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Retur
            slip_total = sale_data.retur
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "R"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Retur
            slip_total = sale_data.ppn
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "T"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Cash
            slip_total = sale_data.cash
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "C"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Debit
            slip_total = sale_data.debit
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "E"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Credit
            slip_total = sale_data.credit
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "K"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Voucher
            slip_total = sale_data.voucher
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "V"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Variance
            slip_total = sale_data.difference
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "D"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Promo
            slip_total = sale_data.claim_promo
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "P"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Paid Difference
            slip_total = sale_data.paid_difference
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "I"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
            #Cash Amount
            slip_total = sale_data.actual_end_amount
            unless (slip_total == 0 || slip_total.blank?)
              slip_type = "A"
              slip_mstr = SlipSale.new(slip_oid: SecureRandom.uuid, slip_dom_id: 1, slip_branch_id: 10001, slip_en_id: 1, slip_add_by: (sale_data.user.first_name rescue ""), slip_add_date: DateTime.now, slip_dt: DateTime.now, slip_code: slip_code, slip_date: sale_data.sod_eod_date, slip_type: slip_type, slip_desc: sale_data.office.office_name, slip_total: slip_total)
              slip_mstr.save
            end
          end
        end
      end
    else
      print "Koneksi ke database server, gagal, tunda transfer data.."
    end
  end
end