class SessionsController < Devise::SessionsController
	# POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options)
    logger.info "[ ] SessionsController.create() " + self.resource.to_json
    if @user.save
      render :json => {:state => {:code => 0}, :data => self.resource }
    else
      render :json => {:state => {:code => 1, :messages => self.resource.errors.full_messages} }
    end
  end
end