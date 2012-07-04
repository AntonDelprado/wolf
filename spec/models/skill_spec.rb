# == Schema Information
#
# Table name: skills
#
#  id                :integer         not null, primary key
#  character_id      :integer
#  name              :string(255)
#  level             :integer
#  created_at        :datetime        not null
#  updated_at        :datetime        not null
#  required_skill_id :integer
#

require 'spec_helper'

describe Skill do
  pending "add some examples to (or delete) #{__FILE__}"
end
