class SodEod < ActiveRecord::Base
  #serialize :cash

  belongs_to :office
  belongs_to :user

  has_many :sessions, foreign_key: :sodeod_id

  before_save :set_start_time, if: 'start_time.present?'
  before_update :set_end_time, if: 'end_time.present?'

  before_save :calculate_start_amount, if: 'start_time.present?'
  before_update :calculate_end_amount, if: 'end_time.present?'

  before_update :calculate_total_cash_sales, if: 'end_time.present?'
  before_update :calculate_petty_cash, if: 'end_time.present?'
  before_update :calculate_difference, if: 'end_time.present?'

  after_create :generate_session_number

  validates :office_id, :presence => { message: "Branch is required" }
  #validates :date, :presence => true
  validates :start_time, presence: { message: "Star time is required" }, on: :create
  validates :user_id, presence: { message: "Cashier is required" }

  def self.api(params)
    ActiveSupport::JSON.decode(params).each do |cash|
      sod_eod = self.new()
      sod_eod.actual_end_amount = cash["actual_end_amount"]
      sod_eod.end_amount = cash["end_amount"]
      sod_eod.cash = cash["cash"]
      sod_eod.credit = cash["credit"]
      sod_eod.sod_eod_date = cash["sod_eod_date"].to_time
      sod_eod.debit = cash["debit"]
      sod_eod.difference = cash["difference"]
      sod_eod.discount = cash["discount"]
      sod_eod.end_time = cash["end_time"].to_time if cash["end_time"].present?
      sod_eod.end_100 = cash["end_100"]
      sod_eod.end_100k = cash["end_100k"]
      sod_eod.end_10k = cash["end_10k"]
      sod_eod.end_1k = cash["end_1k"]
      sod_eod.end_200 = cash["end_200"]
      sod_eod.end_20k = cash["end_20k"]
      sod_eod.end_2k = cash["end_2k"]
      sod_eod.end_50 = cash["end_50"]
      sod_eod.end_500 = cash["end_500"]
      sod_eod.end_50k = cash["end_50k"]
      sod_eod.end_5k = cash["end_5k"]
      sod_eod.machine_id = cash["machine_id"]
      sod_eod.start_amount = cash["start_amount"]
      sod_eod.retur = cash["retur"]
      sod_eod.total_cash_sales = cash["total_cash_sales"]
      sod_eod.note = cash["note"].to_s + " (insert from mobile)"
      sod_eod.paid_difference = cash["paid_difference"]
      sod_eod.petty_cash = cash["petty_cash"]
      sod_eod.ppn = cash["ppn"]
      sod_eod.voucher = cash["voucher"]
      sod_eod.total_sales = cash["total_sales"]
      sod_eod.session = cash["session"]
      sod_eod.special_discount = cash["special_discount"]
      sod_eod.total_spending = cash["total_spending"]
      sod_eod.start_time = cash["start_time"].to_time if cash["start_time"].present?
      sod_eod.start_100 = cash["start_100"]
      sod_eod.start_100k = cash["start_100k"]
      sod_eod.start_10k = cash["start_10k"]
      sod_eod.start_1k = cash["start_1k"]
      sod_eod.start_200 = cash["start_200"]
      sod_eod.start_20k = cash["start_20k"]
      sod_eod.start_2k = cash["start_2k"]
      sod_eod.start_50 = cash["start_50"]
      sod_eod.start_500 = cash["start_500"]
      sod_eod.start_50k = cash["start_50k"]
      sod_eod.start_5k = cash["start_5k"]
      sod_eod.office_id = cash["office_id"]
      sod_eod.transfer = cash["transfer"]
      sod_eod.session_type = cash["session_type"]
      sod_eod.user_id = cash["user_id"]
      sod_eod.receipt_count = cash["receipt_count"]
      sod_eod.save!
    end
  end

  def set_start_time
    self.start_time = self.start_time.to_time
  end

  def set_end_time
    self.end_time = self.end_time.to_time
  end

  def calculate_start_amount
    note = ['(insert from mobile)','MOBILE_POS']
    unless note.include? @attributes["note"]
    self.start_amount  = 0
      start_cash = self.cash[:start].to_i
      start_cash.each do |c|
        self.start_amount  += c.first.to_f * c.last.to_f
      end
    end
  end

  def calculate_end_amount
    note = ['(insert from mobile)','MOBILE_POS']
    unless note.include? @attributes["note"]
    self.end_amount  = 0
      if (self.cash[:end])
        end_cash = self.cash[:end]
        end_cash.each do |c|
          self.end_amount  += c.first.to_f * c.last.to_f
        end
      end
    end
  end

  def calculate_total_cash_sales
    note = ['(insert from mobile)','MOBILE_POS']
    unless note.include? @attributes["note"]
      sales = Sale.where("user_id=? AND created_at between ? AND ?", User.current.id, start_time, end_time)
      self.total_cash_sales =  !sales.blank? ? sales.select("SUM(total_paid)") : 0
    end
  end

  def self.get_total_cash_sales
  	calculate_total_cash_sales
  end

  def calculate_petty_cash
    note = ['(insert from mobile)','MOBILE_POS']
    unless note.include? @attributes["note"]
      self.petty_cash = (self.end_amount.to_f - self.total_cash_sales.to_f) - self.total_spending.to_f
    end
  end

  def calculate_difference
    note = ['(insert from mobile)','MOBILE_POS']
    unless note.include? @attributes["note"]
      self.difference = self.actual_end_amount.to_f - self.petty_cash.to_f
    end
  end

  def self.in_date(in_date)
    if in_date.present?
      where(:date => in_date.to_date)
    else
      where(nil)
    end
  end

  def self.in_branch(in_branch)
    if in_branch.present?
      joins(:office).where("lower(offices.office_name) LIKE ?", "%#{in_branch}%")
    else
      where(nil)
    end
  end

  def has_started?
    self.start_time.present?
  end

  def has_ended?
    self.end_time.present?
  end

  def generate_session_number
    session = SodEod.where("office_id = ? AND id != ?", self.office_id, self.id).order('start_time DESC').count + 1
    self.update_attributes(:session => session)
  end

end
