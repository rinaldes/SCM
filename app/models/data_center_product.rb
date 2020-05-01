class DataCenterProduct < DataCenterDatabase
  # establish_connection(:data_center)
  self.table_name = :products

  belongs_to :m_class, class_name: 'DataCenterMClass'
  belongs_to :department, class_name: 'DataCenterDepartment'

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["no", "article", "department_name", "category_1", "category_2", "category_3", "category_4", "cost_of_products", "uom_1", "uom_2", "uom_3", "box_num", "box2_num", "net_price_perpcs", "barcode",
        "description", "description_2", "selling_price", "minimal_order", "supplier_code", "supplier_name", "store"]
      nomor = 0
      all.each do |product|
        nomor += 1
        cat_ori = DataCenterMClass.find(product.m_class_id) rescue ''
        cat_level = cat_ori.level rescue 0
        if cat_level == 1
          cat1 = cat_ori
          cat2 = ''
          cat3 = ''
          cat4 = ''
        elsif cat_level == 2
          cat2 = cat_ori
          cat1 = DataCenterMClass.find(cat_ori.parent_id) rescue ''
          cat3 = ''
          cat4 = ''
        elsif cat_level == 3
          cat3 = cat_ori
          cat2 = DataCenterMClass.find(cat_ori.parent_id) rescue ''
          cat1 = DataCenterMClass.find(cat3.parent_id) rescue ''
          cat4 = ''
        elsif cat_level == 4
          cat4 = cat_ori
          cat3 = DataCenterMClass.find(cat_ori.parent_id) rescue ''
          cat2 = DataCenterMClass.find(cat3.parent_id) rescue ''
          cat1 = DataCenterMClass.find(cat2.parent_id) rescue ''
        end
        csv << [nomor, product.article, (product.department.name rescue ''), (cat1.name rescue ''), (cat2.name rescue ''), (cat3.name rescue ''), (cat4.name rescue ''), product.cost_of_products,
          (product.unit.name rescue ''), (DataCenterUnit.find(product.box_id).name rescue ''), (DataCenterUnit.find(product.box2_id).name rescue ''), product.box_num, product.box2_num, product.purchase_price, product.barcode,
          product.description, product.short_name, product.selling_price, '', product.margin_percent, product.minimal_order, (product.supplier.code rescue ''), (product.supplier.name rescue ''), '']
      end
    end
  end
end
