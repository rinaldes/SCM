class CashOut < ActiveRecord::Base
  mount_uploader :receipt, PettyCashUploader
  belongs_to :petty_cash

  # before_save :set_time
  # after_save :customize_detail

  validates :amount, presence: true, numericality: {only_float: true}
  validates :cash_out_type, presence: true

  # def set_time
  #   self.time = self.time.to_time
  # end

  # def customize_detail
  #   pcd = PettyCashDetail.where(petty_cash_id: petty_cash_id, date: ).first_or_create
  #   pcd_tobe_updated = self.cash_out_type == 'CASH IN' ? {cash_in: pcd.cash_in.to_f+self.amount} : {cash_out: pcd.cash_out.to_f+self.amount}
  #   pcd.update_attributes(pcd_tobe_updated)
  # end

  def self.get_report
    self.where("LOWER(cash_out_type) != ?", "cash in").order('created_at DESC')
  end
end
