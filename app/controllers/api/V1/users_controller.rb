module Api 
	module V1
		class UsersController < ApplicationController
			# before_action :authenticate_user!
			protect_from_forgery with: :null_session
			before_action :doorkeeper_authorize! # Require access token for all actions
			respond_to :json

			def index
				logger.info User.all
				respond_with(User.all)
			end
		end
	end
end
