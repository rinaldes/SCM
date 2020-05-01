class AddHppToPmh < ActiveRecord::Migration
  def change
    add_column :product_mutation_histories, :ppn, :float
  end
end
