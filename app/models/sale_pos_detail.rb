class SalePosDetail < SalePosDb
  self.table_name = "sales_details"
  belongs_to :sale_pos, foreign_key: :sale_id
end