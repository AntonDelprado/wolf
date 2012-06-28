# == Schema Information
#
# Table name: campaigns
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :text
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#  visibility  :integer(255)
#

require 'spec_helper'

describe Campaign do
  pending "add some examples to (or delete) #{__FILE__}"
end
