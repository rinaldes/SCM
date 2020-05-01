#reset transaction
ActiveRecord::Base.connection.execute(
  "TRUNCATE TABLE stock_opnames, stock_opname_details, receivings, receiving_details, product_mutations, product_mutation_details, product_mutation_histories, sales, sales_details RESTART IDENTITY;
  UPDATE product_details SET available_qty=0, allocated_qty=0, freezed_qty=0, rejected_qty=0, defect_qty=0, online_qty=0;"
)
ActiveRecord::Base.connection.execute("TRUNCATE TABLE purchase_orders, purchase_order_details RESTART IDENTITY")

#Start reset master data
#-------=======-------=======-------=======-------

#reset category
ActiveRecord::Base.connection.execute("TRUNCATE TABLE m_classes RESTART IDENTITY")

#reset supplier
ActiveRecord::Base.connection.execute("TRUNCATE TABLE suppliers, bank_accounts, contact_people RESTART IDENTITY")

#reset product
ActiveRecord::Base.connection.execute("TRUNCATE TABLE brands, selling_prices, product_suppliers, products, product_sizes, product_details, skus RESTART IDENTITY")

#-------=======-------=======-------=======-------
#End reset master data


#Start reset setting
#-------=======-------=======-------=======-------

ActiveRecord::Base.connection.execute("TRUNCATE TABLE features, feature_names RESTART IDENTITY;")
ActiveRecord::Base.connection.execute("TRUNCATE TABLE users, roles RESTART IDENTITY;")

#-------=======-------=======-------=======-------
#End reset setting


#-------=======Initial Data Start=======-------

['Super Admin', 'Kasir'].each{|role|
  role = Role.where(name: role.titleize).first_or_create
#  role.generate_accessable_pages
}

['Daryn Admin', 'Daryn'].each_with_index{|user, i|
  User.create(first_name: user.split(' ')[0], last_name: user.split(' ')[1], gender: i < 1 ? 'Male' : 'Female', birth_place: "hometown", birth_date: "1992-12-12 00:00:00",
    email: "#{user.gsub(' ', '')}@gmail.com", status: "active", confirmed_at: Time.now, username: user.gsub(' ', '_').downcase, password: '12345678', role_id: i+1,
    pos_password: Digest::MD5.hexdigest('12345678')
  )
}

[{"id"=>1, "name"=>"View Product", "module_name"=>"Inventory"}, {"id"=>4, "name"=>"Cek Stock", "module_name"=>"Inventory"}, {"id"=>5, "name"=>"View Stock Opname", "module_name"=>"Inventory"},
  {"id"=>9, "name"=>"Manage Product", "module_name"=>"Inventory"}, {"id"=>10, "name"=>"Manage Stock Opname", "module_name"=>"Inventory"}, {"id"=>17, "name"=>"View Receiving", "module_name"=>"Purchase"},
  {"id"=>23, "name"=>"Manage Receiving", "module_name"=>"Purchase"}, {"id"=>37, "name"=>"View Supplier", "module_name"=>"Master Data"}, {"id"=>38, "name"=>"View Brand", "module_name"=>"Master Data"},
  {"id"=>41, "name"=>"View Department", "module_name"=>"Master Data"}, {"id"=>42, "name"=>"View M-Class", "module_name"=>"Master Data"}, {"id"=>43, "name"=>"View Member", "module_name"=>"Master Data"},
  {"id"=>44, "name"=>"View Unit", "module_name"=>"Master Data"}, {"id"=>45, "name"=>"View Bank", "module_name"=>"Master Data"}, {"id"=>50, "name"=>"Manage Supplier", "module_name"=>"Master Data"},
  {"id"=>51, "name"=>"Manage Brand", "module_name"=>"Master Data"}, {"id"=>54, "name"=>"Manage Department", "module_name"=>"Master Data"}, {"id"=>55, "name"=>"Manage M-Class", "module_name"=>"Master Data"},
  {"id"=>56, "name"=>"Manage Member", "module_name"=>"Master Data"}, {"id"=>57, "name"=>"Manage Unit", "module_name"=>"Master Data"}, {"id"=>58, "name"=>"Manage Bank", "module_name"=>"Master Data"},
  {"id"=>63, "name"=>"Manage AR Voucher", "module_name"=>"Master Data"}, {"id"=>64, "name"=>"View AR Voucher", "module_name"=>"Master Data"}, {"id"=>65, "name"=>"View User", "module_name"=>"Setting"},
  {"id"=>66, "name"=>"View Role", "module_name"=>"Setting"}, {"id"=>67, "name"=>"Manage User", "module_name"=>"Setting"}, {"id"=>68, "name"=>"Manage Role", "module_name"=>"Setting"},
  {"id"=>88, "name"=>"View Unsold Report", "module_name"=>"Report"}, {"id"=>93, "name"=>"View Stock Report", "module_name"=>"Report"}, {"id"=>97, "name"=>"View Sales Report", "module_name"=>"Report"}].each{|a|
  FeatureName.create a
}
Feature.create role_id: Role.first.id, feature_name_id: FeatureName.where(name: 'Manage Role').first_or_create.id
Feature.create role_id: Role.first.id, feature_name_id: FeatureName.where(name: 'View Role').first_or_create.id

GlobalSetting.create category: 'member_point_amount', name: 100000, description: '1 point seratus rebu', is_active: true
GlobalSetting.create category: 'sale_extra_charges', name: 'Katalog', description: '1 point seratus rebu', is_active: true
GlobalSetting.create category: 'sale_extra_charges', name: 'Jasa Kado', description: '1 point seratus rebu', is_active: true
GlobalSetting.create category: 'sale_extra_charges', name: 'CHARGE MARCHANT', description: '1 point seratus rebu', is_active: true
GlobalSetting.create category: 'sale_rounding', name: 'Rounding', description: '1 point seratus rebu', is_active: true


