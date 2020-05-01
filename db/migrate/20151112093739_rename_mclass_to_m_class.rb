class RenameMclassToMClass < ActiveRecord::Migration
  def change
    rename_column :promo_item_lists, :mclass_id, :m_class_id
    rename_column :prize_lists, :mclass_id, :m_class_id
  end
end
