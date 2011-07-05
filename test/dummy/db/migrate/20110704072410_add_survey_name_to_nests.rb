class AddSurveyNameToNests < ActiveRecord::Migration
  def self.up
    add_column :nests, :survey_name, :string
  end

  def self.down
    remove_column :nests, :survey_name
  end
end