Rails.application.routes.draw do
#  get 'notams/hello'
#  get 'greetings/hello'

  get 'graph/graph'
  post 'graph/graph'
  get 'graph/scenario'
  post 'graph/scenario'
  get 'graph/prod'
  post 'graph/prod'
  get 'graph/fntb'
  post 'graph/fntb'

  get 'graph/fntb_test'
  post 'graph/fntb_test'

  get 'graph/shift_left'
  post 'graph/shift_left'
  get 'graph/shift_right'
  post 'graph/shift_right'

  get 'graph/expand_left'
  post 'graph/expand_left'
  get 'graph/expand_right'
  post 'graph/expand_right'

  get 'graph/last_day'
  post 'graph/last_day'
  get 'graph/last_hour'
  post 'graph/last_hour'

  get 'graph/response_time'
  post 'graph/response_time'
  get 'graph/number_of_notams'
  post 'graph/number_of_notams'
  get 'graph/not_parseable'
  post 'graph/not_parseable'

  get 'graph/scenario'
  post 'graph/scenario'
# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
