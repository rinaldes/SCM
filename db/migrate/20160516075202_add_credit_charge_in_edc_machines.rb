class AddCreditChargeInEdcMachines < ActiveRecord::Migration
  def change
    add_column :edc_machines, :credit_charge, :float
  end
end
