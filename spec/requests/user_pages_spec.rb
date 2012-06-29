require 'spec_helper'

describe 'User Pages' do

	subject { page }

	let(:user) { FactoryGirl.create(:user) }
	let(:other_user) { FactoryGirl.create(:other_user) }
	let(:open_campaign) { FactoryGirl.create(:open_campaign) }
	let(:closed_campaign) { FactoryGirl.create(:closed_campaign) }
	let(:character) { FactoryGirl.create(:public_character, user_id: user.id, campaign_id: open_campaign.id) }
	let(:priv_character) { FactoryGirl.create(:private_character, user_id: user.id) }

	before do
		user.save
		other_user.save
		open_campaign.save
		closed_campaign.save
		character.save
		priv_character.save
	end

	describe 'public access' do

		describe 'to user path' do
			before do
				open_campaign.add_member user
				closed_campaign.add_member user
				visit user_path(user)
			end

			it 'should display correctly' do
				should have_selector('title', text: 'Profile')
				should have_selector('h1', text: user.handle)
				should have_link(open_campaign.name)
				should_not have_link(closed_campaign.name)
				should have_link(character.name)
				should_not have_link(priv_character.name)
			end
		end

		describe 'to edit user path' do
			before { visit edit_user_path(user) }

			it 'should redirect to sign in' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'Sign In')
			end
		end
	end

	describe 'private access' do
		before do
			visit signin_path
			fill_in 'Email',	with: other_user.email
			fill_in 'Password',	with: other_user.password
			click_button 'Sign In'
		end

		it 'should redirect to home page' do
			should have_selector('title', text: 'Profile')
			should have_selector('h1', text: other_user.handle)
			should have_selector('div.alert.alert-success', text: 'Logged in')
		end

		describe 'to user path' do
			before do
				open_campaign.add_member user
				closed_campaign.add_member user
				visit user_path(user)
			end

			it 'should display correctly' do
				should have_selector('title', text: 'Profile')
				should have_selector('h1', text: user.handle)
				should have_link(open_campaign.name)
				should_not have_link(closed_campaign.name)
				should have_link(character.name)
				should_not have_link(priv_character.name)
			end

			describe 'with common closed campaign' do
				before do
					closed_campaign.add_member other_user
					visit user_path(user)
				end

				it 'should display' do
					should have_selector('h1', text: user.handle)
					should have_link(closed_campaign.name)
				end
			end
		end

		describe 'to edit path' do
			before { visit edit_user_path(user) }

			it 'should redirect to show user path' do
				should have_selector('title', text: 'Profile')
				should have_selector('h1', text: user.handle)
				should have_selector('div.alert.alert-error', text: 'You may only edit your own profile')
			end
		end

		describe 'to own edit path' do
			before { visit edit_user_path(other_user) }

			it 'should display correctly' do
				should have_selector('title', text: 'Modify')
				should have_selector('h1', text: 'Change Account Settings')
			end

			describe 'without incorrect password' do
				before do
					fill_in 'Password', with: 'bad pass'
					click_button 'Save Changes'
				end

				it 'should show error' do
					should have_selector('title', text: 'Modify')
					should have_selector('h1', text: 'Change Account Settings')
					should have_selector('div.alert.alert-error', text: 'Incorrect Password')
				end
			end

			describe 'supplying invalid information' do
				before do
					fill_in 'Email', with: 'not an email address'
					fill_in 'Password', with: other_user.password
					click_button 'Save Changes'
				end

				it 'should show error' do
					should have_selector('title', text: 'Modify')
					should have_selector('h1', text: 'Change Account Settings')
					should have_selector('div.alert.alert-error', text: 'Email is invalid')
				end
			end

			describe 'supplying valid information' do
				let(:new_email) { 'new@email.com' }
				let(:new_handle) { 'Handlicious' }
				let(:new_name) { 'Mr New Name' }
				before do
					fill_in 'Email', with: new_email
					fill_in 'User Name', with: new_handle
					fill_in 'Real Name', with: new_name
					fill_in 'Password', with: other_user.password
					click_button 'Save Changes'
				end

				it 'should show correctly' do
					should have_selector('title', text: 'Profile')
					should have_selector('h1', text: new_handle)
					should have_selector('h2', text: new_email)
					should have_selector('h2', text: new_name)
				end
			end

			describe 'changing password' do
				let(:new_pass) { 'PassAnew' }
				before do
					fill_in 'New Password', with: new_pass
					fill_in 'Confirm New Password', with: new_pass
				end

				describe 'with correct authentication' do
					before do
						fill_in 'New Password', with: new_pass
						fill_in 'Confirm New Password', with: new_pass
						fill_in 'Old Password', with: other_user.password
						click_button 'Update'
						other_user.reload
					end

					it 'should change password' do
						should have_selector('title', text: 'Profile')
						should have_selector('h1', text: other_user.handle)
						should have_selector('div.alert.alert-success', text: 'Password Changed' )
						other_user.authenticate(new_pass).should_not == false
					end
				end

				describe 'with incorrect authentication' do
					before do
						fill_in 'Old Password', with: 'bad pass'
						click_button 'Update'
						user.reload
					end

					it 'should show error' do
						should have_selector('title', text: 'Modify' )
						should have_selector('div.alert.alert-error', text: 'Incorrect Password' )
						other_user.authenticate(other_user.password).should_not == false
						# user.authenticate(new_pass).should == false
					end
				end
			end

		end
	end

end
