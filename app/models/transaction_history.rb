class TransactionHistory < ActiveRecord::Base
  has_many :transaction_history_details
end
