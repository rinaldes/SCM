class AddPdetailIdAndRemoveProductIdOnPlano < ActiveRecord::Migration
  def change
    Plano.reset_column_information
    add_column :planos, :product_detail_id, :integer unless Plano.column_names.include?('product_detail_id')
  end
end
