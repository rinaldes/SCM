class EdcMachine < ActiveRecord::Base
  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["bank_name", "branch", "edc_serial_number", "account_number", "owner"]
      all.each do |edc_machine|
        csv << [edc_machine.bank_name, edc_machine.branch, edc_machine.edc_serial_number, edc_machine.account_number, edc_machine.owner]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["bank_name", "branch", "edc_serial_number", "account_number", "owner"]
      all.each do |edc_machine|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      return {error: 1, message: "Wrong CSV Format"} if row["bank_name"].blank?
      if find_by_bank_name(row["bank_name"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        edc_machine = new(parameters.permit(:bank_name, :branch, :edc_serial_number, :account_number, :owner))
        unless edc_machine.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{edc_machine.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{edc_machine.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}"}
      end
    end
    return {error: 0, message: "EDC Machines successfully imported"}
  end

  def self.open_spreadsheet(file)
    case File.extname(file.original_filename)
    when ".csv" then Csv.new(file.path, nil, :ignore)
    when ".xls" then Excel.new(file.path, nil, :ignore)
    when ".xlsx" then Excelx.new(file.path, nil, :ignore)
    else raise "Unknown file type: #{file.original_filename}"
    end
  end
  validates :bank_name, :presence => true, :uniqueness => true
  validates_format_of :bank_name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates :branch, :presence => true
  validates_format_of :branch, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"
  validates :edc_serial_number, :presence => true
  validates :account_number,:presence =>true, :uniqueness => true
  validates :owner, :presence =>true
  validates_format_of :owner, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"

end
