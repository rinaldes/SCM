class AddOutstandingAmountToReceiving < ActiveRecord::Migration
  def change
    add_column :receivings, :outstanding_amount, :float
  end
end
