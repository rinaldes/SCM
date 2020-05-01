class PtnracCntc < DatabaseLain
  self.table_name = "ptnrac_cntc"
  self.primary_key = "ptnrac_oid"

  belongs_to :ptnra_addr, :foreign_key => 'addrc_ptnra_oid'
end