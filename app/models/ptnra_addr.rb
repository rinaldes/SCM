class PtnraAddr < DatabaseLain
  self.table_name = "ptnra_addr"
  self.primary_key = "ptnra_oid"

  belongs_to :ptnr_mstr, :foreign_key => 'ptnra_ptnr_oid'
  has_many :ptnrac_cntcs, class_name: "PtnracCntc"
end