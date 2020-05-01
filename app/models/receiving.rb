class Receiving < ActiveRecord::Base
  has_many :receiving_details, dependent: :destroy
  has_many :account_payable_receivings
  has_many :account_payables, through: :account_payable_receivings
  has_many :pr_transfer_products
  has_many :purchase_transfers, through: :pr_transfer_products
  has_many :selling_prices

  belongs_to :supplier
  belongs_to :purchase_order
  belongs_to :head_office, class_name: 'Office'

  has_one :account_payable

  READY_FOR_INSPECTION = 'READY FOR INSPECTION'
  INSPECTED = 'INSPECTED'
  CLOSED = 'CLOSED'

  accepts_nested_attributes_for :receiving_details, :reject_if => :all_blank, :allow_destroy => true

  validates :consigment_number, presence: true
  validates :head_office_id, presence: true
  validates :supplier_id, presence: true
  # validates :purchase_order_id, uniqueness: true
  validates_uniqueness_of :purchase_order_id, :allow_blank => true
  # validates_format_of :purchase_order_number, :with => /^[0-9\d\s]*$/i, :multiline => true, :message => "hanya mengijinkan input angka"

  after_create :create_ap

  def create_ap
    now = Time.now
    Receiving.where("status NOT IN ('CLOSED', 'PAID ON PROGRESS')").group_by(&:supplier_id).each{|receiving|
      ap_number = "AP/#{now.strftime("%m/%y-")}" + sprintf('%06d', AccountPayable.where("extract(year from created_at) = ? and extract(month from created_at) = ?", now.strftime("%Y"), now.strftime("%m")).count+1)
      total_amount = receiving[1].map(&:total).sum
      supplier = Supplier.find_by_id receiving[0]
      if supplier.long_term.present?
        due_date = now+supplier.long_term.days
        due_day = due_date.strftime('%d').to_i
        due_day = due_day < 15 || due_day-15 < 30-due_day ? 15 : due_date.strftime('%m').to_i == 2 ? due_date.end_of_month.strftime('%d').to_i : 30
      end
      ap = AccountPayable.where(supplier_id: receiving[0], due_date: (due_date.strftime("%Y-%m-#{due_day}") rescue nil)).first_or_create
      ap.ap_number = ap_number if ap.ap_number.blank?
      ap.total_amount = total_amount
      ap.outstanding_amount = ap.outstanding_amount.to_f + total_amount
      ap.payment_term = '-'
      ap.save
      receiving[1].each{|r|
        AccountPayableReceiving.create account_payable_id: ap.id, receiving_id: r.id
      }
    }
  end

  def total
    receiving_details.map(&:total_price).compact.sum
  end

  def self.get_number(time_now)
    "RC/ho-cabang/supplier/#{time_now.strftime("%Y-%m-%d")}/#{
      sprintf('%06d',
        (Receiving.where("extract(year from date) = ? and extract(month from date) = ?", time_now.strftime("%Y"), time_now.strftime("%m")).last.number.split('-')[1].to_i rescue 0) + 1)
    }"
  end

  def self.get_journal_memos
    self.joins(:account_payables, :supplier).group("receivings.id").order("receivings.created_at")
  end
end
