class ProductSupplier < ActiveRecord::Base
  validates_presence_of :product_id
  validates_uniqueness_of :product_id, :scope => :supplier_id 
  validates_presence_of :supplier_id


  belongs_to :contact_person
  belongs_to :product
  belongs_to :supplier
end
