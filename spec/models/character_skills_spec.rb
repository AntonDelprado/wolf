# == Schema Information
#
# Table name: character_skills
#
#  id             :integer         not null, primary key
#  character_id   :integer
#  name           :string(255)
#  level          :integer
#  created_at     :datetime        not null
#  updated_at     :datetime        not null
#  required_skill :string(255)
#  synergy_name   :string(255)
#

require 'spec_helper'

describe CharacterSkills do
  pending "add some examples to (or delete) #{__FILE__}"
end
