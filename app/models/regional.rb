class Regional < Zone
  validates :name, presence: true, uniqueness: true
  validates :code, uniqueness: true
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only", uniqueness: true

	has_many :cities
  has_many :branches
  has_many :provinces

  def self.validate_name(params)
      return true if Regional.find_by_name(params[:name]).nil?
  end

	def self.to_csv2(options = {})
    	CSV.generate(options) do |csv|
      		csv << ["code","name","description"]
    	end
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      	csv << ["code", "name", "description"]
      	Regional.all.each do |regional|
        	csv << [regional.code, regional.name, regional.description]
      	end
      end
  end

  def check_transaction
    return false if City.find_by_regional_id(self.id) || Office.find_by_regional_id(self.id) || Area.find_by_regional_id(self.id)
    true
  end

  def self.number(params)
    number = (Regional.first(:conditions => "code like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      return {error: 1, message: "Wrong CSV Format"} if row["code"].blank?
      if find_by_code(row["code"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        regional = new(parameters.permit(:code, :name, :description))
        unless regional.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{regional.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{regional.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}."}
      end
    end
    return {error: 0, message: "Regional successfully imported"}
  end
end
