class NotamsController < ApplicationController
  def index
#    @notams = Notam.all

    respond_to do |format|
      format.html
    end
  end
  def hello
    @notams = Notam.all

    respond_to do |format|
      format.html
    end
  end
end
