class PettyCash < ActiveRecord::Base

  belongs_to :office

  has_many :cash_outs, :dependent => :destroy
  has_many :petty_cash_details, :dependent => :destroy
  accepts_nested_attributes_for :petty_cash_details#, :allow_destroy => true, :reject_if => lambda { |c| c[:date].blank? }

  validates :office_id, :presence => true
  validates :year, :presence => true
  validates_uniqueness_of :year, :scope => :office_id

  after_create :initialize_petty_cash_details

  def self.in_year(in_year)
    if in_year.present?
      where(:year => in_year.to_date)
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

  def self.generate_petty_cashes(year = nil, month = nil, office = nil, init_bgt = nil )
    if year.present? && month.present?
      date =  Time.new(year, month, 1)
    else
      date =  Time.now.end_of_month+1.days
    end

    if office.present?
      branch = Office.find(office)
      b = branch.petty_cashes.where(:year => date, month: date).first_or_create
      b.petty_cash_details.first.update_attributes(initial_budget: init_bgt)
    else
      branches = Office.all
      branches.each do |branch|
        branch.petty_cashes.where(:year => date, month: date).first_or_create
      end
    end
  end

  def initialize_petty_cash_details
    start_date = self.year.to_date.beginning_of_month
    end_date = self.year.to_date.end_of_month
    (start_date..end_date).each do |date|
      self.petty_cash_details.create(:date => date)
    end
  end

  def get_realization
    realization = Sale.where("EXTRACT(MONTH FROM created_at) = ?", self.year.month).select("SUM(total_price)")
    if realization.blank?
        realization
    else
      0
    end
  end

  def get_realization_in_percent
      realization = self.get_realization.nil? ? 0 : self.get_realization.to_f
      if realization > 0
        realization  * 100.0
      else
        0
      end
  end

end
