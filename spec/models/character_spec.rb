# == Schema Information
#
# Table name: characters
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  str         :integer
#  dex         :integer
#  int         :integer
#  fai         :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  race        :string(255)
#  user_id     :integer
#  campaign_id :integer
#  privacy     :integer
#

require 'spec_helper'

describe Character do

	before do
		@char = Character.new(name: "Essin", player: "Anton", str: 12, dex: 12, int: 12, fai: 4)
	end

	subject { @char }

	it { should respond_to(:name) }
	it { should respond_to(:player) }
	it { should respond_to(:str) }
	it { should respond_to(:dex) }
	it { should respond_to(:int) }
	it { should respond_to(:fai) }
	it { should respond_to(:skills) }
	it { should respond_to(:abilities) }

	it { should be_valid }

	describe "when name is not present" do 
		before { @char.name = " " }
		it { should be_invalid }
	end

	describe "when str is not a die" do 
		before { @char.str = "3" }
		it { should be_invalid }
	end

	describe "when dex is not a die" do 
		before { @char.dex = "3" }
		it { should be_invalid }
	end

	describe "when int is not a die" do 
		before { @char.int = "3" }
		it { should be_invalid }
	end

	describe "when fai is not a die" do 
		before { @char.fai = "3" }
		it { should be_invalid }
	end

end
