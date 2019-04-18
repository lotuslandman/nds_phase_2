namespace :nds do
  desc "load database stream 1 (FNTB)"
  task :load_stream_1 => :environment do
    ds_1 = DeltaStream.find_by_id(1)
    ds_1 ||= DeltaStream.create(id: 1, frequency_minutes: 3, delta_reachback: 6)
    ds_1.create_pretty_response_file_and_fill_database
  end
end