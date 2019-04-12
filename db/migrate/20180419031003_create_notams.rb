class CreateNotams < ActiveRecord::Migration[5.1]
  def change
    create_table :notams do |t|
      t.string :transaction_id
      t.string :scenario
      t.boolean :xsi_nil_error
      t.datetime :end_position
      t.references :delta_request, foreign_key: true

      t.timestamps
    end
  end
end
