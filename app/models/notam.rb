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

  def scenario_6000
    self.scenario == '6000'
  end
  
  def filter_selected_in(filter)
    fh = filter.filter_hash
    raise "Can't have both in and out scenario_6000 specified" if fh[:bool_in_scenario_6000] && fh[:bool_out_scenario_6000] 
    raise "Can't have both in and out xsi_nil_error specified" if fh[:bool_in_xsi_nil_true] && fh[:bool_out_xsi_nil_true] 
    raise "Can't have both in and out bad_href specified" if fh[:bool_in_bad_href] && fh[:bool_out_bad_href]
    scenario_6000_in  = (   scenario_6000   ) && fh[:bool_in_scenario_6000]
    scenario_6000_out = (not scenario_6000  ) && fh[:bool_out_scenario_6000]
    xsi_nil_true_in   = (    xsi_nil_error  ) && fh[:bool_in_xsi_nil_true]
    xsi_nil_true_out  = (not xsi_nil_error  ) && fh[:bool_out_xsi_nil_true]
    bad_href_in       = (    href_with_pound) && fh[:bool_in_bad_href]
    bad_href_out      = (not href_with_pound) && fh[:bool_out_bad_href]

    return true if scenario_6000_in
    return true if scenario_6000_out
    return true if xsi_nil_true_in
    return true if xsi_nil_true_out
    return true if bad_href_in
    return true if bad_href_out
    return false if filter.filtering_applied?
    return true
  end

end
  

