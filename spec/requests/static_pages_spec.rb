require 'spec_helper'

describe "StaticPages" do

	describe "home page" do
		before { visit root_path }

		it { should have_selector('h1', text: 'Welcome') }
	end

end