#-------=======Initial Data End=======-------

=begin
#for test only

#department
d1 = Department.where(name: 'SEPATU', code: '001').first_or_create
d2 = Department.where(name: 'SANDAL', code: '002').first_or_create

#office
h1 = HeadOffice.where(office_name: 'HO Bogor', description: 'HO Pusat Bogor', warehouse: 'Gudang HO Bogor', contact_person: User.first.id, phone_number: '08989898', fax_number: '08989898', mobile_phone: '08989898',
  address: 'Gedong Sawah', lat: '6.666', long: '7.7777').first_or_create
b1 = Branch.where(office_name: 'ABC 1', description: 'ABC 1 Bogor', warehouse: 'Gudang ABC 1', contact_person: User.first.id, phone_number: '08989898', fax_number: '08989898', mobile_phone: '08989898',
  address: 'Dewi Sartika', lat: '6.666', long: '7.7777')
b2 = Branch.where(office_name: 'ABC 2', description: 'ABC 2 Bogor', warehouse: 'Gudang ABC 2', contact_person: User.first.id, phone_number: '08989898', fax_number: '08989898', mobile_phone: '08989898',
  address: 'Dewi Sartika', lat: '6.666', long: '7.7777').first_or_create

#office_department
Department.all.each{|d|
  Office.all.each{|o|
    OfficeDepartment.create department_id: d.id, office_id: d.id,
  }
}

#supplier
s1 = Supplier.where(code: '001', name: 'Sugih Jaya', address: 'Sapan Rancakaso', city: 'Bandung', send_address: 'Sapan Rancakaso', phone: '08989899', fax: '089898991', hp1: '0898989912', email: 'sugih@jaya.com',
  send_city: 'Bandung', setup_discount: 30, hp2: '0898989911', pinbb: 'p121212', no_bill: '090909090', province: 'Jawa Barat', zip: '40123', suptype: 'Konsinyasi', long_term: 30).first_or_create
s2 = Supplier.where(code: '002', name: 'Sumber Kreasi', address: 'Sapan Rancakaso', city: 'Bandung', send_address: 'Sapan Rancakaso', phone: '08989899', fax: '089898991', hp1: '0898989912',
  email: 'sumber@kreasi.com', send_city: 'Bandung', setup_discount: 30, hp2: '0898989911', pinbb: 'p121212', no_bill: '090909090', province: 'Jawa Barat', zip: '40123', suptype: 'Konsinyasi',
  long_term: 30).first_or_create

#supplier_department
Supplier.all.each{|d|
  Department.all.each{|o|
    SupplierDepartment.create department_id: d.id, office_id: d.id,
    d.brands.create name: "ADIDAS#{o.id}#{d.id}", code: "#{o.id}#{d.id}", discount_percent1: 10, discount_percent2: 20, discount_percent3: 30, discount_percent4: 40, department_id: d.id, set_harga: 'Normal'
  }
}

Product.all.each{|product|
  product.size.size_details.each{|size_detail|
    ProductSize.create product_id: product.id, size_detail_id: size_detail.id
    Office.all.each{|branch|
      product_size = product.size
      product.update_attributes(size_id: Size.first.id) if product_size.blank?
      product.size.size_details.each{|size_detail|
        ProductDetail.create product_id: product.id, size_detail_id: size_detail.id, min_stock: 7, warehouse_id: branch.id, available_qty: 17, allocated_qty: 27, freezed_qty: 37,
          rejected_qty: 7, defect_qty: 21
      }
    }
  }
}

#Reset Transaction

Product Mutation, Product Transfer, Return to HO, all in one table product_mutations

All Product Mutation, from inventory, purchase or sales, per office per size are logged in product_mutation_histories

ActiveRecord::Base.connection.execute("TRUNCATE TABLE sales, sales_details, purchase_requests, purchase_request_details, purchase_orders, purchase_order_details, receivings,
  receiving_details, stock_transfers, stock_transfer_details, stock_opnames, stock_opname_details, product_mutations RESTART IDENTITY;")

After transaction
- change quantity
- logged in history

#Transaction Status:

Inventory==============================================================================================================================================================================
--------------------------------------------------------------------------Product Mutation---------------------------------------------------------------------------------------------
After Create -> Pending
After Received -> Closed

----------------------------------------------------------------------Product Mutation Receipt-----------------------------------------------------------------------------------------
After Create -> Ready For Inspection
After Inspection -> Inspected

=======================================================================================================================================================================================

Purchasing=============================================================================================================================================================================
----------------------------------------------------------------------------------Purchase Request-------------------------------------------------------------------------------------
After Create -> Pending
After Included in PO -> Approved
After Receive One Transfer -> On Progress
After Transfer Completed -> Closed

----------------------------------------------------------------------------------Purchase Order---------------------------------------------------------------------------------------
After Create -> Waiting Approval
After Approved -> Approved/Rejected
After One Receive -> On Progress
After Receiving Completed -> Closed

---------------------------------------------------------------------------------------Receiving---------------------------------------------------------------------------------------
After Create -> Ready For Inspection
After Inspection -> Inspected
After Paid All -> Closed

-----------------------------------------------------------------------------------Product Transfer------------------------------------------------------------------------------------
After Create -> Pending
After Received by Branch -> Closed

-------------------------------------------------------------------------------Product Transfer Receipt--------------------------------------------------------------------------------
After Create -> Ready For Inspection
After Inspection -> Inspected

------------------------------------------------------------------------------------ReturnsToSupplier----------------------------------------------------------------------------------
After Create -> On Progress
After Complete -> Closed
=======================================================================================================================================================================================

=end

