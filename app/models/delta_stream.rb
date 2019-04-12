require 'time'
class DeltaStream < ApplicationRecord
  has_many :delta_requests, dependent: :destroy

  validates :frequency_minutes, presence: true
  validates :delta_reachback, presence: true
  
  def apr2019_file_name_array  # go into the filesystem ".../.../files_delta/" and find all delta responses
    stream_number = self.id.to_s
    dir_result = Dir.glob("/home/scott/dev/nds/stream_files/stream_#{stream_number.to_s}_files/2019-4/files_delta/*").sort.collect do |fnp|
      '../files_delta/'+File.basename(fnp)  # have to back out of rails directory with ../
    end
    file_name_array =[]
    dir_result.sort.collect do |file_name_raw|
      begin
        x = file_name_raw.split("delta")[2].split('.')[0][1..-1]
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
    path = "/home/scott/dev/nds/ndsapp1/llog.txt"
    request_type  = :delta
    date_array_from_filesystem = apr2019_file_name_array
    date_array_from_database  = self.delta_requests.collect {|dr| dr.start_time.to_s}  
    dates_to_get_full = date_array_from_filesystem - date_array_from_database
    should_be_empty = date_array_from_database - date_array_from_filesystem    # should be no items in DB that are not in the filesystem
    puts "entry in database that is not in the filesystem #{should_be_empty.size} #{should_be_empty[0].to_s}" if not should_be_empty.empty?
    dates_to_get_full_sort = dates_to_get_full.sort
    puts "dates_to_get_full_sort #{dates_to_get_full_sort.size} = date_array_from_filesystem #{date_array_from_filesystem.size} - date_array_from_database = #{date_array_from_database.size}"
    if dates_to_get_full_sort.size > 7   # limit chunk to put in database to 55
      dates_to_get = dates_to_get_full_sort[-25..-1]  # [-1..-1] gets one from troubleshooting
    else
      dates_to_get = dates_to_get_full_sort
    end
    loop = 0
    dates_to_get.collect do |file_date|
      file_name = file_date.to_s   # Time to string
      @delta_request = self.delta_requests.create()  # create new delta_request from this delta_stream
      begin
        @delta_request.not_parseable = false
        @delta_request.handle_full_delta_request(file_name)
        puts "YES Date #{file_date}"
      rescue
        @delta_request.not_parseable = true
#        puts "filename = #{file_name} - failure"
        puts "NO  Date #{file_date}"
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

  def get_drs_from_range(start_date, end_date)
    self.delta_requests.select do |dr|
      begin
        dr.start_time > start_date and dr.start_time < end_date
      rescue
        false
      end
    end
  end


