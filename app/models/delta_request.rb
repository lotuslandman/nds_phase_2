class DeltaRequest < ApplicationRecord
  belongs_to :delta_stream
  has_many :notams, dependent: :destroy
#  has_many :scenario_notams, -> { positive }, class_name: "Notam", dependent: :destroy

  validates :duration, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
#  validates :parseable, presence: true # apparently setting to false fails validation

  def count_filtered_notams(filter) # 'red' or 'blue'
    self.notams.select do |notam|
      notam.filter_selected_in(filter)
    end.size
  end

  def return_filtered_notams_scenario(filter) # 'red' or 'blue'
    self.notams.collect do |notam|
      notam.scenario if notam.filter_selected_in(filter)   # if filter allows notam return the scenario to be counted later or grouped later
    end
  end

  def parse_and_store_time_info_to_delta_request(response_time_info_line)
    rts = response_time_info_line.split(',')
    start_time = rts[0].strip
    end_time = rts[1].strip
    duration = rts[2].strip.to_f
    self.start_time = start_time
    self.end_time = end_time
    self.duration = duration
  end

  def parse_response_and_save_dr(response, file_path_pretty)
    self.not_parseable = false

    begin
      pretty_response = Nokogiri::XML(response) { |config| config.strict }
      dr_doc = pretty_response.remove_namespaces!       # seems to be necessary for Nokogiri - simplifies XPATH statements too
      feature_collection_doc = dr_doc.xpath("//FeatureCollection")
      self.number_returned = feature_collection_doc.attr('numberReturned').value
    rescue
      self.not_parseable = true
      puts "Nokogiri couldn't parse: #{file_path_pretty}"
    end

    begin
      if DeltaRequest.all.collect {|dr| dr.start_time}.include?(self.start_time)
        puts "Why are we trying to save delta request with start_time of #{self.start_time}, its already in the database"
      end
      self.save!
    rescue
      puts "Couldn't save delta_request - file_path_pretty: #{file_path_pretty} "
    end
    return pretty_response
  end
  
  def save_pretty_notams_to_database(pretty_response, file_path_pretty)
    begin
      File.open(file_path_pretty, 'w') { |rf| rf.puts pretty_response}
    rescue
      puts "Couldn't write pretty - file_path_pretty: #{file_path_pretty}"
    end

    doc = pretty_response.remove_namespaces!       # seems to be necessary for Nokogiri - simplifies XPATH statements too
    notam_docs = doc.xpath("//AIXMBasicMessage")   # prepare to store to Notam object
    puts "Number of NOTAMs in message #{self.number_returned} not equal to what was extracted #{notam_docs.size}" if notam_docs.size != self.number_returned.to_i

    notam_docs.collect do |notam_doc|
      begin
        notam = self.notams.create()                # notams are created even if they are a repeat from the prior delta request.
        notam.fill(notam_doc)                       # fills the database fields with things extracted from the Nokogiri document
      rescue
        puts "couldn't create or fill notam"
      end
    end
  end

  def create_dir(dir)
    Dir.mkdir(dir) unless File.exists?(dir)
  end

  def handle_full_delta_request(file_name) 
    fn_frag = file_name.sub(" UTC","").split(' ').join('T')

    path_to_delta_files = self.delta_stream.compute_stream_file_dir + "/files_delta"
    file_path_response = path_to_delta_files + "/"        + 'delta_'+fn_frag+'.xml'
    file_path_time     = path_to_delta_files + "_time/"   + 'delta_'+fn_frag+'_time.xml'
    file_path_pretty   = path_to_delta_files + "_pretty/" + 'delta_'+fn_frag+'_pretty.xml'
    begin
      response                = File.read(file_path_response)
      response_time_info_line = File.read(file_path_time)
      create_dir(path_to_delta_files + "_pretty/")
      parse_and_store_time_info_to_delta_request(response_time_info_line)
    rescue
      puts "couldn't read response or time files or parse them for self.start_time #{self.start_time}"
    end
    pretty_response = parse_response_and_save_dr(response, file_path_pretty)
    unless self.not_parseable
      save_pretty_notams_to_database(pretty_response, file_path_pretty)
    end
  end

  def scenario_notams(scenario)
#    self_notams_scenario = self_notams.by_scenario(602)    # this works but it is even slower than the select loop around self_notams
    self_notams_scenario = self.notams.select{|notam| notam.scenario == scenario}
  end
  
  def href_notams()
    self_notams_scenario = self.notams.select{|notam| notam.href_with_pound}
  end
  
end
