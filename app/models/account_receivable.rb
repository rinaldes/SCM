class AccountReceivable < ActiveRecord::Base
  belongs_to :member
  belongs_to :office, foreign_key: :branch_id

  has_many :payments, :dependent => :destroy
  accepts_nested_attributes_for :payments, :allow_destroy => true, :reject_if => lambda { |c| c[:amount].blank? }

  validates :due_date, presence: { message: "Payment Due Date can't be blank!" }, on: :update, if: :is_pending_payment

  def self.api(params)
    ActiveSupport::JSON.decode(params).each do |d|
      account_receivable = self.new()
      account_receivable.ar_number = d["ar_number"]
      account_receivable.transaction_number = d["transaction_number"]
      account_receivable.member_id = d["member_id"]
      account_receivable.total_amount = d["total_amount"]
      account_receivable.total_paid = d["total_paid"]
      account_receivable.outstanding = d["outstanding"]
      account_receivable.due_date = d["due_date"]
      account_receivable.bill_to_name = d["bill_to_name"]
      account_receivable.bill_to_phone = d["bill_to_phone"]
      account_receivable.bill_to_email = d["bill_to_email"]
      account_receivable.bill_to_address = d["bill_to_address"]
      account_receivable.branch_id = d["branch_id"]
      account_receivable.payment_term = d["payment_term"]
      account_receivable.payment_discount = d["payment_discount"]
      account_receivable.sale_id = d["sale_id"]
      account_receivable.save!
    end
  end

  def is_pending_payment
    self.payment_term.try(:downcase) == 'pending payment'
  end

  def is_credit
    self.payment_term.try(:downcase) == 'credit'
  end

  def self.in_ar_number(in_ar_number)
    if in_ar_number.present?
      where(:ar_number => in_ar_number)
    else
      where(nil)
    end
  end

  def self.in_transaction_no(in_transaction_no)
    if in_transaction_no.present?
      where(:transaction_number => in_transaction_no)
    else
      where(nil)
    end
  end

  def self.in_customer_name(in_customer_name)
    if in_customer_name.present?
      joins(:member).where("lower(members.name) LIKE ?", "%#{in_customer_name}%")
    else
      where(nil)
    end
  end

  def self.get_total_account_receivables(member_id)
    total_amount = self.where("member_id = ?", member_id).pluck(:total_amount)
    total_amount.inject{ |sum, el| sum + el } if total_amount.present?
  end
end