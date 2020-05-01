class Role < ActiveRecord::Base
  has_many :features
  has_many :feature_names, through: :features
#[[1, "CEO"], [2, "Manager"], [3, "Head Admin"], [4, "Inventory"], [5, "Purchase"], [6, "Finance"], [7, "Admin Inventory"], [8, "Admin Purchase"], [9, "Admin Finance"], [10, "Kasir"], [11, "Gudang"], [12, "SPG"], [13, "Member"], [14, "Supplier"]]

  CEO = 1
  MANAGER = 2
  HEAD_ADMIN = 3
  INVENTORY = 4
  PURCHASE = 5
  FINANCE = 6
  ADMIN_INVENTORY = 7
  ADMIN_PURCHASE = 8
  ADMIN_FINANCE = 9
  KASIR = 10
  GUDANG = 11
  SUPPLIER = 14
  MEMBER = 15

  def has_privilege feature
    Feature.find_by_role_id_and_feature_name_id(id, feature.id)
  end

  def generate_accessable_pages
    view_inventory = ['View Product', 'Daftar Barang Kosong', 'Min Stock', 'Cek Stock Semua Cabang', 'View Stock Opname', 'View Mutasi Barang', 'View Mutasi Stock',
      'View Penerimaan Mutasi Barang']
    manage_inventory = ['Manage Product', 'Manage Stock Opname', 'Manage Transfer Barang', 'Manage Mutasi Barang', 'Manage Mutasi Stock', 'Manage Penerimaan Mutasi Barang']
    inventory = view_inventory + manage_inventory

    view_purchase = ['View Purchase Requisition', 'View Purchase Order', 'View Receiving', 'View Return to Supplier', 'View Return to HO', 'View Distribusi Barang']
    manage_purchase = ['Manage Purchase Requisition', 'Manage Purchase Order', 'Manage Receiving', 'Manage Return to Supplier', 'Manage Return to HO', 'Manage Distribusi Barang']
    purchase = view_purchase + manage_purchase

    view_finance = ['View Petty Cash', 'View Account Payable', 'View Account Receivable', 'View Forecast', 'View Budgeting', 'View SOD - EOD']
    manage_finance = ['Manage Petty Cash', 'Manage Account Payable', 'Manage Account Receivable', 'Manage Forecast', 'Manage Budgeting', 'Manage SOD - EOD']
    finance = view_finance + manage_finance

    view_features = view_inventory + view_purchase + view_finance + ['View Supplier', 'View Brand', 'View Role', 'View Size', 'View Department', 'View M-Class', 'View Member',
      'View Unit', 'View Bank', 'View HO', 'View Branch', 'View Voucher', 'View Promo', 'View User', 'View Role', 'Inventory Report', 'Purchase Report', 'Finance Report']
    view_full_features = view_features + ['Live Report']

    if id == CEO
      (view_full_features + manage_inventory + manage_purchase + manage_finance + ['Manage Supplier', 'Manage Brand', 'Manage Role', 'Manage Size', 'Manage Department',
        'Manage M-Class', 'Manage Member', 'Manage Unit', 'Manage Bank', 'Manage HO', 'Manage Branch', 'Manage Voucher', 'Manage Promo', 'Manage AR Voucher', 'View AR Voucher',
        'Manage User', 'Manage Role']).each{|fn|
        Feature.create role_id: id, feature_name_id: FeatureName.where(name: fn).first_or_create.id
      }
    elsif id == MANAGER
      view_full_features.each{|feature_name|
        Feature.create role_id: id, feature_name_id: FeatureName.where(name: feature_name).first_or_create.id
      }
    elsif id == HEAD_ADMIN
      view_features.each{|feature_name|
        Feature.create role_id: id, feature_name_id: FeatureName.where(name: feature_name).first_or_create.id
      }
    elsif [INVENTORY, ADMIN_INVENTORY].include?id
      inventory.each{|feature_name|
        Feature.create role_id: id, feature_name_id: FeatureName.where(name: feature_name, module_name: 'Inventory').first_or_create.id
      }
      Feature.create role_id: id, feature_name_id: FeatureName.where(name: 'Inventory Report', module_name: 'Report').first_or_create.id if id == ADMIN_INVENTORY
    elsif [PURCHASE, ADMIN_PURCHASE].include?id
      purchase.each{|feature_name|
        Feature.create role_id: id, feature_name_id: FeatureName.where(name: feature_name, module_name: 'Purchase').first_or_create.id
      }
      Feature.create role_id: id, feature_name_id: FeatureName.where(name: 'Purchase Report', module_name: 'Report').first_or_create.id if id == ADMIN_PURCHASE
    elsif [FINANCE, ADMIN_FINANCE].include?id
      finance.each{|feature_name|
        Feature.create role_id: id, feature_name_id: FeatureName.where(name: feature_name, module_name: 'Finance').first_or_create.id
      }
      Feature.create role_id: id, feature_name_id: FeatureName.where(name: 'Finance Report', module_name: 'Report').first_or_create.id if id == ADMIN_FINANCE
    elsif [KASIR, SUPPLIER].include?id
      Feature.create role_id: id, feature_name_id: FeatureName.where(name: 'Cek Stock Semua Cabang', module_name: 'Inventory').first_or_create.id
    end
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["Kode", "Nama"]
      all.each do |role|
        csv << [role.code, role.name]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["Nama"]
      all.each do |role|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["Nama"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        role = new(parameters.permit().merge(:code => "R#{('%03d' % ((Role.last.code.gsub('C', '').to_i rescue 0)+1))}", name: row["Nama"]))
        unless role.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{role.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{role.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        #return {error: 0, message: "Successfully imported"}
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

end