#  def self.delta_request_chart(st, en, scenario)
#    notams_all = []
#    notams_flt = []
#    # builds array of hashes where index is to be grouped
#    DeltaRequest.all.collect { |dr| notams_all << {dr.request_time => dr.notams.size}}
#    DeltaRequest.all.collect { |dr| notams_flt << {dr.request_time => (dr.scenario_notams(scenario).size)}}
#    #    notams_all_1 = notams_all[50..60]
#    #    notams_flt_1 = notams_flt[50..60]
#    notams_all_1 = notams_all[st..en]
#    notams_flt_1 = notams_flt[st..en]
#    # takes array of hashes and makes hash, flattening allong hash keys
#    notams_all_2 = notams_all_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
#    notams_flt_2 = notams_flt_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
#    all_notams_w_filtered = [
#      {name: "Blue Filtered Notams", data: notams_all_2},
#      {name: "Red Filtered Notams", data: notams_flt_2}
#    ]
#  end
  def column_chart_data(start_date, end_date, scenario, y_axis)
    relevant_delta_requests = get_drs_from_range(start_date, end_date)
    # makes a hash of relevant delta_requests between start and end dates filling with start_time and duration
    relevant_dr_duration_hash = {}
    relevant_dr_duration_hash_1 = {}
    relevant_delta_requests.collect do |dr|
      ind = round_to_earlier_3_min_sync_date(dr.start_time)  # start time
      case y_axis
      when "response_time"
        relevant_dr_duration_hash[ind] = dr.duration           # duration could try dr.notams.size
      when "number_of_notams"
        notam_and_notam_scenario = dr.scenario_notams_a(scenario)
        relevant_dr_duration_hash[ind] = notam_and_notam_scenario[0]
        relevant_dr_duration_hash_1[ind] = notam_and_notam_scenario[1]
      when "not_parseable"
        relevant_dr_duration_hash[ind] = (dr.not_parseable ? 1 : 0)  # 
      end
    end
    notams_all_1 = []
    notams_flt_1 = []
    synced_date_array = create_array_uniform_dates(start_date, end_date)

    synced_date_array.collect do |s_date|
      x = relevant_dr_duration_hash[s_date]
      if x.nil?
        x = 0.0
        puts "Missing: Could not find a delta response in DB for this date: #{s_date.to_s}"  # should write to log file
      end
      notams_all_1 << {s_date.to_s => x}

      y = relevant_dr_duration_hash_1[s_date]
      if y.nil?
        y = 0.0
        puts "Missing: Could not find a number of notams w scenario in DB for this date: #{s_date.to_s}"  # should write to log file
      end
      notams_flt_1 << {s_date.to_s => y}
    end

    notams_all_2 = notams_all_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    notams_flt_2 = notams_flt_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
    all_notams_w_filtered = [
      {name: "Blue Filtered Notams", data: notams_all_2},
      {name: "Red Filtered Notams", data: notams_flt_2}
    ]
  end
end

###### Hoon demo #########
#  def column_chart_data(start_date, end_date, scenario, y_axis)
#
#    # makes a hash of relevant delta_requests between start and end dates filling with start_time and duration
#    relevant_delta_requests = self.delta_requests.select do |dr|
#      begin
#        dr.start_time > start_date and dr.start_time < end_date
#      rescue
#        false
#      end
#    end
#    relevant_dr_duration_hash = {}
#    relevant_delta_requests.collect do |dr|
#      ind = round_to_earlier_3_min_sync_date(dr.start_time)  # start time
#      relevant_dr_duration_hash[ind] = dr.duration           # duration
#    end
#    notams_all = []
#    notams_flt = []
#
#    synced_date_array = create_array_uniform_dates(start_date, end_date)
#    synced_date_array.collect do |s_date|
#      x = relevant_dr_duration_hash[s_date]
#      x = 0.0 if x.nil?
#      notams_all << {s_date.to_s => x}
#    end
#
#    notams_all_1 = notams_all
#    notams_all_2 = notams_all_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
#  end
#
#end

#### below works now on production !!! ####
  # builds array of hashes where index is to be grouped
#    self.delta_requests.collect do |dr|
#      if (dr.start_time < end_time) and (dr.start_time > start_time)
#        notams_all << {dr.end_time => dr.duration}
##        notams_all << {dr.end_time => dr.notams.size}
#      end
#    end
    
#    self.delta_requests.collect { |dr| notams_flt << {dr.end_time => (dr.scenario_notams(scenario).size)}}
#    self.delta_requests.collect { |dr| notams_flt << {dr.end_time => dr.duration}}
#    if y_axis == "response_time"
#    elsif y_axis == "number_of_notams"
    #    end
#    notams_flt_1 = notams_flt[-7..-1]
    # takes array of hashes and makes hash, flattening allong hash keys
#    notams_flt_2 = notams_flt_1.inject{|memo, el| memo.merge( el ){|k, old_v, new_v| old_v + new_v}}
#    all_notams_w_filtered = [
#      {name: "Blue Filtered Notams", data: notams_all_2},
#      {name: "Red Filtered Notams", data: notams_flt_2}
#    ]
