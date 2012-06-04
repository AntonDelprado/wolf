# == Schema Information
#
# Table name: characters
#
#  id         :integer         not null, primary key
#  name       :string(255)
#  player     :string(255)
#  str        :integer
#  dex        :integer
#  int        :integer
#  fai        :integer
#  skills     :text
#  abilities  :text
#  created_at :datetime        not null
#  updated_at :datetime        not null
#

require 'spec_helper'

describe Character do
  pending "add some examples to (or delete) #{__FILE__}"
end
