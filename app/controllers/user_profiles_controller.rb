class UserProfilesController < ApplicationController
  def update_profile
    @user = User.find(params[:id])
    respond_to do |format|
        #@user.update_attributes(user_params)
      if @user.update_attributes(user_params)
        flash[:notice] = "User was successfully updated."
        format.html { redirect_to users_path }
      else
        flash.now[:error] = @user.errors.full_messages
        format.html {render 'edit'}
      end
    end
  end

  def index
    @user_profiles = User.find(current_user.id)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @user_profile = User.find(current_user.id)
    respond_to do |format|
      format.html
    end
  end

  def update
    @user_profile = User.find(current_user.id)
    respond_to do |format|
      if @user_profile.update_attributes(user_params)
        flash[:notice] = "User was successfully updated."
        format.html { redirect_to user_profiles_path }
      else
        flash.now[:error] = @user_profile.errors.full_messages
        format.html {render 'edit'}
      end
    end
  end

private
  def user_params
    params.require(:user).permit(:first_name, :last_name, :gender, :birth_place, :birth_date, :email, :role_id, :status, :username, :image, :password, :password_confirmation,
      :head_office_id, :branch_id)
  end

end