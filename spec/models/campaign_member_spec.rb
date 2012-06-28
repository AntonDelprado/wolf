# == Schema Information
#
# Table name: campaign_members
#
#  id          :integer         not null, primary key
#  campaign_id :integer
#  user_id     :integer
#  membership  :integer
#  created_at  :datetime        not null
#  updated_at  :datetime        not null
#

require 'spec_helper'

describe CampaignMember do
  pending "add some examples to (or delete) #{__FILE__}"
end
