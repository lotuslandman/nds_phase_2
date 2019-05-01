require 'time'
class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy

  validates :frequency_minutes, presence: true
  validates :delta_reachback, presence: true

  def compute_stream_file_dir
    stream_number = self.id.to_s
    month_str = Time.now.month.to_s
    year_str = Time.now.year.to_s
    # the following string will produce something like this: "../stream_files/stream_1_files/2019-5/files_delta/*"
    if Rails.env.development?
      stream_file_dir = "../stream_files/stream_#{stream_number.to_s}_files/#{year_str}-#{month_str}"
    elsif Rails.env.production?
      stream_file_dir = "../../../nds_phase_1/stream_files/stream_#{stream_number.to_s}_files/#{year_str}-#{month_str}"
      puts "pwd #{system("pwd")}"
      puts "stream_file_dir = #{stream_file_dir}"
    else
      puts "unknown Rails environment"
      puts "pwd #{system("pwd")}"
      puts "stream_file_dir = " + "../stream_files/stream_#{stream_number.to_s}_files/#{year_str}-#{month_str}"
      exit
    end
    stream_file_dir
  end
  
  def file_name_array  # go into the filesystem ".../.../files_delta/" and find all delta responses
    stream_file_dir = compute_stream_file_dir()
    dir_result = Dir.glob(stream_file_dir+"/files_delta/*").sort.collect do |fnp|
      File.basename(fnp)  # have to back out of rails directory with ../
    end
    file_name_array =[]
    dir_result.sort.collect do |file_name_raw|
      begin
        x = file_name_raw.split("delta")[1].split('.')[0][1..-1]
        y = x.sub('T', ' ')+' UTC'
        file_name_array.append(y)
      rescue
        puts "file in delta_files/ not named correctly: #{file_name_raw}"
      end
    end
    file_name_array
  end
  
#    File.open(path, 'w') { |rf| rf.puts "Top DB for DS #{self.id} with #{dates_to_get.size} (#{date_array_from_filesystem.size}-#{date_array_from_database.size}) delta_requests"}

  def create_pretty_response_file_and_fill_database
    request_type  = :delta
    date_array_from_filesystem = file_name_array
    date_array_from_database  = self.delta_requests.collect {|dr| dr.start_time.to_s}  
    dates_to_get_full = date_array_from_filesystem - date_array_from_database
    should_be_empty = date_array_from_database - date_array_from_filesystem    # should be no items in DB that are not in the filesystem

    if not should_be_empty.empty?
      puts "item found in database that was not in filesytem, number of items: #{should_be_empty.size} sample: #{should_be_empty[0]}"
    end
    puts "entry in database that is not in the filesystem #{should_be_empty.size} #{should_be_empty[0].to_s}" if not should_be_empty.empty?
    dates_to_get_full_sort = dates_to_get_full.sort
    if dates_to_get_full_sort.size > 7   # limit chunk to put in database to 55
      dates_to_get = dates_to_get_full_sort[-30..-1]  # [-1..-1] gets one from troubleshooting
    else
      dates_to_get = dates_to_get_full_sort
    end
    loop = 0
#    puts "dates_to_get_full_sort #{dates_to_get_full_sort.size} = date_array_from_filesystem #{date_array_from_filesystem.size} - date_array_from_database = #{date_array_from_database.size}"
    puts "filesystem count #{date_array_from_filesystem.size} - database count #{date_array_from_database.size} = dates_to_get #{dates_to_get_full_sort.size}, but only getting #{dates_to_get.size}"
    if date_array_from_filesystem.size - date_array_from_database.size != dates_to_get_full_sort.size
      puts "Suspicious discrepency between filesystem and database, expected #{date_array_from_filesystem.size - date_array_from_database.size} but got #{dates_to_get_full_sort.size}"
    end
    dates_to_get.collect do |file_date|
      file_name = file_date.to_s   # Time to string
      @delta_request = self.delta_requests.create()  # create new delta_request from this delta_stream
      begin
        @delta_request.not_parseable = false
        @delta_request.handle_full_delta_request(file_name)
#        puts "YES Date #{file_date}"
      rescue
        @delta_request.not_parseable = true
#        puts "filename = #{file_name} - failure"
#        puts "NO  Date #{file_date}"
      end
      loop += 1
    end
  end

  def round_to_earlier_3_min_sync_date(date)
    date_as_array = date.to_a
    date_as_array[0] = 0
    proposed_minute = date_as_array[1]
    date_as_array[1] -= proposed_minute%3
    Time.utc(*date_as_array)
  end
  
  def create_array_uniform_dates(start_date, end_date)
    synced_to_3_min_start_date = round_to_earlier_3_min_sync_date(start_date)
    synced_to_3_min_end_date   = round_to_earlier_3_min_sync_date(end_date)
    synced_to_3_min_start_date += 3.minutes
    synced_date_array = []
    synced_date =       synced_to_3_min_start_date
    while synced_date <= synced_to_3_min_end_date
      synced_date_array.append(synced_date)
      synced_date += 3.minutes
    end
    synced_date_array
  end

  # select delta_requests from between begin time and end time of chart
  def get_drs_from_range(start_date, end_date)
    self.delta_requests.select do |dr|
      begin
        dr.start_time > start_date and dr.start_time < end_date
      rescue
        false
      end
    end
  end

  def column_chart_data(start_date, end_date, scenario, y_axis, blue_filter, red_filter)
    relevant_delta_requests = get_drs_from_range(start_date, end_date)
    # makes a hash of relevant delta_requests between start and end dates filling with start_time and duration
    plot_dr_hash_blue = {}
    plot_dr_hash_red = {}
    synced_date_array = create_array_uniform_dates(start_date, end_date)
    red_filtered_notam_scenarios = []   # will fill this up with contributions from each relevant_delta_request's notams
    dr_start_time = ""
    relevant_delta_requests.collect do |dr|
      ind = round_to_earlier_3_min_sync_date(dr.start_time)  # start time
      dr_start_time = dr.start_time
      case y_axis
      when "response_time"
        plot_dr_hash_blue[ind] = dr.duration           # duration could try dr.notams.size
      when "number_of_notams"
        plot_dr_hash_blue[ind] = dr.count_filtered_notams(blue_filter) # BLUE
        plot_dr_hash_red[ind]  = dr.count_filtered_notams(red_filter)  # RED
        x = dr.return_filtered_notams_scenario(red_filter)
        red_filtered_notam_scenarios += x
      when "not_parseable"
        plot_dr_hash_blue[ind]  = (dr.not_parseable ? 1 : 0)
      end
    end
    notams_blue_1 = []
    notams_red_1  = []

    synced_date_array.collect do |s_date|
      notams_blue_1 << {s_date.to_s => plot_dr_hash_blue[s_date]} 
      notams_red_1  << {s_date.to_s => plot_dr_hash_red[s_date]} 
    end

    notams_blue_2 = notams_blue_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    notams_red_2  = notams_red_1.inject{ |memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}

    plot_array_number_of_notams = []
    plot_array_number_of_notams << {name: "Blue Filtered Notams", data: notams_blue_2}
    plot_array_number_of_notams << {name: "Red Filtered Notams", data: notams_red_2} if red_filter.filtering_applied?
    plot_array_number_of_notams

    begin
      plot_array_scenario = red_filtered_notam_scenarios.compact.group_by(&:capitalize).map {|k,v| [k, v.length]}
    rescue
      binding.pry
    end
    outp = [plot_array_number_of_notams, plot_array_scenario, dr_start_time]
    outp
  end

end

