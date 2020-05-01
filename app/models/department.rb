class Department < MClass

  self.table_name = 'm_classes'
  before_validation :upcase_save

  has_many :brands

  has_many :office_departments, :dependent => :destroy
  has_many :supplier_departments, dependent: :destroy
  has_many :suppliers, class_name: 'MClass', through: :supplier_departments
 validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"#, uniqueness: true
  validates :name, uniqueness: true
  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ? OR name LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def upcase_save
    self.name = name.titleize rescue nil
  end

  def self.number(params)
    number = (Department.first(:conditions => "name like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:department][:name][0]
    number = (Department.first(:conditions => "name like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_department_id(department)
    id = (Department.first(:conditions => "code = '#{department}' or name = '#{department}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["name"]
    end
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["code", "name"]
      Department.where("parent_id IS NULL").each do |department|
        csv << ["#{"'" if department.code[0] == '0'}#{department.code}", department.name]
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      return {error: 1, message: "Wrong CSV Format"} if row["name"].blank?
      if find_by_name(row["name"].upcase).nil?
        #department = new
        parameters = ActionController::Parameters.new(row.to_hash)
        department = new(parameters.permit(:name).merge(code: "D#{((sprintf '%03d', ((MClass.where("parent_id IS NULL").order("id DESC").limit(1).last.code.gsub('D', '').to_i rescue 0)+1)))}", level: 0))
        unless department.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{department.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{department.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}"}
      end
    end
    return {error: 0, message: "Department successfully imported"}
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
