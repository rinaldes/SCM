class Payment < ActiveRecord::Base
  belongs_to :account_receivable

  before_update :set_payment_date
  after_save :update_outstanding_on_ar

  def set_payment_date
    self.payment_date = Time.now.to_date
  end

  def update_outstanding_on_ar
    self.account_receivable.update_attributes(:outstanding => (self.account_receivable.outstanding.to_f - self.payment_amount.to_f)) unless self.payment_amount.blank? &&  self.account_receivable.outstanding.blank?
  end

  def self.get_report_receivables(member_id)
    Payment.joins(:account_receivable).where("account_receivables.member_id = ?", member_id)
  end
end
