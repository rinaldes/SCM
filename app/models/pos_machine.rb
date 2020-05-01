class PosMachine < ActiveRecord::Base

  belongs_to :head_office, foreign_key: :office_id

  before_validation :upcase_save

  validates :name, :presence => true , :uniqueness => true
  validates :office_id, :presence => true
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"

  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ? OR name LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def check_transaction
    return false if Product.find_by_pos_machine_id(self.id) || Product.find_by_pos_machine2_id(self.id) || Product.find_by_pos_machine3_id(self.id) || Product.find_by_pos_machine4_id(self.id)
    true
  end

  def upcase_save
    self.name = name.titleize rescue nil
  end

  def self.number(params)
    number = (PosMachine.first(:conditions => "name like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:pos_machine][:name][0]
    number = (PosMachine.first(:conditions => "name like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_pos_machine_id(pos_machine)
    id = (PosMachine.first(:conditions => "code = '#{pos_machine}' or name = '#{pos_machine}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["name", "office", "hide_empty_stock", "enable_ppn", "enable_minus_stock", "enable_loss_price", "receipt_footer", "eod_footer"]
      all.each do |pos_machine|
        csv << [pos_machine.name, pos_machine.head_office.office_name, pos_machine.hide_empty_stock, pos_machine.enable_ppn, pos_machine.enable_minus_stock, pos_machine.enable_loss_price, pos_machine.receipt_footer, pos_machine.eod_footer]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["name", "office", "hide_empty_stock", "enable_ppn", "enable_minus_stock", "enable_loss_price", "receipt_footer", "eod_footer"]
      all.each do |pos_machine|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["name"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        office_name = Office.find_by_office_name(row["office"]).id rescue 0
        pos_machine = new(parameters.permit(:name, :office_id, :hide_empty_stock, :enable_ppn, :enable_minus_stock, :enable_loss_price, :receipt_footer, :eod_footer).merge(:office_id => office_name))
        unless pos_machine.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{pos_machine.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{pos_machine.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 0, message: "Successfully imported"}
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