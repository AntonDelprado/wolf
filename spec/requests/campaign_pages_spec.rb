require 'spec_helper'

describe 'Campaign Pages' do

	subject { page }

	let(:user) { FactoryGirl.create(:user) }
	let(:other_user) { FactoryGirl.create(:other_user) }
	let(:open_campaign) { FactoryGirl.create(:open_campaign) }
	let(:closed_campaign) { FactoryGirl.create(:closed_campaign) }
	let(:character) { FactoryGirl.create(:public_character, user_id: user.id, campaign_id: open_campaign.id) }
	let(:priv_character) { FactoryGirl.create(:private_character, user_id: user.id) }

	before do
		character.save
		priv_character.save
	end

	describe 'public access' do

		describe 'to campaigns path' do
			before { visit campaigns_path }

			it 'should show page' do
				should have_selector('title', text: 'Campaigns')
				should have_selector('h1', text: 'Campaign List')
			end

			it 'should show open campaign' do
				should have_link(open_campaign.name)
			end

			it 'should not show closed campaign' do
				should_not have_link(closed_campaign.name)
			end
		end

		describe 'to open campaign path' do
			before do
				open_campaign.add_member user
				visit campaign_path(open_campaign)
			end

			it 'should show page' do
				should have_selector('title', text: open_campaign.name)
			end

			it 'should display correctly' do
				should have_selector('h1', text: open_campaign.name)
				should have_selector('h4', text: 'Privacy: Open')
				should have_selector('h3', text: open_campaign.description)
				should have_table('member-table', rows: [['1', user.handle, 'Member']])
				should have_link(user.handle)
				should_not have_link(other_user.handle)
			end
		end

		describe 'to closed campaign path' do
			before { visit campaign_path(closed_campaign) }

			it 'should redirect to campaigns' do
				should have_selector('title', text: 'Campaigns')
				should have_selector('div.alert.alert-error', text: 'Cannot access Campaign')
			end
		end

		describe 'to edit campaign path' do
			before { visit edit_campaign_path(open_campaign) }

			it 'should redirect to sign in' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'Please Sign In')
			end
		end

		describe 'to join campaign path' do
			before { visit join_campaign_path(open_campaign) }

			it 'should redirect to sign in' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'Please Sign In')
			end
		end

		describe 'to invite campaign path' do
			before { visit invite_campaign_path(open_campaign) }

			it 'should redirect to sign in' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'Please Sign In')
			end
		end

		describe 'to new campaign path' do
			before { visit new_campaign_path }

			it 'should redirect to sign in' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'Please Sign In')
			end
		end
	end

	describe 'private access' do
		before do
			visit signin_path
			fill_in 'Email', with: other_user.email
			fill_in 'Password', with: other_user.password
			click_button 'Sign In'
		end

		describe 'to new campaign path' do
			before { visit new_campaign_path }

			it 'should display' do
				should have_selector('title', text: 'Create Campaign')
				should have_selector('h1', text: 'Create New Campaign')
			end

			describe 'providing valid information' do
				let(:campaign_name) { 'Name of New Campaign' }
				let(:description) { 'Description of New Campaign' }
				before do
					fill_in 'Name', with: campaign_name
					fill_in 'Description', with: description
				end

				it 'should create campaign' do
					expect { click_button 'Create Campaign' }.to change(Campaign, :count).by(1)
					should have_selector('title', text: campaign_name)
					should have_selector('h1', text: campaign_name)
					should have_selector('h3', text: description)
					Campaign.find_by_name(campaign_name).should have_admin(other_user)
				end

			end

			describe 'providing invalid information' do
				it 'should not create campaign' do
					expect { click_button 'Create Campaign' }.not_to change(Campaign, :count)
					should have_selector('title', text: 'Create Campaign')
					should have_selector('div.alert.alert-error', text: 'error')
				end
			end
		end

		describe 'to campaigns page' do
			before { visit campaigns_path }

			it 'should display' do
				should have_selector('title', text: 'Campaigns')
			end

			it 'should show public campaign' do
				should have_link(open_campaign.name)
			end

			it 'should not show closed campaign' do
				should_not have_link(closed_campaign.name)
			end
		end

		describe 'to open campaign' do
			before { visit campaign_path(open_campaign) }

			it 'should display' do
				should have_selector('title', text: open_campaign.name)
				should have_selector('h1', text: open_campaign.name)
			end
		end

		describe 'to closed campaign' do
			before { visit campaign_path(closed_campaign) }

			it 'should redirect to campaigns' do
				should have_selector('title', text: 'Campaigns')
				should have_selector('div.alert.alert-error', text: 'Cannot access Campaign')
			end
		end

		describe 'to edit campaign' do
			before { visit edit_campaign_path(open_campaign) }

			it 'should redirect to campaign' do
				should have_selector('title', text: open_campaign.name)
				should have_selector('div.alert.alert-error', text: 'You do not have permission for that action')
			end
		end

		describe 'to invite campaign' do
			before { visit edit_campaign_path(open_campaign) }

			it 'should redirect to campaign' do
				should have_selector('title', text: open_campaign.name)
				should have_selector('div.alert.alert-error', text: 'You do not have permission for that action')
			end
		end

		describe 'to join' do
			describe 'open campaign' do
				before do
					visit join_campaign_path(open_campaign)
				end
				let(:membership) { CampaignMember.find_by_campaign_id_and_user_id(open_campaign.id, other_user.id) }


				it 'should create request' do
					should have_selector('title', text: open_campaign.name)
					should have_selector('div.alert.alert-success', text: 'Requested to Join')
					should have_selector('h3', text: 'Request Pending')
					membership.should_not be_nil
					membership.membership.should == :request
				end
			end

			describe 'closed campaign' do
				before { visit join_campaign_path(closed_campaign) }

				it 'should redirect to campaigns' do
					should have_selector('title', text: 'Campaigns')
					should have_selector('div.alert.alert-error', text: 'Cannot access Campaign')
				end
			end
		end

		describe 'when admin' do
			before { open_campaign.add_member(other_user, :admin) }

			describe 'viewing campaigns page' do
				before { visit campaigns_path }

				it 'should show as admin' do
					should have_selector('title', text: 'Campaigns')
					open_campaign.should have_admin(other_user)
					should have_selector('p', text: 'Admin')
				end
			end

			describe 'viewing campaign page' do
				before { visit campaign_path(open_campaign) }

				it 'should show as admin' do
					should have_selector('title', text: open_campaign.name)
					should have_table('member-table', rows: [['1', other_user.handle, 'Admin', '', '']])
				end
			end

			describe 'with admin' do
				before { open_campaign.add_member user, :admin }

				describe 'viewing campaign page' do
					before { visit campaign_path(open_campaign) }

					it 'should display correctly' do
						should have_selector('title', text: open_campaign.name)
						should have_table('member-table', rows: [
							['1', other_user.handle, 'Admin', '', ''],
							['2', user.handle, 'Admin', '', '']])
					end
				end
			end

			describe 'with member' do
				before do
					open_campaign.add_member user
					visit campaign_path(open_campaign)
				end

				it 'should display correctly' do
					should have_selector('title', text: open_campaign.name)
					should have_table('member-table', rows: [
						['1', other_user.handle, 'Admin', '',''],
						['2', user.handle, 'Member', 'Admin', 'Kick']])
				end

				describe 'then kick member' do
					it 'should remove member and show page' do
						expect { click_link 'Kick'; open_campaign.reload }.to change{ open_campaign.members.count }.from(2).to(1)
						should have_selector('title', text: open_campaign.name)
						should have_selector('div.alert.alert-success', text: "Kicked Member: #{user.handle}")
						open_campaign.member_type(user).should == :denied
					end

					describe 'then clear member' do
						before { click_link 'Kick' }

						it 'should clear membership' do
							expect { click_link 'Clear' }.to change { CampaignMember.all.count }.by(-1)
							should have_selector('title', text: open_campaign.name)
							should have_selector('div.alert.alert-success', text: "Cleared Member: #{user.handle}")
							open_campaign.member_type(user).should be_nil
						end
					end
				end

				describe 'then add to admin' do
					before { click_link 'Admin' }

					it 'should add to admin' do
						should have_selector('title', text: open_campaign.name)
						should have_selector('div.alert.alert-success', text: 'Added Admin')
						open_campaign.should have_admin(user)
						should have_table('member-table', rows: [
							['1', other_user.handle, 'Admin', '', ''],
							['2', user.handle, 'Admin', '', '']])
					end
				end
			end

			describe 'with requested' do
				before do
					open_campaign.add_member user, :request
					visit campaign_path(open_campaign)
				end

				it 'should display correctly' do
					should have_selector('title', text: open_campaign.name)
					should have_table('member-table', rows:	[
						['1', other_user.handle, 'Admin', '', ''],
						['', user.handle, 'Requesting to Join', 'Accept', 'Deny']])
				end

				describe 'add requested' do
					it 'should add correctly' do
						expect { click_link 'Accept'; open_campaign.reload }.to change { open_campaign.members.count }.by(1)
						should have_selector('title', text: open_campaign.name)
						open_campaign.should have_member(user)
						should have_table('member-table', rows: [
							['1', other_user.handle, 'Admin', '',''],
							['2', user.handle, 'Member', 'Admin', 'Kick']])
					end
				end

				describe 'deny requested' do
					before { click_link 'Deny' }

					it 'should deny correctly' do
						should have_selector('title', text: open_campaign.name)
						open_campaign.member_type(user).should == :denied
						should have_table('member-table', rows: [
							['1', other_user.handle, 'Admin', '', ''],
							['', user.handle, 'Denied Membership', 'Clear', '']])
					end
				end
			end

			describe 'with invited' do
				before do
					open_campaign.add_member user, :invite
					visit campaign_path(open_campaign)
				end

				it 'should display correctly' do
					should have_selector('title', text: open_campaign.name)
					should have_table('member-table', rows: [
						['1', other_user.handle, 'Admin', '',''],
						['', user.handle, 'Invited to Join', '', 'Revoke']])
				end

				describe 'revoke request' do
					before do
						click_link 'Revoke'
						open_campaign.reload
					end

					it 'should revoke and display' do
						should have_selector('title', text: open_campaign.name)
						open_campaign.member_type(user).should be_nil
					end
				end
			end

			describe 'with denied' do
				before do
					open_campaign.add_member user, :denied
					visit campaign_path(open_campaign)
				end

				it 'should display correctly' do
					should have_selector('title', text: open_campaign.name)
					should have_table('member-table', rows: [
						['1', other_user.handle, 'Admin', '', ''],
						['', user.handle, 'Denied Membership', 'Clear','']])
				end

				describe 'click cleared' do
					before do
						click_link 'Clear'
						open_campaign.reload
					end

					it 'should display and clear' do
						open_campaign.member_type(user).should be_nil
						should have_selector('title', text: open_campaign.name)
						should have_table('member-table', rows:[['1', other_user.handle, 'Admin', '','']])
					end
				end
			end
		end

		describe 'when invited' do
			before { open_campaign.add_member other_user, :invite }

			describe 'to campaigns path' do
				before { visit campaigns_path }

				it 'should display correctly' do
					should have_selector('title', text: 'Campaigns')
					should have_selector('p', text: 'Invited to Join')
				end
			end

			describe 'to campaign path' do
				before { visit campaign_path(open_campaign) }

				it 'should display correctly' do
					should have_selector('title', text: open_campaign.name)
					should have_link('Accept Invitation')
				end

				it 'should join correctly' do
					expect { click_link 'Accept Invitation'; open_campaign.reload }.to change { open_campaign.members.count }.by(1)
					should have_selector('title', text: open_campaign.name)
					should have_selector('div.alert.alert-success', text: 'Joined Campaign')
					open_campaign.should have_member(other_user)
					should have_table('member-table', rows: [['1', other_user.handle, 'Member']])
				end
			end

			describe 'to a closed campaign,' do
				let(:closed_campaign) { open_campaign }
				before do
					closed_campaign.visibility = :closed
					closed_campaign.save
				end

				describe 'campaigns page' do
					before { visit campaigns_path }

					it 'should show closed campaign' do
						should have_selector('title', text: 'Campaigns')
						should have_link(open_campaign.name)
						should have_selector('p', text: 'Invited to Join')
					end
				end

				describe 'campaign page' do
					before { visit campaign_path(closed_campaign) }

					it 'should display' do
						should have_selector('title', text: closed_campaign.name)
					end
				end

				describe 'edit_campaign_path' do
					before { visit edit_campaign_path(closed_campaign) }

					it 'should redirect to campaign path' do
						should have_selector('title', text: closed_campaign.name)
						should have_selector('div.alert.alert-error', text: 'You do not have permission for that action')
					end
				end
			end
		end

		describe 'when member' do
			before { open_campaign.add_member(other_user) }

			describe 'campaigns page' do
				before { visit campaigns_path }

				it 'should display membership' do
					should have_selector('title', text: 'Campaigns')
					should have_selector('p', text: 'Member')
				end
			end

			describe 'campaign page' do
				before { visit campaign_path(open_campaign) }

				it 'should display' do
					should have_selector('title', text: open_campaign.name)
				end
			end

			describe 'edit_campaign_path' do
				before { visit edit_campaign_path(open_campaign) }

				it 'should redirect to campaign path' do
					should have_selector('title', text: open_campaign.name)
					should have_selector('div.alert.alert-error', text: 'You do not have permission for that action')
				end
			end

			describe 'invite_campaign_path' do
				before { visit edit_campaign_path(open_campaign) }

				it 'should redirect to campaign path' do
					should have_selector('title', text: open_campaign.name)
					should have_selector('div.alert.alert-error', text: 'You do not have permission for that action')
				end
			end
		end

		describe 'when denied' do
			before { open_campaign.add_member other_user, :denied }

			describe 'visit campaign path' do
				before { visit campaign_path(open_campaign) }

				it 'should display correctly' do
					should have_selector('title', text: open_campaign.name)
					should have_selector('h3', text: 'Request Denied')
				end
			end

			describe 'visit campaigns path' do
				before { visit campaigns_path }

				it 'should display correctly' do
					should have_selector('title', text: 'Campaigns')
					should have_selector('p', text: 'Denied')
				end
			end

			describe 'visit campaigns path for private campaign' do
				before do
					open_campaign.visibility = :closed
					open_campaign.save
					visit campaigns_path
				end

				it 'should not appear' do
					should have_selector('title', text: 'Campaigns')
					should_not have_link(open_campaign.name)
				end
			end
		end

		describe 'when requested' do
			before { open_campaign.add_member other_user, :request }

			describe 'visit campaigns page' do
				before { visit campaigns_path }

				it 'should display' do
					should have_selector('title', text: 'Campaigns')
					should have_selector('p', text: 'Requesting to Join')
				end
			end

			describe 'visit campaign page' do
				before { visit campaign_path(open_campaign) }

				it 'should display' do
					should have_selector('title', text: open_campaign.name)
					should have_selector('h3', text: 'Request Pending')
				end
			end
		end
	end

end
