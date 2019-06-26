class Notam < ApplicationRecord
  belongs_to :delta_request
#  scope :by_scenario, ->(scenario) { where(scenario: scenario) }  # this worked but it was even slower than looping (see other by_scenario occurance)
  
  validates :scenario, presence: true

  def fill(notam_doc)
    self.transaction_id = notam_doc.attr('id')[-8..-1]
    self.scenario     = notam_doc.xpath(".//scenario/text()")
    self.accountability = notam_doc.xpath(".//accountId/text()")
    self.location = notam_doc.xpath(".//location/text()")
    self.classification = notam_doc.xpath(".//classification/text()")
    self.issued = notam_doc.xpath(".//issued/text()")
    self.notam_number = notam_doc.xpath(".//number/text()").to_s
    
    case self.classification
    when "DOM"
      month = Time.parse(issued).month.to_s
      self.natural_key = [accountability, month, notam_number, location, issued].join('-')
    when "INTL"
      series = notam_doc.xpath(".//series/text()").to_s
      year_abrev = Time.parse(issued).year.to_s[3,4] # pulls out 19 from 2019
      self.natural_key = [accountability, series, notam_number, year_abrev, location, issued].join('-')
    end    
    self.end_position = notam_doc.xpath(".//endPosition/text()")
    xsi_nil_list = notam_doc.xpath(".//*[@nil='true'][text()]")
    self.xsi_nil_error = xsi_nil_list.size > 0
#    binding.pry if scenario.to_i == 30

    begin
      self.href_with_pound = (notam_doc.xpath(".//associatedAirportHeliport").attribute('href').value.to_s[0] == '#')
    rescue
      self.href_with_pound = false
    end

    begin 
      self.pre_ver_2_12 = false
      tw = notam_doc.xpath(".//Taxiway")
      designator = tw.xpath(".//designator")
      self.pre_ver_2_12 = (not designator.empty?)
    rescue
      self.pre_ver_2_12 = false
    end

    begin 
      self.post_ver_2_12 = false
      tw = notam_doc.xpath(".//Taxiway")
      annotation = tw.xpath(".//annotation")
      self.post_ver_2_12 = (not annotation.empty?)
    rescue
      self.post_ver_2_12 = false
    end
    
    begin
      self.save!
    rescue
      puts "could not save notam #{notam.id} from delta_request #{self.delta_request}"
    end
  end

  def in_scenario_list(array_of_scenarios_as_characters)
    array_of_scenarios_as_characters.gsub(/\s+/, "").split(',').include?(self.scenario)
  end
  
  def in_location_list(array_of_locations_as_characters)
    array_of_locations_as_characters.gsub(/\s+/, "").split(',').include?(self.location)
  end
  
  def in_accountability_list(array_of_accountabilitys_as_characters)
    array_of_accountabilitys_as_characters.gsub(/\s+/, "").split(',').include?(self.accountability)
  end
  
  def in_classification_list(array_of_classifications_as_characters)
    array_of_classifications_as_characters.gsub(/\s+/, "").split(',').include?(self.classification)
  end
  
  def scenario_6000
    self.scenario == '6000'
  end
  
  def filter_selected_in(filter)
    fh = filter.filter_hash
    raise "Can't have both in and out xsi_nil_error specified" if fh[:bool_in_xsi_nil_true] && fh[:bool_out_xsi_nil_true] 
    raise "Can't have both in and out bad_href specified" if fh[:bool_in_bad_href] && fh[:bool_out_bad_href]
    scenarios_in      = (not (in_scenario_list(fh[:in_scenarios ]))) && (fh[:in_scenarios] != '')
    scenarios_out     = (    (in_scenario_list(fh[:out_scenarios]))) && (fh[:out_scenarios] != '')

    locations_in      = (not (in_location_list(fh[:in_locations ]))) && (fh[:in_locations] != '')
    locations_out     = (    (in_location_list(fh[:out_locations]))) && (fh[:out_locations] != '')

    accountabilitys_in      = (not (in_accountability_list(fh[:in_accountabilitys ]))) && (fh[:in_accountabilitys] != '')
    accountabilitys_out     = (    (in_accountability_list(fh[:out_accountabilitys]))) && (fh[:out_accountabilitys] != '')

    classifications_in      = (not (in_classification_list(fh[:in_classifications ]))) && (fh[:in_classifications] != '')
    classifications_out     = (    (in_classification_list(fh[:out_classifications]))) && (fh[:out_classifications] != '')

    xsi_nil_true_in   = (not xsi_nil_error  )                        && fh[:bool_in_xsi_nil_true]
    xsi_nil_true_out  = (    xsi_nil_error  )                        && fh[:bool_out_xsi_nil_true]

    bad_href_in       = (not href_with_pound)                        && fh[:bool_in_bad_href]                # need to clean this up nomencalture dichotomy in single line
    bad_href_out      = (    href_with_pound)                        && fh[:bool_out_bad_href]

    pre_ver_2_12_in   = (not pre_ver_2_12)                           && fh[:bool_in_pre_ver_2_12]
    pre_ver_2_12_out  = (    pre_ver_2_12)                           && fh[:bool_out_pre_ver_2_12]

    post_ver_2_12_in  = (not post_ver_2_12)                          && fh[:bool_in_post_ver_2_12]
    post_ver_2_12_out = (    post_ver_2_12)                          && fh[:bool_out_post_ver_2_12]

    # if doesn't meet critera for being in and filter was on flag this for returning false

    return false if locations_in
    return false if locations_out

    return false if accountabilitys_in
    return false if accountabilitys_out

    return false if classifications_in
    return false if classifications_out

    return false if scenarios_in
    return false if scenarios_out
    return false if xsi_nil_true_in
    return false if xsi_nil_true_out
    return false if bad_href_in
    return false if bad_href_out
    return false if pre_ver_2_12_in
    return false if pre_ver_2_12_out
    return false if post_ver_2_12_in
    return false if post_ver_2_12_out

#    return false if filter.filtering_applied?  # if notam not specifically selected in, then select it out if filtering applied for this filter
    return true
  end

end
  

