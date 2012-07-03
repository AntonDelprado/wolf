require 'spec_helper'

describe "StaticPages" do

	subject { page }

	let(:user) { FactoryGirl.create(:user) }
	let(:other_user) { FactoryGirl.create(:other_user) }

	describe 'public access' do
		describe 'to rules' do
			before { visit rules_path }

			it 'should display' do
				should have_selector('title', text: 'Rules')
				should have_selector('h1', text: 'Wolf: Rules')
			end

			it 'should show core' do
				should have_selector('div#tab-core')
				should have_selector('h2', text: 'Stats and Skill Checks')
			end

			it 'should show combat' do
				should have_selector('div#tab-combat')
				should have_selector('h2', text: 'Initiative and Movement Speed')
			end

			it 'should show races' do
				should have_selector('div#tab-races')
				should have_selector('h2', text: 'Wolves')
			end

			it 'should show skills' do
				should have_selector('div#tab-skills')
				should have_selector('h2', text: 'Skills')
				should have_selector('div.skill-rogue', text: 'Backstab')
			end

			it 'should show skill trees' do
				should have_selector('div#tab-skill-trees')
				should have_selector('h2', text: 'Skill Trees')
				should have_selector('div.synergy.rogue', text: 'Backstab')
			end

			it 'should show abilities' do
				should have_selector('div#tab-abilities')
				should have_selector('h2', text: 'Abilities')
				should have_selector('div.ability.rogue', text: 'Acrobatic')
			end

			it 'should show synergy classes' do
				should have_selector('div#tab-synergy')
				should have_selector('h2', text: 'Synergy Classes')
			end

			it 'should show items' do
				should have_selector('div#tab-items')
				should have_selector('h2', text: 'Items')
				should have_selector('td', text: 'Cloth')
				should have_selector('td', text: 'Buckler')
				should have_selector('td', text: 'Short Sword')
			end

			it 'should show monsters' do
				should have_selector('div#tab-monsters')
				should have_selector('h2', text: 'Monsters')
			end
		end

		describe 'to setting' do
			before { visit setting_path }

			it 'should display' do
				should have_selector('title', text: 'Setting')
				should have_selector('h1', text: 'Wolf: Setting')
			end
		end

		describe 'to about' do
			before { visit root_path }

			it 'should display' do
				should have_selector('title', text: 'Home')
				should have_selector('h1', text: 'Wolf: Home Page')
			end
		end

		describe 'to contact' do
			before { visit contact_path }

			it 'should display' do
				should have_selector('title', text: 'Contact')
				should have_selector('h1', text: 'Wolf: Contact')
			end
		end
	end

	describe 'private access' do
		before do
			visit signin_path
			fill_in 'Email', with: user.email
			fill_in 'Password', with: user.password
			click_button 'Sign In'
		end

		describe 'to rules' do
			before { visit rules_path }

			it 'should display without add' do
				should have_selector('title', text: 'Rules')
				should_not have_link('Add Skill to')
				should_not have_link('Add Ability to')
			end
		end

		describe 'with own character' do
			let(:character) { FactoryGirl.create(:public_character, user_id: user.id) }
			before do
				character.user_id = user.id
				character.save
				visit character_path(character)
				visit rules_path
			end

			it 'should display with add' do
				should have_selector('title', text: 'Rules')
				should have_link('Add Skill to')
				should have_link(character.name)
				should have_link('Add Ability to')
			end
		end
	end

end
