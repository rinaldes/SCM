class AccountPayableDetail < ActiveRecord::Base
   belongs_to :account_payable
   before_save :set_receive_id

  def set_receive_id
#    self.set_receive_id = self.account_payable.receive_id
  end

end
