class AddRefCodeToPmh < ActiveRecord::Migration
  def change
    add_column :product_mutation_histories, :ref_code, :string
  end
end
