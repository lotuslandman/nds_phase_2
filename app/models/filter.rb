class Filter
  
  def initialize(filter_hash)
    @filter_hash = filter_hash
  end

  def filter_hash
    @filter_hash
  end

  def filtering_applied?
    not (@filter_hash.values - [false, '']).empty?
  end
end


