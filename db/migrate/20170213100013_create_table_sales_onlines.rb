class CreateTableSalesOnlines < ActiveRecord::Migration
  def change
    create_table :sales_onlines do |t|
      # TELCO PASCABAYAR
      t.string :tipe              #ex: HALO
      t.string :idpel             #ex: 081300000001
      t.string :name              #ex: SUPARNO MITRO
      t.float :bill_amt           #ex: 38500 (Rp Tagihan)
      t.float :admin_amt          #ex: 2500
      t.float :total_amt          #ex: 41000 (Rp Total Bayar)
      t.string :no_invoice        #ex: INV150820197633 (Ref Payment)
      t.date :pay_date            #ex: 2015/05/28-04:28:30
      t.string :biller_msg        #ex: TELKOMSEL MENYATAKAN STRUK INI SEBAGAI BUKTI PEMBAYARAN YANG SAH (Pesan Biller)

      # TELCO VOUCHER
      t.string :transaction_id    #ex: 7446978
      t.string :code              #ex: XX50-08174860519
      t.string :status            #ex: SUKSES - 99040528021726

      # PAYMENT POINT
      t.string :biller_refcode    #ex: 985D211C7B6E6AB6CC20A82572E13E2F
      t.string :bank_code         #ex: BANK XYZ

      # Sales & Branch
      t.integer :branch_id
      t.integer :sale_id
      t.integer :session_id

    end
  end
end
