FactoryGirl.define do
	factory :user do
		name		"Mr User"
		email		"user@test.com"
		handle		"Test Master"
		password	"usertest"
		password_confirmation	"usertest"
	end

	factory :other_user, class: User do
		name		'Other User'
		email		'test@user.com'
		handle		'Different Person'
		password	'testuser'
		password_confirmation	'testuser'
	end

	factory :open_campaign, class: Campaign do
		name		'PubCamp'
		description	'This is the public campaign.'
		visibility	:open
	end

	factory :closed_campaign, class: Campaign do
		name		'PrivCamp'
		description	'This is the private campaign'
		visibility	:closed
	end

	factory :public_character, class: Character do
		name			"PubChar"
		str				10
		dex				8
		int				6
		fai				4
		race			'Wolf'
		privacy			:public
		user_id			1
		campaign_id		nil
	end

	factory :private_character, class: Character do
		name			"PrivChar"
		str				4
		dex				6
		int				8
		fai				10
		race			'Dwarf'
		privacy			:private
		user_id			1
		campaign_id		nil
	end
end
