class Filter
  
  def initialize(filter_hash)
    @filter_hash = filter_hash
  end

  def filter_hash
    @filter_hash
  end

  def filtering_applied?
    @filter_hash.values.any?
  end
end


