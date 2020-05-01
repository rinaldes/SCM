class DataCenterMClass < DataCenterDatabase
  self.table_name = :m_classes

  belongs_to :m_class, foreign_key: :parent_id
  has_many :m_classes, foreign_key: :parent_id, dependent: :destroy
end
