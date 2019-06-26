class CreateNotams < ActiveRecord::Migration[5.1]
  def change
    create_table :notams do |t|
      t.string :transaction_id
      t.string :scenario
      t.string :accountability
      t.string :location
      t.string :issued
      t.string :classification
      t.string :notam_number
      t.string :natural_key
      t.boolean :xsi_nil_error
      t.boolean :href_with_pound
      t.boolean :pre_ver_2_12
      t.boolean :post_ver_2_12
      t.datetime :end_position
      t.references :delta_request, foreign_key: true

      t.timestamps
    end
  end
end
