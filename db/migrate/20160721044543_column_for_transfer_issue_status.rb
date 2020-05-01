class ColumnForTransferIssueStatus < ActiveRecord::Migration
  def change
    add_column :stock_transfers, :location, :string
    add_column :stock_transfers, :remark, :string
    add_column :stock_transfers, :effective_date, :date
  end
end
