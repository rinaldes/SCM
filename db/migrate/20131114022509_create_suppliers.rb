class CreateSuppliers < ActiveRecord::Migration
  def change
    create_table :suppliers do |t|
      t.string :code
      t.string :name
      t.string :address
      t.string :city
      t.string :send_address
      t.string :phone
      t.string :fax
      t.string :hp1
      t.string :email
      t.string :person
      t.string :send_city
      t.float :setup_discount
      t.string :hp2
      t.string :pinbb
      t.string :no_bill
      t.string :bank
      t.string :branch
      t.timestamps
    end
    add_index :suppliers, :code
    add_index :suppliers, :name
    add_index :suppliers, :address
    add_index :suppliers, :city
    add_index :suppliers, :send_address
    add_index :suppliers, :phone
    add_index :suppliers, :fax
    add_index :suppliers, :hp1
    add_index :suppliers, :email
    add_index :suppliers, :person
    add_index :suppliers, :send_city
    add_index :suppliers, :setup_discount
    add_index :suppliers, :hp2
    add_index :suppliers, :pinbb
    add_index :suppliers, :no_bill
    add_index :suppliers, :bank
    add_index :suppliers, :branch
  end
end
