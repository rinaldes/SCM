class AddPaymentStatusToReceive < ActiveRecord::Migration
  def change
    add_column :receivings, :payment_status, :string #CLOSED jika sudah lunas, OPEN jika belum lunas
  end
end
