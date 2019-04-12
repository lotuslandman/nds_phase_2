class AddDurationToDeltaRequests < ActiveRecord::Migration[5.1]
  def change
    add_column :delta_requests, :duration, :float
    add_column :delta_requests, :start_time, :datetime
    add_column :delta_requests, :end_time, :datetime
    add_column :delta_requests, :not_parseable, :boolean
    add_column :delta_requests, :number_returned, :string

    add_index :delta_requests, :start_time
  end
end
