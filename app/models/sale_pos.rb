class SalePos < SalePosDb
  self.table_name = "sales"
  has_many :sale_pos_details
end