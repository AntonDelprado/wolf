require 'spec_helper'

describe 'Character Pages' do
	let(:user) { FactoryGirl.create(:user) }
	let(:other_user) { FactoryGirl.create(:other_user) }
	let(:open_campaign) { FactoryGirl.create(:open_campaign) }
	let(:closed_campaign) { FactoryGirl.create(:closed_campaign) }
	let(:character) { FactoryGirl.create(:public_character, user_id: user.id, campaign_id: open_campaign.id) }

	subject { page }

	before { character.save }

	describe 'public access' do

		describe 'to new character page' do
			before { visit new_character_path }

			it 'should redirect to Sign In' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'sign in')
			end
		end

		describe 'to edit character page' do
			before { visit edit_character_path(character) }

			it 'should redirect to Sign In' do
				should have_selector('title', text: 'Sign In')
				should have_selector('div.alert.alert-notice', text: 'sign in')
			end
		end

		describe 'to characters page' do 
			before { visit characters_path }

			it { should have_selector('title', text: 'Characters') }

			describe 'for a public character' do
				it { should have_link(character.name) }
			end

			describe 'for a private character' do
				before do
					character.privacy = :private
					character.save
					visit characters_path
				end

				it { should_not have_link(character.name) }
			end
		end

		describe 'to public character page' do 
			before { visit character_path(character) }

			it { should have_selector('title', text: character.name) }

			it 'should have full content' do 
				should have_selector('th', text: 'Skill Name')
				should have_selector('th', text: 'Ability Name')
				should have_selector('th', text: 'Synergy Class')
				should have_selector('td', text: 'Spell XP')
				should have_selector('td', text: 'Strength')
			end

			it 'should have player link' do
				should have_link(user.handle)
			end

			it 'should have campaign link' do
				should have_link(open_campaign.name)
			end

			describe 'error and warning messages' do
				before do
					character.str = 12
					character.dex = 12
					character.save
					visit character_path(character)
				end

				it 'should display' do
					should have_selector('li', text: '* Unspent Free Ability')
					should have_selector('li', text: '* Invalid Stats')
				end
			end
		end

		describe 'to private character page' do
			before do
				character.privacy = :private
				character.save
				visit character_path(character)
			end

			it 'should redirect to characters page' do
				should have_selector('title', text: 'Characters')
				should have_selector('div.alert.alert-error', text: 'Unable to access character')
			end
		end

		describe 'to campaign character page' do 
			before do
				character.privacy = :campaign
				character.save
				visit character_path(character)
			end

			it 'should redirect to characters page' do
				should have_selector('title', text: 'Characters')
				should have_selector('div.alert.alert-error', text: 'Unable to access character')
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

		describe 'to new characters page' do
			let(:submit) { 'Create Character' }
			before { visit new_character_path }

			it { should have_selector('title', text: 'New Character') }

			describe 'creating new invalid character' do
				it "should not create a user" do
					expect { click_button submit }.not_to change(Character, :count)
					should have_selector('title', text: 'New Character')
					should have_selector('div.alert.alert-error', text: 'error')
				end
			end

			describe 'creating new valid character' do
				let(:new_name) { 'NewChar' }
				before do
					fill_in 'Name',		with: new_name
					select 'Dwarf',		from: 'Race'
					select 'None',		from: 'Campaign'
				end

				it 'should create a user' do
					expect { click_button submit }.to change(Character, :count).by(1)
					should have_selector('title', text: new_name)
					should have_selector('h2', text: 'Race: Dwarf')
					should_not have_selector('h2', text: 'Campaign')
				end

			end

		end

		describe 'to public character' do

			describe 'at character path' do
				before { visit character_path(character) }

				it 'should display without modify interface' do
					should have_selector('title', text: character.name)
					should have_selector('div.modify', visible: false)
				end
			end

			describe 'at characters path' do
				before { visit characters_path }

				it 'should display' do
					should have_selector('title', text: 'Characters')
					should have_link(character.name)
				end
			end

		end

		describe 'to private character' do
			before do
				character.privacy = :private
				character.save
			end

			describe 'at character path' do
				before { visit character_path(character) }

				it 'should redirect to characters page' do
					should have_selector('title', text: 'Characters')
					should have_selector('div.alert.alert-error', text: 'Unable to access character')
				end
			end

			describe 'at characters path' do
				before { visit characters_path }

				it 'should not show character' do
					should have_selector('title', text: 'Characters')
					should_not have_link(character.name)
				end
			end
		end

		describe 'to campaign character' do
			before do
				character.privacy = :campaign
				character.save
			end

			describe 'in a different campaign' do
				describe 'at character path' do
					before { visit character_path(character) }

					it 'should redirect to characters page' do
						should have_selector('title', text: 'Characters')
						should have_selector('div.alert.alert-error', text: 'Unable to access character')
					end
				end

				describe 'at characters path' do
					before { visit characters_path }

					it 'should not show character' do
						should have_selector('title', text: 'Characters')
						should_not have_link(character.name)
					end
				end
			end

			describe 'in the same campaign' do
				before { open_campaign.add_member other_user }
				
				describe 'at character path' do
					before { visit character_path(character) }

					it { should have_selector('title', text: character.name) }
				end

				describe 'at characters path' do
					before { visit characters_path }

					it 'should show character' do
						should have_selector('title', text: 'Characters')
						should have_link(character.name)
					end
				end

			end
		end

	end

	describe 'own character editing' do
		before do
			closed_campaign.add_member user

			visit signin_path
			fill_in 'Email',	with: user.email
			fill_in 'Password',	with: user.password
			click_button 'Sign In'
			visit character_path(character)
		end

		describe 'character details' do
			let(:new_name) { 'NewNameChar' }
			before do
				fill_in 'Name',					with: new_name
				select 'Goblin', 				from: 'Race'
				select closed_campaign.name,	from: 'Campaign'
				select 'Private',				from: 'Privacy'
				click_button 'Change Details'
			end

			it 'should update' do
				should have_selector('title', text: new_name)
				should have_selector('h2', text: 'Race: Goblin')
				should have_link(closed_campaign.name)
				should have_selector('h3', text: 'Privacy: Private')
			end
		end

		describe 'base stats' do
			before do
				select '10, 10, 4, 4',	from: 'Base Stats'
				select '4 Str, 10 Dex, 10 Int, 4 Fai', from: 'raw_stats1'
				click_button 'Change Stats'
				character.reload
			end

			it 'should update' do
				should have_selector('title', text: character.name)
				should have_selector('div.alert.alert-success', text: 'Changed Stats')
				character.str.should == 4
				character.dex.should == 10
				character.int.should == 10
				character.fai.should == 4
			end

		end

		describe 'by adding skills' do
			before do
				check 'add_Attack'
				click_button 'Add Skills'
				character.reload
			end

			it 'should update' do
				should have_selector('title', text: character.name)
				should have_selector('div.alert.alert-success', text: 'Add')
				should have_selector('div.alert.alert-success', text: 'Added 1 Skill: Attack')
				character.should have_skill('Attack')
			end

			describe 'then removing skills' do
				before do
					check 'remove_Attack'
					click_button 'Remove Skills'
					character.reload
				end

				it 'should update' do
					should have_selector('title', text: character.name)
					should have_selector('div.alert.alert-success', text: 'Remove')
					should have_selector('div.alert.alert-success', text: 'Removed 1 Skill: Attack')
					character.should_not have_skill('Attack')
				end
			end

			describe 'then changing skill levels' do
				before do
					select '13', from: 'level_Attack'
					select '15', from: 'level_Endurance'
					click_button 'Save Changes'
					character.reload
				end

				it 'should update' do
					should have_selector('title', text: character.name)
					should have_selector('div.alert.alert-success', text: 'Changed 2 Skill Levels: Attack, Endurance')
					character.skill('Attack').level.should == 13
				end
			end

		end

		describe 'by adding abilities' do
			before do
				check 'add_Acrobatic'
				click_button 'Add Abilities'
				character.reload
			end

			it 'should update' do
				should have_selector('title', text: character.name)
				should have_selector('div.alert.alert-success', text: 'Added 1 Ability: Acrobatic')
				character.should have_ability('Acrobatic')
			end

			describe 'then removing abilties' do
				before do
					check 'remove_Acrobatic'
					click_button 'Remove Abilities'
					character.reload
				end

				it 'should update' do
					should have_selector('title', text: character.name)
					should have_selector('div.alert.alert-success', text: 'Removed 1 Ability: Acrobatic')
					character.should_not have_ability('Acrobatic')
				end
			end
		end

		describe 'showing synergies' do
			before do
				character.add_skill('Attack', 10)
				character.save
				visit character_path(character)
			end

			it 'should show synergy' do
				should have_selector('title', text: character.name)
				should have_selector('td.name-warrior', text: 'Warrior')
			end
		end

		describe 'deleting character' do
			it 'should delete character' do
				expect { click_link 'Delete' }.to change(Character, :count).by(-1)
				should have_selector('title', text: 'Characters')
				should have_selector('div.alert.alert-success', text: "Destroyed: #{character.name}" )
			end
		end

	end

end