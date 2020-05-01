class Unit < ActiveRecord::Base
  before_validation :upcase_save

  validates :name, :short_name, presence: {message: 'required'}, :uniqueness => {:case_sensitive => false}
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphanumeric input only"
  validates_format_of :short_name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphanumeric input only"

  def check_transaction
    return false if Product.find_by_unit_id(self.id)
    true
  end

  def upcase_save
    self.name = name.titleize rescue nil
    self.short_name = short_name.titleize rescue nil
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["name", "short_name"]
      all.each do |unit|
        csv << [unit.name, unit.short_name]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["name", "short_name"]
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["name"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        unit = new(parameters.permit(:name, :short_name))
        unless unit.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{unit.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{unit.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Must unique"}
      end
    end
    return {error: 0, message: "Successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
end
