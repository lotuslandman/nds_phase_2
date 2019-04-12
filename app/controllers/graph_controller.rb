require 'time'

class GraphController < ApplicationController

  def environment_to_stream_map
    case session[:env]
    when "fntb"
      1   # these are the stream ids
    when "prod"
      2
    when "acy"
      3
    else
      exit
    end
  end

  def find_start_of_range
    if params[:start_graph] == "" or params[:start_graph].nil?
      start_date_string = session[:start_date]  # assumes session is string
    else
      start_date_string = params[:start_graph]
    end
    session[:start_date] = start_date_string
    Time.parse(start_date_string)
  end    

  def find_end_of_range
    if params[:end_graph] == "" or params[:end_graph].nil?
      end_date_string = session[:end_date]  # assumes session is string
    else
      end_date_string = params[:end_graph]
    end
    session[:end_date] = end_date_string
    Time.parse(end_date_string)
  end
  
  def graph
#   update_database_for_all_streams
    @ds = DeltaStream.find_by_id(environment_to_stream_map)   # uses session[:env] to get the right DeltaStream
    @start_date = find_start_of_range
    @end_date = find_end_of_range
    @scenario  = params[:scenario]  # if no scenario entered no need to store
    @y_axis = session[:y_axis]
    @get_column_chart_data = @ds.column_chart_data(@start_date, @end_date, @scenario, @y_axis) if ((@start_date - @end_date) < 31.days)
  end

#  def scenario
#    @ds = DeltaStream.find_by_id(stream_to_environment_map)
#    DeltaStream.update_database_for_all_streams
#    st = params[:start_graph].to_i * -1
#    en = params[:end_graph].to_i * -1
#    scenario  = params[:scenario]
#  end
  def find_full_time
    sd = Time.parse(session[:start_date])
    ed = Time.parse(session[:end_date])
    [sd, ed, (ed - sd) ]
  end
  
  def shift_left
    sd, ed, full_time = find_full_time
    sd = sd - full_time
    ed = ed - full_time
    session[:start_date] = sd.to_s
    session[:end_date] = ed.to_s
    redirect_to :action => "graph"
  end

  def shift_right
    sd, ed, full_time = find_full_time
    sd = sd + full_time
    ed = ed + full_time
    session[:start_date] = sd.to_s
    session[:end_date] = ed.to_s
    redirect_to :action => "graph"
  end

  def expand_left
    sd, ed, full_time = find_full_time
    sd = sd - full_time
    session[:start_date] = sd.to_s
    redirect_to :action => "graph"
  end

  def expand_right
    sd, ed, full_time = find_full_time
    ed = ed + full_time
    session[:end_date] = ed.to_s
    redirect_to :action => "graph"
  end

  def last_hour
    session[:start_date] = (Time.now - 60.minutes).to_s
    session[:end_date] = Time.now.to_s
    redirect_to :action => "graph"
  end

  def last_day
    session[:start_date] = (Time.now - 24.hours).to_s
    session[:end_date] = Time.now.to_s
    redirect_to :action => "graph"
  end

  def response_time
    session[:y_axis] = "response_time"
    redirect_to :action => "graph"
  end
  
  def number_of_notams
    session[:y_axis] = "number_of_notams"
    redirect_to :action => "graph"
  end
  
  def not_parseable
    session[:y_axis] = "not_parseable"
    redirect_to :action => "graph"
  end
  
  def prod
    session[:env] = "prod"
    redirect_to :action => "graph"
   end

  def fntb
    session[:env] = "fntb"
    redirect_to :action => "graph"
   end

  def fntb_test
    session[:env] = "fntb_test"
    redirect_to :action => "graph"
   end
end
