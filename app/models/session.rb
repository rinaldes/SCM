class Session < ActiveRecord::Base
  belongs_to :user
  belongs_to :office
  belongs_to :sod_eod
  has_many :sales

  def self.api(params)
    ActiveSupport::JSON.decode(params).each do |ss|
      session = self.new()
      session.start_time = ss["start_time"].to_time if ss["start_time"].present?
      session.end_time = ss["end_time"].to_time if ss["end_time"].present?
      session.client_id = ss["client_id"]
      session.shift_no = ss["shift_no"]
      session.sodeod_id = ss["sodeod_id"]
      session.office_id = ss["office_id"]
      session.user_id = ss["user_id"]

      session.save!
    end
  end
end

