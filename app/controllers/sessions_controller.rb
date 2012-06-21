class SessionsController < ApplicationController
	def new
		@user = User.new
	end

	def create
		user = User.find_by_email(params[:session][:email])
		if user and user.authenticate(params[:session][:password])
			flash[:success] = "Logged in: #{user.name}"
			sign_in user
			redirect_to user
		else
			flash[:error] = "Invalid email and/or password"
			render 'new'
		end
	end

	def destroy
		sign_out
		redirect_to root_path
	end
end
