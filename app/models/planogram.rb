class Planogram < ActiveRecord::Base
  # validates :office_id, presence: true
  validates :rack_number, uniqueness: true, presence: true
  #validates :rack_type, presence: true, uniqueness: true

  has_many :product_planograms
  has_many :planograms_stores
  has_many :planos, foreign_key: :rak_id

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["office_id","rack_number","rack_type"]
    end
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["office_id","rack_number","rack_type"]
      Planogram.all.each do |planogram|
        csv << [planogram.office_id, planogram.rack_number, planogram.rack_type]
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      return {error: 1, message: "Looks like Rack Number is blank."} if row["rack_number"].blank?

      if find_by_rack_number(row["rack_number"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        planogram = new(parameters.permit(:office_id, :rack_number, :rack_type))
        unless planogram.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{planogram.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{planogram.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. Rack Number Are Already Existed."}
      end
    end
    return {error: 0, message: "Planogram successfully imported"}
  end
end
