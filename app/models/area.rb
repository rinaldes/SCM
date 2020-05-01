class Area < Zone
  belongs_to :city
  belongs_to :regional
  has_many :stores
  validates :city_id, presence: true 
  validates :regional_id, presence: true
  validates :name, presence: true, uniqueness: true
  validates :code, uniqueness: true
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only", uniqueness: true

  HUMANIZED_ATTRIBUTES = {
    :city_id => "Branch"
  }
  def self.human_attribute_name(attr, options={})
    HUMANIZED_ATTRIBUTES[attr.to_sym] || super
  end

  def check_transaction
    return false if Office.find_by_area_id(self.id)
    true
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["code","name","city_id","regional_id","description"]
    end
  end

  def self.to_csv(areas, options = {})
    CSV.generate(options) do |csv|
      csv << ["code", "name", "city_id", "regional_id", "description"]
      all.each do |area|
        #regional = Regional.find(area.regional_id).name
        #if area.city.present?
          csv << [area.code, area.name, area.city_name, area.regional_name, area.description]
        #end
      end
    end
  end

    def self.number(params)
      number = (Area.first(:conditions => "code like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
      return number
    end

    def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      return {error: 1, message: "Wrong CSV Format"} if row["code"].blank?

      if find_by_code(row["code"]).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        area = new(parameters.permit(:code, :name, :regional_id, :city_id, :description))
        unless area.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{area.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. #{area.errors.full_messages.join('<br/>')}"}
        end
        line += 1
      else
        return {error: 1, message: "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line}. Code Are Already Existed."}
      end
    end
    return {error: 0, message: "Area successfully imported"}
  end
end
