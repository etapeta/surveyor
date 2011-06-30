class CreateNests < ActiveRecord::Migration
  def self.up
    create_table :nests do |t|
      t.string :name
      t.string :document
      t.string :header
      t.string :footer

      t.timestamps
    end
  end

  def self.down
    drop_table :nests
  end
end
