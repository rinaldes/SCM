class RenameMutationId < ActiveRecord::Migration
  def change
    rename_column :product_mutation_histories, :mutation_id, :product_mutation_detail_id
  end
end
