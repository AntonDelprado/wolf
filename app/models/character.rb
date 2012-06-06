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

class Character < ActiveRecord::Base
  attr_accessible :dex, :fai, :int, :name, :player, :race, :str
  serialize :skills
  serialize :abilities

  validates :name, presence: true, length: { maximum: 100 }
  validates :player, presence: true, length: { maximum: 100 }
  validates :race, presence: true, inclusion: %w[Wolf Dwarf Goblin Vampire]
  validates :str, presence: true, inclusion: [4,6,8,10,12]
  validates :dex, presence: true, inclusion: [4,6,8,10,12]
  validates :int, presence: true, inclusion: [4,6,8,10,12]
  validates :fai, presence: true, inclusion: [4,6,8,10,12]

  def self.stats(race="Wolf")
    case race
    when "Wolf", "Dwarf" then return [[12,4,4,4], [10,10,4,4], [10,8,6,4], [8,8,8,6]]
    when "Vampire" then return [[12,12,12,4]]
    when "Goblin" then return [[8,6,4,4], [6,6,6,6]]
    end
  end

  def self.join_stats(stats)
    return "#{stats[0]} Str, #{stats[1]} Dex, #{stats[2]} Int, #{stats[3]} Fai"
  end

  # index1 represents which ba
  def base_stats(index_base = nil, index_raw = nil)
    return self.class.stats(self.race) if index_base.nil?
    if self.class == 'Vampire'
      return [[12,12,12,4]] if index_raw.nil?
      return [12,12,12,4]
    else
      return self.class.stats(self.race)[index_base].permutation.to_a.uniq if index_raw.nil?
      return self.class.stats(self.race)[index_base].permutation.to_a.uniq[index_raw]
    end
  end

  def stats
    [self.str, self.dex, self.int, self.fai]
  end

  def stats_options(index = nil)
    return self.base_stats.each_with_index.collect { |stat, index| [stat.join(", "), index]} if index.nil?
    return [["12, 12, 12, 4", 0]] if self.race == "Vampire"
    return self.base_stats[index].permutation.to_a.uniq.each_with_index.collect { |stat, index| [self.class.join_stats(stat), index]}
  end

  def stats_selected(option_index = nil)
    if option_index.nil?
      sorted_stats = [self.str, self.dex, self.int, self.fai].sort.reverse
      self.base_stats.each_with_index do |stat, index|
        return index if sorted_stats == stat
      end
      return nil
    else
      self.base_stats[option_index].permutation.to_a.uniq.each_with_index do |stat, index|
        return index if stat == self.stats
      end
      return nil
    end
  end

end
