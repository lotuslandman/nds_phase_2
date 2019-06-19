class Notam < ApplicationRecord
  belongs_to :delta_request
#  scope :positive, -> { where("scenario < 602") }
  scope :by_scenario, ->(scenario) { where(scenario: scenario) }
  
  validates :scenario, presence: true
#  validates :xsi_nil_error, presence: true
#  validates :end_position, presence: true
  
#  attr_reader :notam_doc, :trans_id, :scenario, :xsi_nil_present, :begin_position, :end_position, :time_position

#  def initialize(notam_doc)
#    @notam_doc = notam_doc   # this will be a Nokogiri node (or a Nokogiri document with pointer to node) need to search relative from here
#    @trans_id = self.notam_doc.attr('id')
#    @scenario = self.notam_doc.xpath(".//scenario/text()")
#    @begin_position = self.notam_doc.xpath(".//beginPosition/text()")
#    @end_position = self.notam_doc.xpath(".//endPosition/text()")
#    @time_position = self.notam_doc.xpath(".//timePosition/text()")
#    xsi_nil_list = self.notam_doc.xpath(".//*[@nil='true'][text()]")
#    @xsi_nil_present = xsi_nil_list.size > 0
#    #    @fns_id_array = notams.collect { |notam| notam.attr('id') }
#  end

  def fill(notam_doc)
    self.transaction_id = notam_doc.attr('id')[-8..-1]
    self.scenario     = notam_doc.xpath(".//scenario/text()")
    self.end_position = notam_doc.xpath(".//endPosition/text()")
    xsi_nil_list = notam_doc.xpath(".//*[@nil='true'][text()]")
    self.xsi_nil_error = xsi_nil_list.size > 0
    begin
      self.href_with_pound = (notam_doc.xpath(".//associatedAirportHeliport").attribute('href').value.to_s[0] == '#')
    rescue
      false
    end
    begin
      self.save!
    rescue
      puts "could not save notam #{notam.id} from delta_request #{self.delta_request}"
    end
  end

  def in_scenario_list(array_of_scenarios_as_characters)
    array_of_scenarios_as_characters.include?(self.scenario)
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
    xsi_nil_true_in   = (not xsi_nil_error  )                        && fh[:bool_in_xsi_nil_true]
    xsi_nil_true_out  = (    xsi_nil_error  )                        && fh[:bool_out_xsi_nil_true]
    bad_href_in       = (not href_with_pound)                        && fh[:bool_in_bad_href]
    bad_href_out      = (    href_with_pound)                        && fh[:bool_out_bad_href]

    # if doesn't meet critera for being in and filter was on flag this for returning false

    return false if scenarios_in
    return false if scenarios_out
    return false if xsi_nil_true_in
    return false if xsi_nil_true_out
    return false if bad_href_in
    return false if bad_href_out

#    return true if scenarios_in
#    return true if scenarios_out
#    return true if xsi_nil_true_in
#    return true if xsi_nil_true_out
#    return true if bad_href_in
#    return true if bad_href_out

#    return false if filter.filtering_applied?  # if notam not specifically selected in, then select it out if filtering applied for this filter
    return true
  end

end
  

