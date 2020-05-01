['Super User'].each{|role|
  role = Role.where(name: role.titleize).first_or_create
}

['Adrian'].each_with_index{|user, i|
  User.create(first_name: user.split(' ')[0], last_name: user.split(' ')[1], gender: i < 1 ? 'Male' : 'Female', birth_place: "hometown", birth_date: "1992-12-12 00:00:00",
    email: "#{user.gsub(' ', '')}@gmail.com", status: "active", confirmed_at: Time.now, username: user.gsub(' ', '_').downcase, password: '12345678', role_id: i+1,
    pos_password: Digest::MD5.hexdigest('12345678')
  )
}

FeatureName.delete_all
[{"id"=>1, "name"=>"View Product", "module_name"=>"Master Data"}, {"id"=>2, "name"=>"Daftar Barang Kosong", "module_name"=>"Inventory"}, {"id"=>3, "name"=>"Min Stock", "module_name"=>"Inventory"},
  {"id"=>4, "name"=>"Cek Stock Semua Cabang", "module_name"=>"Inventory"}, {"id"=>5, "name"=>"View Stock Opname", "module_name"=>"Inventory"}, {"id"=>9, "name"=>"Manage Product",
  "module_name"=>"Master Data"}, {"id"=>10, "name"=>"Manage Stock Opname", "module_name"=>"Inventory"}, {"id"=>15, "name"=>"View Purchase Requisition", "module_name"=>"Purchase"}, {"id"=>16,
  "name"=>"View Purchase Order", "module_name"=>"Purchase"}, {"id"=>17, "name"=>"View Receiving", "module_name"=>"Purchase"}, {"id"=>18, "name"=>"View Return to Supplier", "module_name"=>"Purchase"}, {"id"=>21,
  "name"=>"Manage Purchase Requisition", "module_name"=>"Purchase"}, {"id"=>22, "name"=>"Manage Purchase Order", "module_name"=>"Purchase"}, {"id"=>23, "name"=>"Manage Receiving", "module_name"=>"Purchase"},
  {"id"=>24, "name"=>"Manage Return to Supplier", "module_name"=>"Purchase"}, {"id"=>37, "name"=>"View Supplier", "module_name"=>"Master Data"}, {"id"=>41, "name"=>"View Department",
  "module_name"=>"Master Data"}, {"id"=>42, "name"=>"View M-Class", "module_name"=>"Master Data"}, {"id"=>43, "name"=>"View Member", "module_name"=>"Master Data"}, {"id"=>44, "name"=>"View Unit",
  "module_name"=>"Master Data"}, {"id"=>47, "name"=>"View Store", "module_name"=>"Master Data"}, {"id"=>50, "name"=>"Manage Supplier", "module_name"=>"Master Data"}, {"id"=>54, "name"=>"Manage Department",
  "module_name"=>"Master Data"}, {"id"=>55, "name"=>"Manage M-Class", "module_name"=>"Master Data"}, {"id"=>56, "name"=>"Manage Member", "module_name"=>"Master Data"}, {"id"=>57, "name"=>"Manage Unit",
  "module_name"=>"Master Data"}, {"id"=>59, "name"=>"Manage HO", "module_name"=>"Master Data"}, {"id"=>60, "name"=>"Manage Store", "module_name"=>"Master Data"}, {"id"=>65, "name"=>"View User",
  "module_name"=>"Setting"}, {"id"=>66, "name"=>"View Role", "module_name"=>"Setting"}, {"id"=>67, "name"=>"Manage User", "module_name"=>"Setting"}, {"id"=>68, "name"=>"Manage Role", "module_name"=>"Setting"},
  {"id"=>69, "name"=>"Inventory Report", "module_name"=>"Report"}, {"id"=>70, "name"=>"Purchase Report", "module_name"=>"Report"}, {"id"=>71, "name"=>"Finance Report", "module_name"=>"Report"},
  {"id"=>74, "name"=>"Live Report", "module_name"=>"Report"}, {"id"=>80, "name"=>"View Regional", "module_name"=>"Master Data"}, {"id"=>81, "name"=>"Manage Regional", "module_name"=>"Master Data"},
  {"id"=>82, "name"=>"View Branch", "module_name"=>"Master Data"}, {"id"=>83, "name"=>"Manage Branch", "module_name"=>"Master Data"}, {"id"=>84, "name"=>"View Area", "module_name"=>"Master Data"},
  {"id"=>85, "name"=>"Manage Area", "module_name"=>"Master Data"}, {"id"=>88, "name"=>"View Unsold Report", "module_name"=>"Report"}, {"id"=>89, "name"=>"View Best Seller Report", "module_name"=>"Report"},
  {"id"=>90, "name"=>"View Store Report", "module_name"=>"Report"}, {"id"=>91, "name"=>"View Product Report", "module_name"=>"Report"}, {"id"=>92, "name"=>"View Supplier Report", "module_name"=>"Report"},
  {"id"=>93, "name"=>"View Stock Report", "module_name"=>"Report"}, {"id"=>94, "name"=>"View Cashier Report", "module_name"=>"Report"}, {"id"=>95, "name"=>"View Product Movement Report",
  "module_name"=>"Report"}, {"id"=>96, "name"=>"View Cancel Item Report", "module_name"=>"Report"}, {"id"=>97, "name"=>"View Sales Report", "module_name"=>"Report"}, {"id"=>98, "name"=>"View Inventory Request",
  "module_name"=>"Inventory"}, {"id"=>103, "name"=>"View Planogram", "module_name"=>"Master Data"}, {"id"=>104, "name"=>"Manage Planogram", "module_name"=>"Master Data"}, {"id"=>32, "name"=>"Manage Petty Cash",
  "module_name"=>"Finance"}, {"id"=>27, "name"=>"View Petty Cash", "module_name"=>"Finance"}, {"id"=>102, "name"=>"View Price Tag", "module_name"=>"Master Data"}, {"id"=>105, "name"=>"View Price Tag",
  "module_name"=>"Master Data"}, {"id"=>113, "name"=>"View Product Supplier", "module_name"=>"Master Data"}, {"id"=>122, "name"=>"View Selling Price", "module_name"=>"Master Data"}, {"id"=>123,
  "name"=>"Manage Selling Price", "module_name"=>"Master Data"}, {"id"=>125, "name"=>"View Dashboard", "module_name"=>"Dashboard"}].each{|a|
  FeatureName.create a
}
FeatureName.all.each{|fn|
  Feature.create feature_name_id: fn.id, role_id: Role.first.id
}
Entity.create logo: "lotte.jpg", name: nil, address: nil, npwp: nil, npwp_address: nil, created_at: "2016-06-27 04:02:58", updated_at: "2016-06-29 12:14:11", title: "Lottemart - IMM Back Office", footer: nil, favicon: nil, custom_css: "lotte.css", domain_name: "112.215.62.91:6999"

Entity.create logo: "lotte.jpg", name: nil, address: nil, npwp: nil, npwp_address: nil, created_at: "2016-06-27 04:02:58", updated_at: "2016-06-29 12:14:11", title: "Lottemart - IMM Back Office", footer: nil, favicon: nil, custom_css: "lotte.css", domain_name: "10.167.1.181:6999"

#6999 ganti pake port ybs
