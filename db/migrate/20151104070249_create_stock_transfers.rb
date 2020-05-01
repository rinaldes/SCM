class CreateStockTransfers < ActiveRecord::Migration
  def change
    create_table :stock_transfers do |t|
    	t.integer	:user_id
    	t.date		:date
    	t.string	:number
    	t.integer	:branch_id
    	t.string	:string
      t.string  :no_surat_jalan
      t.string  :status
      t.timestamps
    end
  end
end
