class Type < ActiveRecord::Base
  JOIN = ''
  ORDER = 'types.id'
  SELECTED = 'types.*'
  GROUP_BY = 'types.id'

  before_validation :upcase_save

  before_destroy :goods_already_in_used?

  has_many :goods, class_name: "Goods", dependent: :destroy
  has_many :subtype, class_name: "Type", foreign_key: :parent_id 

  validates :name, presence: {message: 'required'}, uniqueness: {message: 'used', :case_sensitive => false}

  scope :search, lambda {|search|{
    :conditions => ['name LIKE ? OR code LIKE ?', "%#{search.first}%", "%#{search.first}%"], :order => "code ASC"
  }}

  scope :master, -> { where(parent_id: nil) }

  def upcase_save
    self.name = name.upcase rescue nil
  end

  def goods_already_in_used?
    goods.each{|item|return false if item.check_relation}
    subtype.map{|sub_type| sub_type.goods.map{|item| (return false if item.check_relation) }}    
  end

end
