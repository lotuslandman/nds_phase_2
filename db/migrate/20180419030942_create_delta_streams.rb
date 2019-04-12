class CreateDeltaStreams < ActiveRecord::Migration[5.1]
  def change
    create_table :delta_streams do |t|
      t.integer :frequency_minutes
      t.integer :delta_reachback

      t.timestamps
    end
  end
end
