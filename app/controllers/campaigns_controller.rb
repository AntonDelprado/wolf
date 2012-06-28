class CampaignsController < ApplicationController
	before_filter :signed_in_user, except: [:show, :index]
	before_filter :correct_user, only: [:edit, :update, :destroy]

	def new
		@campaign = Campaign.new
	end

	def create
		@campaign = Campaign.new(params[:campaign])
		@campaign.visibility = :open
		if @campaign.save
			@campaign.add_member current_user, :admin
			current_user.push_active_campaign(@campaign) if signed_in?
			redirect_to @campaign, flash: { success: "Campaign Created Successfully" }
		else
			render 'new'
		end
	end

	def show
		@campaign = Campaign.find(params[:id])

		if @campaign.open? or @campaign.has_member? current_user
			current_user.push_active_campaign(@campaign) if signed_in?
			@character_list = Character.find_all_by_campaign_id(@campaign.id)
		else
			redirect_to campaigns_path, flash: { error: "Cannot access Campaign" }
		end
	end

	def index
	end

	def join
		@campaign = Campaign.find(params[:id])
		member = CampaignMember.find_by_campaign_id_and_user_id(@campaign.id, current_user.id)

		if member.nil?
			member = CampaignMember.new campaign_id: @campaign.id, user_id: current_user.id, membership: :request
			member.save
			redirect_to @campaign, flash: { success: "Request Pending" }
		elsif member.membership == :invite
			member.membership = :member
			member.save
			redirect_to @campaign, flash: { success: "Successfully Joined Campaign" }
		else
			redirect_to @campaign, flash: { error: "Unknown Request" }
		end
	end

	def invite
		@campaign = Campaign.find(params[:id])

		if params.has_key? :request_id
			request = CampaignMember.find(params[:request_id])
			if request and (request.membership == :request or request.membership == :denied)
				request.membership = :member
				request.save
				redirect_to @campaign, flash: { success: "Successfully added: #{request.user.handle}" }
			else
				redirect_to @campaign, flash: { error: "Invalid Request ID"}
			end
		elsif params.has_key? :deny_id
			request = CampaignMember.find(params[:deny_id])
			if request
				request.membership = :denied
				request.save
				redirect_to @campaign, flash: { warning: "Denied: #{request.user.handle}" }
			else
				redirect_to @campaign, flash: { error: "Invalid Request ID"}
			end
		elsif params.has_key? :invite_id
			user = User.find(params[:invite_id])
			if user
				new_member = CampaignMember.find_by_campaign_id_and_user_id(@campaign.id, new_user.id)
				if new_member and new_member.membership == :request
					new_member.membership = :member
					new_member.save
					redirect_to @campaign, flash: { success: "Successfully added: #{user.handle}" }
				elsif new_member and new_member.membership == :deny
					new_member.membership = :invite
					new_member.save
					redirect_to @campaign, flash: { success: "Successfully invited: @{user.handle}"}
				elsif new_member.nil?
					new_member = CampaignMember.new campaign_id: @campaign.id, user_id: user.id, membership: :invite
					new_member.save
					redirect_to @campaign, flash: { success: "Successfully invited: @{user.handle}"}
				else
					redirect_to @campaign, flash: { error: "Invalid Request"}
				end
			else
				redirect_to @campaign, flash: { error: "Invalid User ID" }
			end
		else
			redirect_to @campaign, flash: { error: "Unknown Request" }
		end
	end

	def edit
		@campaign = Campaign.find(params[:id])
	end

	def update
		@campaign = Campaign.find(params[:id])

		if @campaign.update_attributes(params[:campaign])
			redirect_to @campaign, flash: { success: "Successfully Modified Campaign" }
		else
			flash.now[:error] = "Error: #{@campaign.errors.full_messages.join(', ')}"
			@campaign.reload
			render 'show'
		end
	end

	def destroy
		# destroy required
	end

	private

	def signed_in_user
		redirect_to signin_path, notice: 'Please Sign In' unless signed_in?
	end

	def correct_user
		@campaign = Campaign.find(params[:id])
		redirect_to @campaign, flash: { error: 'You do not have permission for that action' } unless @campaign.has_admin? current_user
	end
end
