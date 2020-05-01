class User < ActiveRecord::Base
#  rolify
  has_many :knowledge_details
  has_many :pages, through: :allowable_pages
  has_many :allowable_pages
  has_many :sod_eods

  belongs_to :role
  belongs_to :head_office
  belongs_to :branch

  has_one :office, foreign_key: :contact_person
  has_one :flag_company
  has_one :api_key

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable, :authentication_keys => [:username], :reset_password_keys => [:username, :email]

  attr_accessor :password, :password_confirmation, :remember_me

  validates_confirmation_of :password
  validates_presence_of [:username, :role_id] unless :import
  validates_uniqueness_of [:username, :email]
  validates :head_office_id, presence: true, if: :should_have_head_office_id?
  # validates :branch_id, presence: true, if: :should_have_branch_id?

  before_save :encrypt_password

  def should_have_head_office_id?
#    ![Role::CEO, Role::MANAGER, Role::MEMBER, Role::SUPPLIER, Role::FINANCE, Role::PURCHASE].include?role_id
  end

  def current_offices
    branch_id.blank? ? (head_office_id.blank? ? Office.all : head_office.branches+[head_office]) : [branch]
  end

  def should_have_branch_id?
    ![Role::CEO, Role::MANAGER, Role::HEAD_ADMIN, Role::MEMBER, Role::SUPPLIER].include?role_id
  end

  #head_office_id AND branch_id IS NULL for CEO, Manager, Member, Supplier
  #branch_id IS NULL for Head Admin

