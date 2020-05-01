class CreateOtherCharges < ActiveRecord::Migration
  def change
    create_table :other_charges do |t|
    	t.integer :account_payable_id
    	t.string :name
    	t.float :amount
      t.timestamps
    end
  end
end
