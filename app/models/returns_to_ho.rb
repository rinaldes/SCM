class ReturnsToHo < ProductMutation
  scope :count_no, lambda { |x| where("extract(month from created_at) = ?", "#{x}") }
  scope :count_not, lambda { |x| where("extract(year from created_at) = ?", "#{x}") }
  belongs_to :supplier

  def self.get_number(time_now)
    "RTH/ho - cabang/supplier/#{time_now.strftime("%Y-%m-%d")}/#{
      sprintf('%06d',
        (ReturnsToHo.where("extract(year from date) = ? and extract(month from date) = ?", time_now.strftime("%Y"), time_now.strftime("%m")).last.number.split('-')[1].to_i rescue 0) + 1)
    }"
  end
end