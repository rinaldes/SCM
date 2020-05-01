class Page < ActiveRecord::Base
  has_many :users, through: :allowable_pages
  has_many :allowable_pages

  DASHBOARD = 'Dashboard'
  BRANCH = 'Setting - Branch'
  UNIT = 'Setting - Unit'
  HEAD_OFFICE = 'Setting - Head Office'
  USER = 'Setting - User Setting'
  HEAD_OFFICE_SETTING = 'Setting - Management Head Office'
  BRANCH_SETTING = 'Setting - Management Branch'
  SETTING_PAGES = [UNIT, BRANCH_SETTING, BRANCH, HEAD_OFFICE_SETTING, HEAD_OFFICE, USER]

  SUPPLIER = 'Master - Supplier'
  BRAND = 'Master - Brand'
  COLOUR = 'Master - Colour'
  SIZE = 'Master - Size'
  TYPE = 'Master - Type'
  MEMBER = 'Master - Member'
  BANK = 'Master - Bank'
  GOODS_BRANCH_PRICE = 'Master - Setting Branch Price'
  MASTER_PAGES = [SUPPLIER, SIZE, TYPE, BRAND, COLOUR, MEMBER, BANK, GOODS_BRANCH_PRICE]

  GOODS_STOCK = 'Inventory - Goods Stock'
  EMPTY_STOCK = 'Inventory - Empty Stock'
  ALL_BRANCHES_STOCK = 'Inventory - All Branches Stock'
  GOODS_MOVEMENT = 'Inventory - Goods Movement at Branch'
  GOODS_TRANSFER = 'Inventory - Goods Transfer'
  GOODS_AVAILABILITY = 'Inventory - Goods Availability'
  STOCK_OPNAME = 'Inventory - Stock Opname'
  INVENTORY_PAGES = [GOODS_STOCK, EMPTY_STOCK, ALL_BRANCHES_STOCK, GOODS_TRANSFER, STOCK_OPNAME, GOODS_MOVEMENT, GOODS_AVAILABILITY]

  PURCHASE_ORDER_MASTER = 'Purchase - PO Master'
  PURCHASE_ORDER = 'Purchase - Purchase Order'
  VIEW_RETURN_TO_SUPPLIER = 'Purchase - Return to Supplier (view)'
  CREATE_RETURN_TO_SUPPLIER = 'Purchase - Return to Supplier (create)'
  VIEW_GOODS_ALLOCATION = 'Purchase - Goods Allocation at Warehouse (view)'
  CREATE_GOODS_ALLOCATION = 'Purchase - Goods Allocation at Warehouse (create)'
  GOODS_DISTRIBUTION_RECEIPT = 'Purchase - Goods Distribution Receipt'
  VIEW_GOODS_DISTRIBUTION = 'Purchase - Goods Distribution (view)'
  CREATE_GOODS_DISTRIBUTION = 'Purchase - Goods Distribution (create)'
  VIEW_GOODS_RECEIPT = 'Purchase - Goods Receipt (view)'
  CREATE_GOODS_RECEIPT = 'Purchase - Goods Receipt (create)'
  INSPECT_GOODS_RECEIPT = 'Purchase - Goods Receipt (Inspeksi)'
  VIEW_RETURN_TO_HO = "Purchase - Return to HO (view)"
  CREATE_RETURN_TO_HO = "Purchase - Return to HO (create)"
  RETURN_TO_HO_RECEIPT = "Purchase - Return to HO Receipt"
  PURCHASE_PAGES = [RETURN_TO_HO_RECEIPT, CREATE_RETURN_TO_HO, VIEW_RETURN_TO_HO, PURCHASE_ORDER_MASTER, PURCHASE_ORDER, VIEW_GOODS_RECEIPT,
    CREATE_RETURN_TO_SUPPLIER, VIEW_RETURN_TO_SUPPLIER, VIEW_GOODS_ALLOCATION, GOODS_DISTRIBUTION_RECEIPT, CREATE_GOODS_DISTRIBUTION,
    VIEW_GOODS_DISTRIBUTION, CREATE_GOODS_ALLOCATION, CREATE_GOODS_RECEIPT, INSPECT_GOODS_RECEIPT]

  POS = 'Sale - Sale from POS'
  EXCHANGE = 'Sale - Exchange'
  CREATE_GOODS_REQUEST = 'Sale - Goods Request (create)'
  VIEW_GOODS_REQUEST = 'Sale - Goods Request (view)'
  SALE_PAGES = [POS, EXCHANGE, CREATE_GOODS_REQUEST, VIEW_GOODS_REQUEST]

  STOCK_REPORT = 'Report - Stock Report'
  SALES_REPORT = 'Report - Sale Report'
  REPORT_PAGES = [STOCK_REPORT, SALES_REPORT]

  VIEW_TO_DO_LIST = 'Job Task - To Do List (view)'
  CREATE_TO_DO_LIST = 'Job Task - To Do List (create)'
  JOB_TASK_PAGE = [VIEW_TO_DO_LIST, CREATE_TO_DO_LIST]

  STAF_HO_PURCHASE_PAGE = [PURCHASE_ORDER, PURCHASE_ORDER_MASTER, VIEW_GOODS_RECEIPT, CREATE_GOODS_RECEIPT, CREATE_RETURN_TO_SUPPLIER,
    VIEW_RETURN_TO_SUPPLIER, VIEW_GOODS_DISTRIBUTION, CREATE_GOODS_DISTRIBUTION, VIEW_RETURN_TO_HO, RETURN_TO_HO_RECEIPT,
    INSPECT_GOODS_RECEIPT]
  STAF_HO_ACCESS_PAGE_LIST = MASTER_PAGES + INVENTORY_PAGES + STAF_HO_PURCHASE_PAGE + [POS] + REPORT_PAGES + JOB_TASK_PAGE

  BRANCH_STAFF_PURCHASE_PAGE = [PURCHASE_ORDER, VIEW_GOODS_RECEIPT, VIEW_RETURN_TO_SUPPLIER, GOODS_DISTRIBUTION_RECEIPT, CREATE_RETURN_TO_HO,
    VIEW_GOODS_DISTRIBUTION, VIEW_RETURN_TO_HO, VIEW_GOODS_ALLOCATION, VIEW_RETURN_TO_HO]
  BRANCH_STAFF_PAGE_LIST = BRANCH_STAFF_PURCHASE_PAGE + MASTER_PAGES + INVENTORY_PAGES + [VIEW_GOODS_REQUEST] + REPORT_PAGES + JOB_TASK_PAGE

  SPG_ACCESS_PAGE_LIST = [CREATE_GOODS_REQUEST, VIEW_GOODS_REQUEST]

  HO_STORE_INVENTORY_PAGES = [GOODS_STOCK, EMPTY_STOCK, ALL_BRANCHES_STOCK, STOCK_OPNAME]
  HO_STORE_PURCHASE_PAGES = [CREATE_RETURN_TO_SUPPLIER, VIEW_RETURN_TO_SUPPLIER, VIEW_GOODS_DISTRIBUTION, CREATE_GOODS_DISTRIBUTION,
    VIEW_RETURN_TO_HO, RETURN_TO_HO_RECEIPT, VIEW_GOODS_RECEIPT, INSPECT_GOODS_RECEIPT]
  HO_STORE_PAGES_LIST = HO_STORE_INVENTORY_PAGES + HO_STORE_PURCHASE_PAGES + [STOCK_REPORT]

  BRANCH_STORE_INVENTORY_PAGES = [GOODS_STOCK, EMPTY_STOCK, ALL_BRANCHES_STOCK, GOODS_TRANSFER, STOCK_OPNAME, GOODS_MOVEMENT]
  BRANCH_STORE_PURCHASE_PAGES = [CREATE_RETURN_TO_HO, VIEW_RETURN_TO_HO, VIEW_GOODS_ALLOCATION, CREATE_GOODS_ALLOCATION]
  BRANCH_STORE_SALE_PAGES = [EXCHANGE, VIEW_GOODS_REQUEST]
  BRANCH_STORE_PAGES_LIST = BRANCH_STORE_INVENTORY_PAGES + BRANCH_STORE_PURCHASE_PAGES + BRANCH_STORE_SALE_PAGES + [STOCK_REPORT,
    VIEW_TO_DO_LIST]

  def self.setting_detail_page
    {UNIT => ['units#index'], HEAD_OFFICE => ['head_offices#user_head_offices', 'head_offices#edit_user', 'head_offices#connect',
      'head_offices#index', 'head_offices#create', 'head_offices#new', 'head_offices#edit', 'head_offices#show', 'head_offices#update',
      'head_offices#destroy']}
  end

  def self.sell_detail_page
    {EXCHANGE => ['exchange_datas#index'], POS => ['point_of_sales#filter', 'point_of_sales#index'],
      CREATE_GOODS_REQUEST => ['size_details#autocomplete_size_detail_size_number', 'goods_sizes#filter_goods_with_prices',
      'autocompletes#autocomplete_type_name', 'goods_requests#save_request', 'goods_requests#cari_size', 'goods_requests#search_goods',
      'goods_requests#find_goods_to_selected', 'goods_requests#create', 'goods_requests#new'],
      VIEW_GOODS_REQUEST => ['goods_requests#index', 'goods_requests#show']}
  end

  def self.purchase_detail_page
    {PURCHASE_ORDER_MASTER => ['composite_purchase_orders#filter_po',
      'size_details#autocomplete_size_detail_size_number', 'composite_purchase_orders#autocomplete_composite_purchase_order_number_pendings',
      'composite_purchase_orders#close_po', 'composite_purchase_orders#index', 'composite_purchase_orders#create',
      'composite_purchase_orders#new', 'composite_purchase_orders#show', 'autocompletes#autocomplete_type_name',
      'goods_sizes#filter_goods_with_prices', 'purchase_orders#view_stock'], VIEW_RETURN_TO_HO => ['returns_to_head_offices#show',
      'returns_to_head_offices#index'], RETURN_TO_HO_RECEIPT => ['returns_to_head_offices#update', 'returns_to_head_offices#edit',
      'returns_to_head_offices#mark_as_received', 'returns_to_head_offices#add_by_barcode_edit'],
      CREATE_RETURN_TO_HO => ['returns_to_head_offices#new', 'returns_to_head_offices#create', 'returns_to_head_offices#add_by_barcode'],
      CREATE_RETURN_TO_SUPPLIER => ['autocompletes#autocomplete_goods_size_barcode', 'purchase_orders#view_stock',
      'returns_to_suppliers#scanner_barcode', 'returns_to_suppliers#mark_as_delivered', 'returns_to_suppliers#add_by_barcode',
      'returns_to_suppliers#create', 'returns_to_suppliers#new', 'returns_to_suppliers#edit', 'returns_to_suppliers#update'],
      VIEW_RETURN_TO_SUPPLIER => ['returns_to_suppliers#index', 'returns_to_suppliers#show']}
  end

  def self.report_detail_page
    {STOCK_REPORT => ['reports#stock', 'reports#filter_stock', 'autocompletes#autocomplete_supplier_name',
      'autocompletes#autocomplete_brand_name', 'autocompletes#autocomplete_colour_name'],
      SALES_REPORT => ['reports#sales', 'reports#filter_sales', 'autocompletes#autocomplete_supplier_name',
      'autocompletes#autocomplete_brand_name', 'autocompletes#autocomplete_type_name']}
  end

  def self.inventory_detail_page
    {STOCK_OPNAME => ['autocompletes#autocomplete_goods_size_barcode', 'autocompletes#autocomplete_stock_opname_number',
      'autocompletes#autocomplete_store_name', 'autocompletes#autocomplete_user_name', 'stock_opnames#show', 'stock_opnames#new',
      'stock_opnames#create', 'stock_opnames#index', 'stock_opnames#import_packing_list', 'stock_opnames#buka_gudang',
      'stock_opnames#add_by_barcode', 'stock_opnames#get_stock', 'to_excel_example', 'stock_opnames#form_import_packing_list',
      'stock_opnames#search'], GOODS_STOCK => ['autocompletes#autocomplete_supplier_name',
      'autocompletes#autocomplete_brand_name_and_supplier', 'goods#stock_branch', 'autocompletes#autocomplete_brand_name',
      'autocompletes#autocomplete_type_name', 'autocompletes#autocomplete_colour_name', 'goods#history_pmb', 'goods#add', 'goods#show',
      'goods#scan_manual', 'goods#scan_barcode', 'goods#update_goods_stock', 'goods#destroy_goods_stock', 'goods#filter_goods',
      'goods#search_purchase_price_after_discount', 'goods#print_barcode', 'goods#get_sales_data', 'goods#create', 'goods#get_pmb_data',
      'goods#new'], EMPTY_STOCK => ['goods#index'], ALL_BRANCHES_STOCK => ['autocompletes#autocomplete_brand_name',
      'autocompletes#autocomplete_type_name', 'goods#all_branches_stock', 'autocompletes#autocomplete_colour_name', 'goods#search_by_data',
      'goods#branch_stock']}
  end

  def self.detail_page
    {GOODS_AVAILABILITY => ['goods#check_goods'], VIEW_GOODS_RECEIPT => ['goods_receipts#index', 'goods_receipts#show'],
      CREATE_GOODS_RECEIPT => ['size_details#autocomplete_size_detail_size_number', 'goods_receipts#search_barcode',
      'goods_receipts#search_po', 'goods_receipts#collect_goods', 'goods_receipts#new', 'goods_receipts#goods_filter_to_table_selected',
      'goods_receipts#create', 'autocompletes#autocomplete_type_name', 'goods_sizes#filter_goods_with_prices',
      'purchase_orders#search_goods'], INSPECT_GOODS_RECEIPT => ['goods_receipts#mark_as_inspected', 'goods_receipts#index',
      'goods_receipts#show'], VIEW_TO_DO_LIST => ['to_do_lists#new', 'to_do_lists#show_status_to_do'],
      CREATE_TO_DO_LIST => ['to_do_lists#new', 'to_do_lists#show_status_to_do', 'to_do_lists#index', 'to_do_lists#show', 'to_do_lists#update_status'],
      PURCHASE_ORDER => ['size_details#autocomplete_size_detail_size_number',
      'autocompletes#autocomplete_type_name', 'purchase_orders#show', 'goods_sizes#filter_goods_with_prices', 'purchase_orders#search_goods',
      'purchase_orders#view_stock', 'purchase_orders#index', 'purchase_orders#edit', 'purchase_orders#new', 'purchase_orders#create',
      'purchase_orders#search', 'purchase_orders#search_po', 'purchase_orders#update_po', 'purchase_orders#search_image',
      'purchase_orders#preview', 'purchase_orders#search_goods', 'purchase_orders#search_size'], SUPPLIER => ['suppliers#update',
      'suppliers#show', 'suppliers#edit', 'suppliers#create', 'suppliers#index', 'suppliers#search', 'suppliers#get_number'],
      BRAND => ['brands#destroy', 'brands#update', 'brands#show', 'brands#edit', 'brands#new', 'brands#create', 'brands#index'],
      COLOUR => ['colours#search', 'colours#autocomplete_colour_name', 'colours#index', 'colours#create', 'colours#new', 'colours#edit',
      'colours#show', 'colours#update', 'colours#destroy'], SIZE => ['sizes#destroy', 'sizes#update', 'sizes#show', 'sizes#new',
      'sizes#edit', 'sizes#create', 'sizes#index', 'sizes#search'], TYPE => ['types#search', 'types#index', 'types#create', 'types#new',
      'types#edit', 'types#show', 'types#update', 'types#destroy'], MEMBER => ['members#search', 'members#index', 'members#new',
      'members#create', 'members#edit', 'members#show', 'members#update', 'members#destroy'], BANK => ['edc_machines#index',
      'edc_machines#edit', 'edc_machines#create', 'edc_machines#update', 'edc_machines#destroy'],
      VIEW_GOODS_ALLOCATION => ['goods_allocations#show', 'goods_allocations#index'],
      GOODS_DISTRIBUTION_RECEIPT => ['goods_distribution_branches#autocomplete_goods_distribution_branch_receipt_number',
      'goods_distribution_branches#edit', 'goods_distribution_branches#update', 'goods_distributions#edit', 'goods_distributions#update'],
      VIEW_GOODS_DISTRIBUTION => ['goods_distributions#index'], CREATE_GOODS_ALLOCATION => ['goods_allocations#new',
      'goods_allocations#goods_distribution', 'goods_allocations#search_distribution', 'goods_allocations#create'],
      CREATE_GOODS_DISTRIBUTION => ['goods_distributions#search_pmb', 'goods_distributions#search_barcode_from_pmb',
      'goods_distributions#barcode_scanned', 'goods_distributions#preview', 'goods_distributions#get_goods_have_stock_in_storage_ho',
      'goods_distributions#get_goods_wihout_pmb', 'goods_distributions#search_pmb_barcode', 'goods_distributions#create',
      'goods_distributions#new', 'goods_distributions#edit'], GOODS_MOVEMENT => ['goods_movements#search_goods', 'goods_movements#index',
      'goods_movements#create', 'goods_movements#show'], GOODS_TRANSFER => ['goods_transfers#search_goods', 'goods_transfers#collect_stores',
      'goods_transfers#index', 'goods_transfers#create', 'goods_transfers#new', 'goods_transfers#edit', 'goods_transfers#show',
      'goods_transfers#update']}.merge(Page.setting_detail_page).merge(Page.sell_detail_page).merge(Page.purchase_detail_page)
      .merge(Page.report_detail_page).merge(Page.inventory_detail_page)
  end
end
