require_dependency 'gantts_controller'
require_dependency 'redmine/helpers/gantt'

module GanttsControllerPatch
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do 
            
        end
    end

    module InstanceMethods

        def show_without_version
            @gantt = Redmine::Helpers::Gantt.new(params)

            @gantt.project = @project
            retrieve_query
            @query.group_by = nil
            @gantt.query = @query if @query.valid?
            basename = (@project ? "#{@project.identifier}-" : '') + 'gantt'
            respond_to do |format|
              Rails.logger.info  format 
              format.html { render :action => "show_without_version", :layout => !request.xhr? }
              format.png  { send_data(@gantt.to_image, :disposition => 'inline', :type => 'image/png', :filename => "#{basename}.png") } if @gantt.respond_to?('to_image')
              format.pdf  { send_data(@gantt.to_pdf_without_concidering_versions, :type => 'application/pdf', :filename => "#{basename}.pdf") }
            end
        end

    end
end

GanttsController.send(:include, GanttsControllerPatch)
