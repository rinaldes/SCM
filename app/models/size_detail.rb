class SizeDetail < ActiveRecord::Base
  belongs_to :size
  has_many :goods_sizes

  before_validation :upcase_save

  validates :size_number, presence: {message: 'required'}
  validates_format_of :size_number, :with => /^[a-zA-Z0-9\d\s]*$/i, :multiline => true, :message => "hanya mengijinkan angka dan huruf"

  def check_relation
    goods_size_already_in_used || GoodsRequest.find_by_size(size_number)
  end

  def upcase_save
    self.size_number = size_number.upcase rescue nil
  end

  def goods_size_already_in_used
    goods_sizes.each{|goods_size| return true if goods_size.check_relation}
  end

  def self.size_list(params)
    params[:page] = 1 if params[:page].blank?
    params[:per_page] = 10 if params[:per_page].blank?

    if params[:start_at].present? && params[:end_at].present?
      size_details = SizeDetail.where("size_id IS NOT NULL && size_number IS NOT NULL && updated_at >= ? && updated_at <= ?", params[:start_at], params[:end_at]).paginate(:page => params[:page], :per_page => params[:per_page])
    else
      size_details = SizeDetail.where("size_id IS NOT NULL && size_number IS NOT NULL").paginate(:page => params[:page], :per_page => params[:per_page])
    end

    size_details.map{|size_detail|{
        id: size_detail.id, keterangan: (size_detail.size.description rescue ''), kode_size: '%03d' % size_detail.size_number
    }}
  end
end
