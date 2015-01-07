require_dependency 'gantt_helper'

module GanttHelperPatch
    def self.included(base)
        base.send(:include, InstanceMethods)
 
    end

    module InstanceMethods

        def gantt_zoom_link_without_considering_versions(gantt, in_or_out)
            case in_or_out
            when :in
              if gantt.zoom < 4
                link_to_content_update l(:text_zoom_in),
                  params.merge(gantt.params_without_considering_versions.merge(:zoom => (gantt.zoom + 1))),
                  :class => 'icon icon-zoom-in'
              else
                content_tag(:span, l(:text_zoom_in), :class => 'icon icon-zoom-in').html_safe
              end

            when :out
              if gantt.zoom > 1
                link_to_content_update l(:text_zoom_out),
                  params.merge(gantt.params_without_considering_versions.merge(:zoom => (gantt.zoom - 1))),
                  :class => 'icon icon-zoom-out'
              else
                content_tag(:span, l(:text_zoom_out), :class => 'icon icon-zoom-out').html_safe
              end
            end
        end
    end


end

GanttHelper.send(:include, GanttHelperPatch)

