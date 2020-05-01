class MemberLevel < ActiveRecord::Base
  JOIN = ''
  ORDER = 'member_levels.id'
  SELECTED = 'member_levels.*'
  GROUP_BY = 'member_levels.id'

  validates :description, :presence => true, :length => {:minimum => 3, :maximum => 50}, :uniqueness => true
  validates :level, presence: true, :uniqueness => true
  validates :minimum_amount, presence: true
  validates :discount_percent, presence: true

  scope :search, lambda {|search|{
    :order => "level ASC",
    :conditions => [
      'level LIKE ? OR description LIKE ?',
      "%#{search.first}%", "%#{search.first}%"
    ]
  }}

  def self.number(params)
    number = (MemberLevel.first(:conditions => "description like '#{params[:first_char]}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.create_number(params)
    init = params[:member_level][:description][0]
    number = (MemberLevel.first(:conditions => "description like '#{init}%'", :order => "id DESC").code[1..-1].to_i rescue 0)+1
    return number
  end

  def self.get_member_level_id(member_level)
    id = (MemberLevel.first(:conditions => "level = '#{member_level}' or description = '#{member_level}'", :order => "id DESC").id.to_i rescue 0)
    return id
  end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["description", "level", "minimum_amount", "discount_percent"]
      all.each do |member_level|
        csv << [member_level.description, member_level.level, member_level.minimum_amount, member_level.discount_percent, member_level.allow_credit]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["description", "level", "minimum_amount", "discount_percent", "allow_credit"]
      all.each do |member_level|
      end
    end
  end

  def self.import(file)
    CSV.foreach(file.path, headers: true) do |row|
    if find_by_description(row["description"].upcase).nil?
      member_level = find_by_level(row["level"]) || new
      parameters = ActionController::Parameters.new(row.to_hash)
      member_level.update(parameters.permit(:description, :level, :minimum_amount, :discount_percent, :allow_credit))
      member_level.save
    else
      return "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Must unique"
    end
    end
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
