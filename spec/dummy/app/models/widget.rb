class Widget < ActiveRecord::Base
  def self.ransackable_attributes(_auth_object = nil) = column_names
  def self.ransackable_associations(_auth_object = nil) = []
end
