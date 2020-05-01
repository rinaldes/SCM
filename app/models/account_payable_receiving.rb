class AccountPayableReceiving < ActiveRecord::Base
  belongs_to :receiving
  belongs_to :account_payable
end
