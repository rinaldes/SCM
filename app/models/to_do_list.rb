class ToDoList < ActiveRecord::Base
	JOIN = ''
  ORDER = 'to_do_lists.id'
  SELECTED = 'to_do_lists.*'
  GROUP_BY = 'to_do_lists.id'
  belongs_to :user

	has_many :branch_to_do_lists, :dependent => :destroy
	has_many :offices, through: :branch_to_do_lists
	validate :has_branches


  validates :date, :presence => {:message => 'required'}
  validates :end_at, :presence => {:message => 'required'}

  cattr_accessor :current_user

  mount_uploader :image, ImageUploader

	def has_branches
		errors.add(:base, 'Destination must select one or more') if self.branch_to_do_lists.blank?
	end

  def self.to_csv(options = {})
    CSV.generate(options) do |csv|
      csv << ["date", "time", "username", "destination", "description", "status"]
      all.each do |to_do_list|
        a = to_do_list.tujuan.split(';').join(', ')
        csv << [to_do_list.date, to_do_list.time.strftime("%I:%M:%S %p"), to_do_list.user.username, a, to_do_list.description, to_do_list.status]
      end
    end
  end

  def self.to_csv2(options = {})
    CSV.generate(options) do |csv|
      csv << ["date", "time", "destination", "description", "status"]
      all.each do |to_do_list|
      end
    end
  end

  def self.import(file)
    line = 0

    CSV.foreach(file.path, headers: true) do |row|
      #if find_by_name(row["description"].upcase).first.nil?
        to_do_list = new
        parameters = ActionController::Parameters.new(row.to_hash)
        #to_do_list.update(parameters.permit(:date, :time, :description, :status).merge(:code => (('%03d' % ((ToDoList.last.code.to_i rescue 0)+1)))).merge(:tujuan => row["destination"]).merge(:user_id => current_user.id))
        #to_do_list.save! rescue (return "ToDoList successfully imported until line #{line}. Department failed imported  from line #{line+1}. Please rechecked the row")
        to_do_list.update(parameters.permit(:date, :time, :description, :status).merge(:code => (('%03d' % ((ToDoList.last.code.to_i rescue 0)+1)))).merge(:tujuan => row["destination"]).merge(:user_id => ToDoList.current_user.id))
        to_do_list.save
        line += 1
      #else
      #  return "Successfully imported until line #{line}. Failed imported  from line #{line+1}. Must unique"
      #end
    end
    return "To Do List Successfully imported"
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
