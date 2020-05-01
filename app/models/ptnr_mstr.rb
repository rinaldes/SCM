class PtnrMstr < DatabaseLain
  self.table_name = "ptnr_mstr"
  self.primary_key = "ptnr_oid"

  has_many :ptnra_addrs, class_name: "PtnraAddr"
end