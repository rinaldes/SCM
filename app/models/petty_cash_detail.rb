class PettyCashDetail < ActiveRecord::Base

  belongs_to :petty_cash
  validates :date, :presence => true
  validates_uniqueness_of :date, :scope => :petty_cash_id
  before_update :calcucalte_balance

  def calcucalte_balance
    # if PettyCashDetail.where("petty_cash_id = #{self.petty_cash_id} AND initial_budget IS NOT NULL").first.initial_budget.present?
      # self.balance = self.initial_budget.to_f + self.cash_in.to_f - self.cash_out.to_f
    # else
      self.balance = self.initial_budget.to_f + self.cash_in.to_f - self.cash_out.to_f
    # end
  end

end
