require 'spec_helper'

describe 'Authentication Pages' do

	subject { page }

	describe 'Sign Up page' do 
		before { visit signup_path }

		it { should have_selector('h1', text: 'Create a New Account') }
		it { should have_selector('title', text: 'Sign Up') }

		let(:submit) { 'Create Account' }

		describe 'with invalid information' do 
			it "should not create a user" do
				expect { click_button submit }.not_to change(User, :count)
			end
		end

		describe 'with valid information' do 
			before do
				fill_in 'Email', 			with: 'temp@user.com'
				fill_in 'User Name', 		with: 'Tempman'
				fill_in 'Real Name',		with: 'Dr Temp User'
				fill_in 'Password',			with: 'temppass'
				fill_in 'Confirm Password',	with: 'temppass'
			end

			it 'should create a user' do
				expect { click_button submit }.to change(User, :count).by(1)
			end
		end
	end

	describe 'Sign In Page' do 
		before { visit signin_path }

		it { should have_selector('h1', text: 'Sign In') }
		it { should have_selector('title', text: 'Sign In') }

		describe 'with invalid information' do 
			before { click_button 'Sign In' }

			it { should have_selector('title', text: 'Sign In') }
			it { should have_selector('div.alert.alert-error', text: 'Invalid') }
		end

		describe 'with valid information' do 
			let(:user) { FactoryGirl.create(:user) }

			before do
				fill_in 'Email',		with: user.email
				fill_in 'Password',		with: user.password
				click_button 'Sign In'
			end

			it 'should log in' do
				should have_selector('title', text: 'Profile')
				should have_selector('h1', text: user.handle)
				should have_link('Profile', href: user_path(user))
				should have_link('Settings', href: edit_user_path(user))
				should have_link('Sign Out', href: signout_path)
				should_not have_link('Sign In', href: signin_path)
			end

			describe 'followed by signout' do
				before { click_link 'Sign Out' }

				it { should have_link('Sign In', href: signin_path) }
			end
		end
	end

end
