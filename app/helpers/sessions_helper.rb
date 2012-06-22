module SessionsHelper

	def sign_in(user)
		session[:current_user_id] = user.id
		self.current_user = user
		deactivate
	end

	def sign_out
		self.current_user = nil
		self.active_character = nil
		session.delete :current_user_id
		session.delete :active_character_id
	end

	def current_user=(user)
		@current_user = user
	end

	def current_user
		@current_user ||= User.find(session[:current_user_id]) unless @current_user.nil? and session[:current_user_id].nil?
	end

	def signed_in?
		not current_user.nil?
	end

	def current_user_owns?(character)
		character.user_id == self.current_user.id if self.current_user
	end

	def activate(character)
		session[:active_character_id] = character.id
		self.active_character = character
	end

	def deactivate
		session.delete :active_character_id
		self.active_character = nil
	end

	def active_character=(character)
		@active_character = character
	end

	def active_character
		@active_character || Character.find(session[:active_character_id]) unless @active_character.nil? and session[:active_character_id].nil?
	end

	def activated_character?
		not active_character.nil?
	end
end
