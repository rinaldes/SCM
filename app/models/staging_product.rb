class StagingProduct < ActiveRecord::Base
  belongs_to :brand
  belongs_to :colour2, class_name: 'Colour'
  belongs_to :colour3, class_name: 'Colour'
  belongs_to :colour4, class_name: 'Colour'
  belongs_to :m_class, class_name: 'DataCenterMClass'
  belongs_to :unit
  belongs_to :box, class_name: 'Unit'
  belongs_to :box2, class_name: 'Unit'
  belongs_to :size
  belongs_to :colour
  belongs_to :department, class_name: 'DataCenterDepartment'

  has_many :purchase_request_details
  has_many :inventory_request_details
  has_many :product_details
  has_many :receivings
  has_many :branch_prices
  has_many :product_sizes, dependent: :destroy
  has_many :product_suppliers
  has_many :suppliers, through: :product_suppliers
  has_many :selling_prices
  has_many :sales_details
  has_many :skus

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["no", "article", "department_name", "category_1", "category_2", "category_3", "category_4", "cost_of_products", "uom_1", "uom_2", "uom_3", "box_num", "box2_num", "net_price_perpcs", "barcode",
        "description", "description_2", "selling_price", "minimal_order", "supplier_code", "supplier_name", "store"]
      nomor = 0
      all.each do |product|
        nomor += 1
        cat_ori = MClass.find(product.m_class_id) rescue ''
        cat_level = cat_ori.level rescue 0
        if cat_level == 1
          cat1 = cat_ori
          cat2 = ''
          cat3 = ''
          cat4 = ''
        elsif cat_level == 2
          cat2 = cat_ori
          cat1 = MClass.find(cat_ori.parent_id) rescue ''
          cat3 = ''
          cat4 = ''
        elsif cat_level == 3
          cat3 = cat_ori
          cat2 = MClass.find(cat_ori.parent_id) rescue ''
          cat1 = MClass.find(cat3.parent_id) rescue ''
          cat4 = ''
        elsif cat_level == 4
          cat4 = cat_ori
          cat3 = MClass.find(cat_ori.parent_id) rescue ''
          cat2 = MClass.find(cat3.parent_id) rescue ''
          cat1 = MClass.find(cat2.parent_id) rescue ''
        end
        csv << [nomor, product.article, (product.department.name rescue ''), (cat1.name rescue ''), (cat2.name rescue ''), (cat3.name rescue ''), (cat4.name rescue ''), product.cost_of_products,
          (product.unit.name rescue ''), (Unit.find(product.box_id).name rescue ''), (Unit.find(product.box2_id).name rescue ''), product.box_num, product.box2_num, product.purchase_price, product.barcode,
          product.description, product.short_name, product.selling_price, '', product.margin_percent, product.minimal_order, (product.supplier.code rescue ''), (product.supplier.name rescue ''), '']
      end
    end
  end
end
