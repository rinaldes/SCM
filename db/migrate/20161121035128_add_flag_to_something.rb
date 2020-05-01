class AddFlagToSomething < ActiveRecord::Migration
  def change
  	add_column :suppliers, :sent_to_erp, :datetime
  	add_column :receivings, :sent_to_erp, :datetime
  end
end