=begin
[['Master Data', ['Manage Supplier', 'View Supplier', 'Manage Brand', 'View Brand', 'Manage Colour', 'View Colour', 'Manage Size', 'View Size', 'Manage Department', 'View Department',
  'Manage M-Class', 'View M-Class', 'Manage Member', 'View Member', 'Manage Unit', 'View Unit', 'Manage Bank', 'View Bank', 'Manage HO', 'View HO', 'Manage Branch', 'View Branch',
  'Manage Voucher', 'View Voucher', 'Manage Promo', 'View Promo']], ['Inventory', ['Manage Product', 'View Product', 'Daftar Barang Kosong & Min Stock', 'Cek Stock Semua Cabang',
  'Manage Stock Opname', 'View Stock Opname', 'Manage Transfer Barang', 'View Transfer Barang']], ['Purchasing', ['Manage Purchase Requisition', 'View Purchase Requisition',
  'Manage Purchase Order', 'View Purchase Order', 'Manage Receiving', 'View Receiving', 'Manage Return to Supplier', 'View Return to Supplier', 'Manage Return to HO',
  'View Return to HO', 'Manage Distribusi Barang', 'View Distribusi Barang']], ['Finance', ['Manage Petty Cash', 'View Petty Cash', 'Manage Account Payable', 'View Account Payable',
  'Manage Account Receivable', 'View Account Receivable'], ['Setting', ['Manage User', 'View User', 'Manage Role', 'View Role'], ['Dashboard', ['Live Report']]]]].each{|feature|
=end

  #http://localhost:3000/products?locale=en
  def can_view_price_tag?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRICE_TAG, role_id)
  end

  def can_manage_price_tag?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRICE_TAG, role_id)
  end

  def can_view_inventory_request?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_INVENTORY_REQUEST, role_id)
  end

  def can_view_product_structure?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_STRUCTURE, role_id)
  end

  def can_manage_product_structure?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRODUCT_STRUCTURE, role_id)
  end

  def can_view_product_convertion?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_CONVERTION, role_id)
  end

  def can_manage_product_convertion?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRODUCT_CONVERTION, role_id)
  end

  def can_view_inventory_receipt?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_INVENTORY_RECEIPT, role_id)
  end

  def can_view_location?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_LOCATION, role_id)
  end

  def can_view_pl_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::PROFIT_LOST_REPORT, role_id)
  end
  def can_view_sales_online_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::SALES_ONLINE_REPORT, role_id)
  end

  def can_view_product?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT, role_id)
  end

  def can_view_product_supplier?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_SUPPLIER, role_id)
  end

  def can_view_regional?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_REGIONAL  , role_id)
  end

  def can_manage_regional?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_REGIONAL, role_id)
  end

  def can_view_ap_invoice?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_AP_INVOICE  , role_id)
  end

  def can_manage_ap_invoice?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_AP_INVOICE, role_id)
  end

  def can_view_city?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_CITY, role_id)
  end

  def can_view_warehouse?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_WAREHOUSE, role_id)
  end

  def can_manage_city?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_CITY, role_id)
  end

  def can_view_area?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_AREA, role_id)
  end

  def can_manage_area?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_AREA, role_id)
  end

  def can_view_planogram?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PLANOGRAM, role_id)
  end

  def can_view_planogram_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::PLANOGRAM_REPORT, role_id)
  end

  def can_manage_planogram?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PLANOGRAM, role_id)
  end

  def can_view_unsold_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_UNSOLD_REPORT, role_id)
  end

  def can_view_best_seller_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_BEST_SELLER_REPORT, role_id)
  end

  def can_view_store_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_STORE_REPORT, role_id)
  end

  def can_view_product_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_REPORT, role_id)
  end

  def can_view_supplier_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_SUPPLIER_REPORT, role_id)
  end

  def can_view_stock_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_STOCK_REPORT, role_id)
  end

  def can_view_cashier_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_CASHIER_REPORT, role_id)
  end

  def can_view_sales_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_SALES_REPORT, role_id)
  end

  def can_view_cancel_item_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_CANCEL_ITEM_REPORT, role_id)
  end

  def can_view_profit_and_lost_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PROFIT_AND_LOST_REPORT, role_id)
  end

  def can_view_product_movement_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_MOVEMENT_REPORT, role_id)
  end

  def can_view_product_margin?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_MARGIN, role_id)
  end

  def can_manage_product_margin?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRODUCT_MARGIN  , role_id)
  end

  def can_view_empty_stock?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_EMPTY_STOCK, role_id)
  end

  def can_view_min_stock?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_MIN_STOCK, role_id)
  end

  def can_view_stock_all_branches?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_STOCK_ALL_BRANCHES, role_id)
  end

  def can_view_stock_opname?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_STOCK_OPNAME, role_id)
  end

  def can_view_goods_transfer?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_GOOD_TRANSFER, role_id)
  end

  def can_view_stock_transfer?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_STOCK_TRANSFER, role_id)
  end

  def can_view_transfer_receipt?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_TRANSFER_RECEIPT, role_id)
  end

  def can_view_inventory?
    can_view_product? || can_view_empty_stock? || can_view_min_stock? || can_view_stock_all_branches? || can_view_stock_opname? || can_view_goods_transfer? || can_view_stock_transfer? || can_view_transfer_receipt? || can_view_inventory_request?
  end

  def can_manage_product?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRODUCT, role_id)
  end

  def can_view_mobile_order?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_MOBILE_ORDER, role_id)
  end

  def can_view_selling_price?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_SELLING_PRICE, role_id)
  end

  def can_view_purchase_price?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PURCHASE_PRICE, role_id)
  end

  def can_manage_purchase_price?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PURCHASE_PRICE, role_id)
  end

  def can_view_brd_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_BRD, role_id)
  end

  def can_view_dashboard?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_DASHBOARD, role_id)
  end

  def can_manage_selling_price?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_SELLING_PRICE, role_id)
  end

  def can_view_order?
    can_view_mobile_order?
  end

  def can_manage_unit?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_UNIT, role_id)
  end

  def can_manage_stock_opname?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_STOCK_OPNAME, role_id)
  end

  def can_manage_product_mutation?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRODUCT_MUTATION, role_id)
  end

  def can_manage_stock_mutation?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_STOCK_MUTATION, role_id)
  end

  def can_manage_mutation_receipt?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_MUTATION_RECEIPT, role_id)
  end

  def can_view_user?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_USER, role_id)
  end

  def can_view_to_do_list?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_TO_DO_LIST, role_id)
  end

  def can_manage_to_do_list?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_TO_DO_LIST, role_id)
  end

  def can_view_role?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_ROLE, role_id)
  end

  def can_view_setting?
    can_view_user? || can_view_role?
  end

  def can_manage_sync_product?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_SYNC_PRODUCT, role_id)
  end

  def can_manage_user?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_USER, role_id)
  end

  def can_manage_role?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_ROLE, role_id)
  end

  def can_view_supplier?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_SUPPLIER, role_id)
  end

  def can_view_brand?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_BRAND, role_id)
  end

  def can_view_colour?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_COLOUR, role_id)
  end

  def can_view_size?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_SIZE, role_id)
  end

  def can_view_department?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_DEPARTMENT, role_id)
  end

  def can_view_ad?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_AD, role_id)
  end

  def can_view_mclass?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_MCLASS, role_id)
  end

  def can_view_member?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_MEMBER, role_id)
  end

  def can_view_member_level?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_MEMBER, role_id)
  end

  def can_view_unit?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_UNIT, role_id)
  end

  def can_view_pos_machine?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_POS_MACHINE, role_id)
  end

  def can_view_bank?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_BANK, role_id)
  end

  def can_view_ho?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_HO, role_id)
  end

  def can_view_branch?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_BRANCH, role_id)
  end

  def can_view_voucher?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_VOUCHER, role_id)
  end

  def can_view_promo?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PROMO, role_id)
  end

  def can_view_ar_voucher?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_AR_VOUCHER, role_id)
  end

  def can_view_master_data?
    can_view_supplier? || can_view_brand? || can_view_colour? || can_view_size? || can_view_department? || can_view_mclass? || can_view_member? || can_view_unit? || can_view_bank? || can_view_ho? || can_view_branch? || can_view_voucher? || can_view_promo? || can_view_ar_voucher?
  end

  def can_view_pr?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PR, role_id)
  end

  def can_view_po?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PO, role_id)
  end

  def can_view_receiving?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_RECEIVING, role_id)
  end

  def can_view_product_transfer?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PRODUCT_TRANSFER, role_id)
  end

  def can_view_return_to_ho?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_RETURN_TO_HO, role_id)
  end

  def can_view_return_to_ho_receipt?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_RETURN_TO_HO_RECEIPT, role_id)
  end

  def can_view_return_to_supplier?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_RETURN_TO_SUPPLIER, role_id)
  end

  def can_view_purchase?
    can_view_pr? || can_view_po? || can_view_receiving? || can_view_product_transfer? || can_view_return_to_ho? || can_view_return_to_supplier?
  end

  def can_manage_pr?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PR, role_id)
  end

  def can_manage_ad?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_AD, role_id)
  end

  def can_manage_pos_machine?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_POS_MACHINE, role_id)
  end

  def can_manage_voucher?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_VOUCHER, role_id)
  end

  def can_manage_department?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_DEPARTMENT, role_id)
  end

  def can_manage_branch?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_BRANCH, role_id)
  end

  def can_manage_ho?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_HO, role_id)
  end

  def can_manage_po?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PO, role_id)
  end

  def can_manage_receiving?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_RECEIVING, role_id)
  end

  def can_manage_product_transfer?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PRODUCT_TRANSFER, role_id)
  end

  def can_manage_supplier?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_SUPPLIER, role_id)
  end

  def can_manage_promo?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PROMO, role_id)
  end

  def can_manage_return_to_supplier?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_RETURN_TO_SUPPLIER, role_id)
  end

  ######  Finance ######
  def can_view_account_payable?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_ACCOUNT_PAYABLE, role_id)
  end

  def can_manage_account_payable?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_ACCOUNT_PAYABLE, role_id)
  end

  def can_view_account_receivable?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_ACCOUNT_RECEIVABLE, role_id)
  end

  def can_manage_account_receivable?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_ACCOUNT_RECEIVABLE, role_id)
  end

  def can_view_budget?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_BUDGETING, role_id)
  end

  def can_manage_budget?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_BUDGETING, role_id)
  end

  def can_view_forecast?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_FORECAST, role_id)
  end

  def can_manage_forecast?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_FORECAST, role_id)
  end

  def can_view_petty_cash?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_PETTY_CASH, role_id)
  end

  def can_manage_petty_cash?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_PETTY_CASH, role_id)
  end

  def can_view_sod_eod?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_SOD_EOD, role_id)
  end

  def can_manage_sod_eod?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_SOD_EOD, role_id)
  end

  def can_manage_return_to_ho?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_RETURN_TO_HO, role_id)
  end

  def can_manage_brand?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_BRAND, role_id)
  end

  def can_manage_colour?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_BRAND, role_id)
  end

  def can_manage_size?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_SIZE, role_id)
  end

  def can_manage_warehouse?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_WAREHOUSE, role_id)
  end

  def can_manage_mclass?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_M_CLASS, role_id)
  end

  def can_manage_member?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_MEMBER, role_id)
  end

  def can_manage_member_level?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_MEMBER, role_id)
  end

  def can_manage_bank?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_MEMBER, role_id)
  end

  def can_manage_ar_voucher?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::MANAGE_MEMBER, role_id)
  end

  ###### Finance Report ######
  def can_manage_bank_out_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::BANK_OUT_REPORT, role_id)
  end

  def can_manage_cash_out_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::CASH_OUT_REPORT, role_id)
  end

  def can_manage_global_finance_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::GLOBAL_FINANCE_REPORT, role_id)
  end

  def can_manage_journal_memo_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::JOURNAL_MEMO_REPORT, role_id)
  end

  def can_manage_account_payable_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::ACCOUNT_PAYABLE_REPORT, role_id)
  end

  def can_manage_store_cash_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::STORE_CASH_REPORT, role_id)
  end

  def can_manage_receivable_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::RECEIVABLE_REPORT, role_id)
  end

  def can_manage_repayment_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::REPAYMENT_REPORT, role_id)
  end

  def can_manage_denomination_report?
    Feature.find_by_feature_name_id_and_role_id(FeatureName::DENOMINATION_REPORT, role_id)
  end

  def office_id
    branch_id || head_office_id
  end

  def can_view_live_report
    Feature.find_by_feature_name_id_and_role_id(FeatureName::VIEW_LIVE_REPORT)
  end

  def offices
    return [branch] if branch.present?
    return head_office.branches+[head_office] if head_office.present?
    Office.all
  end

  def encrypt_password
    if password.present?
      self.encrypted_password = BCrypt::Password.create(password)
    end
  end

  def fullname
    [first_name, last_name].join(' ')
  end

  def self.set_per_page(number)
    self.per_page = number
  end

  def company_code
   company = organization.company rescue nil
   "#{company.created_at.strftime("%Y%m%d%H%M%S")}#{company.id}" rescue ''
  end

  def name
    if self.first_name.present? and self.last_name.present?
  	  self.first_name + " " + self.last_name
    else
      return ''
    end
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["Nama Depan", "Nama Belakang", "Username", "Role", "Status", "Email", "Password", "Office", "Store"]
      all.each do |user|
        role = user.role.name rescue ''
        head_office = user.head_office.office_name rescue ''
        branch = user.branch.office_name rescue ''
        csv << [user.first_name, user.last_name, user.username, role, user.status, user.email, user.password, head_office, branch]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["Nama Depan", "Nama Belakang", "Username", "Role", "Status", "Email", "Password", "Office", "Store"]
      all.each do |user|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_username(row["Username"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        user = new(parameters.permit().merge(
          first_name: row["Nama Depan"], last_name: row["Nama Belakang"], username: row["Username"], role_id: (Role.find_by_name(row["Role"]).id rescue 0), status: row["Status"], email: row["Email"],
          password: row["Password"], pos_password: row["Password"], head_office_id: (HeadOffice.find_by_office_name(row["Office"]).id rescue 0), branch_id: (Branch.find_by_office_name(row["Store"]).id rescue 0)
        ))
        user.skip_confirmation!
        unless user.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{user.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{user.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
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

  def self.current
    Thread.current[:user]
  end

  def self.current=(user)
    Thread.current[:user] = user
  end

  private
    def build_default_flag
      # build_flag_company
    end
end
