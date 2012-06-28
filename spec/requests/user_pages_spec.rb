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


		end
	end

end
