class Api::SessionsController < Devise::SessionsController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :check_current_user, :check_permitted_page
  skip_before_filter :protect_from_forgery
  prepend_before_filter :require_no_authentication, :only => [:create]

  def create
=begin
example params
    params[:username] = 'superadmin'
    params[:password] = 'superadmin'
=end
    resource = User.find_for_database_authentication(username: params[:username])
    if resource && resource.valid_password?(params[:password])
      api_key = resource.api_key
      time_now = Time.now
      # unless api_key
        api_key = ApiKey.new access_token: SecureRandom.hex, user_id: resource.id, expired_at: time_now + 2.day unless api_key
        api_key.save
      # end
   
      sign_in(:user, resource)
      render json: {token_string: api_key.access_token,
        login_time: time_now.strftime("%Y-%m-%d %H:%M:%S"), id: current_user.id}, status: 200
    else
      render json: {token_string: '', login_time: Time.now.strftime("%Y-%m-%d %H:%M:%S"), id: 0}, status: 200
    end
  end
end
