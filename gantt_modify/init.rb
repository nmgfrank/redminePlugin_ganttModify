require 'redmine'


require_dependency 'lib_redmine_helpers_gantt_patch'
require_dependency 'gantt_helper_patch'
require_dependency 'gantts_controller_patch'


Redmine::Plugin.register :gantt_modify do
  name 'Gantt Modify plugin'
  author 'nmgfrank'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://nmgfrankblog.sinaapp.com/'
  author_url 'http://nmgfrankblog.sinaapp.com/'

  permission :gantt_modify, {:gantts=>[:show_without_version]}, :public=>true
end
