module SessionsHelper

	def sign_in(user)
		self.current_user = user
	end

	def sign_out
		self.current_user = nil
	end

	def current_user=(user)
		@current_user = user
		if user.nil?
			session.delete :current_user_id
		else
			session[:current_user_id] = user.id
		end
	end

	def current_user
		@current_user ||= User.find(session[:current_user_id]) unless session[:current_user_id].nil?
	end

	def signed_in?
		not current_user.nil?
	end

	def current_user_owns?(character_or_campaign)
		return false if current_user.nil?

		case character_or_campaign
		when Character then character_or_campaign.user_id == current_user.id
		when Campaign then character_or_campaign.has_admin? current_user
		end
	end

	def visible?(character)
		return true if current_user_owns? character

		case character.privacy
		when :public then true
		when :campaign then character.in_campaign? and character.campaign.has_member? current_user
		when :private then false
		end
	end

	def active_character
		current_user.active_character if signed_in? and current_user_owns? current_user.active_character
	end

	def active_campaign
		current_user.active_campaign if signed_in? and current_user_owns? current_user.active_campaign
	end
end
