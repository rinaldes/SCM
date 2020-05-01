class TransactionHistoryDetail < ActiveRecord::Base
	belongs_to :transaction_history
	belongs_to :brand
	belongs_to :m_class
	belongs_to :size
	belongs_to :colour
end
