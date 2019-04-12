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
      self.save!
    rescue
      puts "could not save notam #{notam.id} from delta_request #{self.delta_request}"
    end
  end

end
  

