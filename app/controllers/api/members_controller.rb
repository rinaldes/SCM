class Api::MembersController < ApplicationController
#  before_filter :check_token
  skip_before_filter :authenticate_user!
  skip_before_filter :verify_authenticity_token

  def create
    member = []
    # delete_all when tahun, pekan, dist_id
    first_detail = ActiveSupport::JSON.decode(params[:member_details]).first
    #Member.delete_all#(["active = ? AND address_home = ? AND barcode = '#{first_detail["dist_id"]}' AND pcode = '#{first_detail["pcode"]}'", first_detail['tahun'].to_i,
      #first_detail["pekan"].to_i]) if Member.count != 0
    # save data api
    #run_sidekiq_if_killed
    Member.api(params[:member_details])
    render json: {status: 'success'}, status: 200
  end

  private
    def check_token
      #example params[:token]=
      access_token = User.find_by_authentication_token(params[:token])
      unless access_token
        render :json => {status: 'failed'}, :status => 200
      end
    end
end