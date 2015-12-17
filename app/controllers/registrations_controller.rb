class RegistrationsController < Devise::RegistrationsController
  skip_before_filter  :verify_authenticity_token
  def create
  	logger.info params
    @user = User.create(params[:user])
    if @user.save
      render :json => {:state => {:code => 0}, :data => @user }
    else
      render :json => {:state => {:code => 1, :messages => @user.errors.full_messages} }
    end

  end
end