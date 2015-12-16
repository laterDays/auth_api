module Api 
	module V1
		class AwsCognitoAuthController < ApplicationController
			protect_from_forgery with: :null_session
			before_action :doorkeeper_authorize! # Require access token for all actions
			respond_to :json

			def new
				#bearer = OauthAccessGrants.find(1, :conditions => ("token = " + params[:token]))
				token = request.headers['Authorization']
				token.gsub!("Bearer ", "")
				bearer = ActiveRecord::Base.connection.execute("SELECT resource_owner_id FROM oauth_access_grants WHERE (token = '" + token + "')")
				logger.info "[ ] AwsCognitoAuthController.new(), bearer: " + bearer.to_s

				if bearer.to_s != ''
					Aws.config.update({
					    region: ENV['S3_REGION'],
						credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY'])
					})

					cognito = Aws::CognitoIdentity::Client.new(region:ENV['S3_REGION'])
					resp = cognito.get_open_id_token_for_developer_identity(
					           identity_pool_id: ENV['IDENTITY_POOL_ID'], 
					           logins: {ENV['IDENTITY_POOL_PROVIDER'] => bearer.to_s})
					
					logger.info "[ ] AwsCognitoAuthController.new(), response: " + resp.to_json
				else
					logger.info "[ ] AwsCognitoAuthController.new(), error, token bearer not found."
					resp = {"error" => "token bearner not found."}
				end
				respond_with(resp)
			end
		end
	end
end