class CreateExtraCharges < ActiveRecord::Migration
  def change
    create_table :extra_charges do |t|
      t.string :description
      t.float :amount
      t.timestamps
    end
  end
end
