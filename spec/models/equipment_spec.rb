# == Schema Information
#
# Table name: equipment
#
#  id           :integer         not null, primary key
#  character_id :integer
#  slot         :string(255)
#  name         :string(255)
#  created_at   :datetime        not null
#  updated_at   :datetime        not null
#  item_type    :string(255)
#

require 'spec_helper'

describe Equipment do
  pending "add some examples to (or delete) #{__FILE__}"
end
