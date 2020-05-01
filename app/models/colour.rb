class Colour < ActiveRecord::Base
#  include Filter
  JOIN = ''
  ORDER = 'colours.id'
  SELECTED = 'colours.*'
  GROUP_BY = 'colours.id'

  before_validation :upcase_save
  #before_destroy :goods_already_in_used?

  #has_many :goods, class_name: "Goods", dependent: :destroy

  validates :name, :presence => {message: 'required'} , :uniqueness => true
  validates_format_of :name, :with => /^[a-zA-Z\d\s]*$/i, :multiline => true, :message => "alphabet input only"

  scope :search, lambda {|search|{
    :order => "code ASC",
    :conditions => [
      'code LIKE ? OR name LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def check_transaction
    return false if Product.find_by_colour_id(self.id) || Product.find_by_colour2_id(self.id) || Product.find_by_colour3_id(self.id) || Product.find_by_colour4_id(self.id)
    true
  end

  def upcase_save
    self.name = name.titleize rescue nil
  end
=begin
  def goods_already_in_used?
    return true
    #goods.each{|item|return false if item.check_relation}
  end
=end
  def self.number(params)
    number = (Colour.first(:conditions => "name like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:colour][:name][0]
    number = (Colour.first(:conditions => "name like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_colour_id(colour)
    id = (Colour.first(:conditions => "code = '#{colour}' or name = '#{colour}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["code", "name"]
      all.each do |colour|
        csv << [colour.code, colour.name]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["name"]
      all.each do |colour|
      end
    end
  end

  def self.import(file)
    line = 0
    CSV.foreach(file.path, headers: true) do |row|
      if find_by_name(row["name"].upcase).nil?
        parameters = ActionController::Parameters.new(row.to_hash)
        colour = new(parameters.permit(:name).merge(:code => "C#{('%03d' % ((Colour.last.code.gsub('C', '').to_i rescue 0)+1))}"))
        unless colour.save
          return {error: 1, message: line == 0 ? "Import failed, please recheck CSV file. #{colour.errors.full_messages.join('<br/>')}" : "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Please recheck and reupload from line #{line+1}. #{colour.errors.full_messages.join('<br/>')}"}
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
