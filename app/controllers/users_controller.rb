class UsersController < ApplicationController
	before_filter :signed_in_user, only: [:edit, :update]
	before_filter :correct_user, only: [:edit, :update]

	def new
		@user = User.new
	end

	def create
		@user = User.new(params[:user])
		if @user.save
			sign_in @user
			redirect_to @user
		else
			render 'new'
		end
	end

	def show
		@user = User.find(params[:id])
		@character_list =  Character.find_all_by_user_id(@user.id)
	end

	def edit
		@user = User.find(params[:id])
	end

	def update
		@user = User.find(params[:id])

		if @user and @user.authenticate params[:user][:password]

			if params[:user][:new_password]
				# change password
				@user.password = params[:user][:new_password]
				@user.password_confirmation = params[:user][:new_password_confirmation]
				if @user.save
					redirect_to @user, flash: { success: "Password Changed" }
				else
					flash.now[:error] = "Error: #{@user.errors.full_messages.join(', ')}"
					render 'edit'
				end
			else
				# change user details
				params[:user][:password_confirmation] = params[:user][:password]

				if @user.update_attributes(params[:user])
					redirect_to @user, flash: { success: "Updated Details" }
				else
					flash.now[:error] = "Error: #{@user.errors.full_messages.join(', ')}"
					render 'edit'
				end
			end
		else
			flash.now[:error] = "Incorrect Password"
			render 'edit'
		end
	end

	private

	def signed_in_user
		redirect_to signin_path, notice: 'Please Sign In' unless signed_in?
	end

	def correct_user
		@user = User.find(params[:id])
		redirect_to @user, flash: { error: 'You may only edit your own profile' } unless @user == current_user
	end
end
