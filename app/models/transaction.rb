class Transaction < ActiveRecord::Base
  def self.api(params)
    ActiveSupport::JSON.decode(params).each do |d|
      transaction = self.new()
      transaction.date = d["date"]
      transaction.employee_id = d["employee_id"]
      transaction.transaction_number = d["transaction_number"]
      transaction.save!
    end
  end
end