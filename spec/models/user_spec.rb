# == Schema Information
#
# Table name: users
#
#  id                  :integer         not null, primary key
#  name                :string(255)
#  email               :string(255)
#  handle              :string(255)
#  created_at          :datetime        not null
#  updated_at          :datetime        not null
#  password_digest     :string(255)
#  active_character_id :integer
#  character2_id       :integer
#  character3_id       :integer
#  active_campaign_id  :integer
#  campaign2_id        :integer
#  campaign3_id        :integer
#

require 'spec_helper'

describe User do

	before do 
		@user = User.new name: "Mr User", email: "user@test.com", handle: "Test Master", password: "usertest", password_confirmation: "usertest"
	end

	subject { @user }

	it { should respond_to :name }
	it { should respond_to :email }
	it { should respond_to :handle }
	it { should respond_to :password_digest }
	it { should respond_to :password }
	it { should respond_to :password_confirmation }
	it { should respond_to :authenticate}

	it { should be_valid }

	describe "when password is not present" do
		before { @user.password = @user.password_confirmation = " " }
		it { should_not be_valid }
	end

	describe "when password does not match confirmation" do 
		before { @user.password_confirmation = "mismatch" }
		it { should be_invalid }
	end

	describe "when password confirmation is nil" do
		before { @user.password_confirmation = "mismatch" }
		it { should_not be_valid }
	end

	describe "when a password is too short" do
		before { @user.password = @user.password_confirmation = 'abcde' }
		it { should_not be_valid }
	end

	describe "return value of authentication method" do 
		before { @user.save }
		let(:found_user) { User.find_by_name @user.name }

		describe "with valid password" do 
			it { should == found_user.authenticate(@user.password) }
		end

		describe "with invalid password" do 
			let(:user_for_invalid_password) { found_user.authenticate 'invalid password' }

			it { should_not == user_for_invalid_password }
			specify { user_for_invalid_password.should be_false }
		end
	end

	describe "email address with mixed case" do
		let(:mixed_case_email) { "Foo@ExAMPle.CoM" }

		it "should be saved as all lower-case" do
			@user.email = mixed_case_email
			@user.save
			@user.reload.email.should == mixed_case_email.downcase
		end
	end
end
