class CampaignsController < ApplicationController
	before_filter :signed_in_user, except: [:show, :index]
	before_filter :correct_user, except: [:show, :index, :new, :create, :join]

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

		if @campaign.visible_to? current_user
			current_user.push_active_campaign(@campaign) if signed_in?
			@characters = Character.find_all_by_campaign_id(@campaign.id)
		else
			redirect_to campaigns_path, flash: { error: "Cannot access Campaign" }
		end
	end

	def index
		@campaigns = Campaign.all.sort_by { |campaign| campaign.name }
	end

	def join
		@campaign = Campaign.find(params[:id])
		@membership = @campaign.membership_for current_user

		case @membership.membership
		when :none
			@membership.membership = :request
			@membership.save
			redirect_to @campaign, flash: { success: 'Requested to Join' }
		when :invite
			@membership.membership = :member
			@membership.save
			redirect_to @campaign, flash: { success: "Joined Campaign" }
		when :member, :admin
			redirect_to @campaign, flash: { error: "Already a Member" }
		when :request
			redirect_to @campaign, flash: { warning: "Already Requested Membership" }
		when :denied
			redirect_to @campaign, flash: { error: "Denied Membership" }
		end
	end

	def invite
		@campaign = Campaign.find(params[:id])
		@membership = @campaign.membership_for params[:user_id].to_i
		@user = User.find params[:user_id]

		case @membership.membership
		when :request
			@membership.membership = :member
			@membership.save
			redirect_to @campaign, flash: { success: "Added Member: #{@user.handle}" }
		when :none, :denied
			@membership.membership = :invite
			@membership.save
			redirect_to @campaign, flash: { success: "Invited Member: #{@user.handle}" }
		when :member, :admin
			redirect_to @campaign, flash: { error: "Already a Member: #{@user.handle}" }
		when :invite
			redirect_to @campaign, flash: { warning: "Already Invited: #{@user.handle}" }
		end
	end

	def deny
		@campaign = Campaign.find(params[:id])
		@user = User.find params[:user_id]
		@membership = @campaign.membership_for params[:user_id].to_i

		case @membership.membership
		when :none, :request, :invite
			@membership.membership = :denied
			@membership.save
			redirect_to @campaign, flash: { success: "Denied Member: #{@user.handle}" }
		when :member
			@membership.membership = :denied
			@membership.save
			redirect_to @campaign, flash: { success: "Kicked Member: #{@user.handle}" }
		when :admin
			redirect_to @campaign, flash: { error: "Cannot Kick Admin: #{@user.handle}" }
		when :denied
			redirect_to @campaign, flash: { warning: "Already Denied: #{@user.handle}" }
		end
	end

	def clear
		@campaign = Campaign.find(params[:id])
		@user = User.find params[:user_id]
		@membership = @campaign.membership_for params[:user_id].to_i

		case @membership.membership
		when :invite, :request, :denied
			@membership.delete
			redirect_to @campaign, flash: { success: "Cleared Member: #{@user.handle}" }
		when :member, :admin
			redirect_to @campaign, flash: { error: "Cannot Clear Full Member: #{@user.handle}" }
		when :none
			redirect_to @campaign, flash: { warning: "Alread Cleared: #{@user.handle}" }
		end
	end

	def admin
		@campaign = Campaign.find(params[:id])
		@user = User.find params[:user_id]
		@membership = @campaign.membership_for params[:user_id].to_i

		case @membership.membership
		when :admin
			redirect_to @campaign, flash: { warning: "Already Admin: #{@user.handle}" }
		else
			@membership.membership = :admin
			@membership.save
			redirect_to @campaign, flash: { success: "Added Admin: #{@user.handle}" }
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
