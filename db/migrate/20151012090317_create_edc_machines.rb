class CreateEdcMachines < ActiveRecord::Migration
  def change
    create_table :edc_machines do |t|
      t.string :bank_name
      t.string :branch
      t.string :edc_serial_number
      t.string :account_number
      t.string :owner

      t.timestamps
    end
  end
end
