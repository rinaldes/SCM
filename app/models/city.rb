class City < Zone
  validates :name, presence: true, uniqueness: true
  validates :regional_id, presence: true
  validates :code, uniqueness: true
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only", uniqueness: true
  has_many :areas, :dependent => :restrict_with_error
  has_many :offices, :dependent => :restrict_with_error
	belongs_to :regional

	  def self.to_csv2(options = {})
    	CSV.generate(options) do |csv|
      		csv << ["name","regional_id","description"]
    	end
  	end

  	def self.to_csv(options = {})
    	CSV.generate(options) do |csv|
      		csv << ["code", "name", "regional", "description"]
      		City.select("zones.*, regionals_zones.name AS regional_name").all.joins(:regional).each do |city|
        		csv << [city.code, city.name, city.regional_name, city.description]
      		end
      	end
    end

    def self.number(params)
      number = (City.first(:conditions => "code like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
      return number
    end

    def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      #return {error: 1, message: "Wrong CSV Format"} if row["code"].blank?

      if row["code"].nil? || find_by_code(row["code"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        city = new(parameters.permit(:name, :regional_id, :description).merge(code: (("BRANCH#{sprintf '%03d', ((City.where("code IS NOT NULL").order("id DESC").limit(1).last.code.gsub('BRANCH', '').to_i rescue 0)+1)}"))))
        unless city.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{city.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{city.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      elsif find_by_code(row["code"]).present?
        parameters = ActionController::Parameters.new(row.to_hash)
        city = City.find_by_code(row["code"])
        unless city.update(parameters.permit(:code, :name, :regional_id, :description))
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{city.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{city.errors.full_messages.join('<br/>')}"}
        end
        #return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. Code Are Already Existed."}
      end
    end
    return {error: 0, message: "Branch successfully imported"}
  end
end
