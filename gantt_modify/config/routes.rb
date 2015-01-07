# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html


get '/projects/:project_id/issues/gantt_without_version', :to => 'gantts#show_without_version' 

get '/issues/gantt/gantt_without_version', :to => 'gantts#show_without_version' 
