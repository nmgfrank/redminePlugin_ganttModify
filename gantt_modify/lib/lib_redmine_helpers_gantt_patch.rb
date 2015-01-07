require_dependency 'redmine/helpers/gantt'

module LibRedmineHelpersPatch
    def self.included(base)
        base.send(:include, InstanceMethods)
        base.class_eval do 

        end
           
    end

    module InstanceMethods


        # ------ with no width limit -------------

        def html_subject_with_no_width_limit(params, subject, options={})
            style = "position: absolute;top:#{params[:top]}px;left:#{params[:indent]}px;"
            #style << "width:#{params[:subject_width] - params[:indent]}px;" if params[:subject_width]
            output = view.content_tag(:div, subject,
                                      :class => options[:css], :style => style,
                                      :title => options[:title],
                                      :id => options[:id])
            @subjects << output
            output
        end

        def render_issues_with_no_width_limit(issues, options={})
            @issue_ancestors = []
            issues.each do |i|
              subject_for_issue_with_no_width_limit(i, options) unless options[:only] == :lines
              line_for_issue(i, options) unless options[:only] == :subjects
              options[:top] += options[:top_increment]
              @number_of_rows += 1
              break if abort?
            end
            options[:indent] -= (options[:indent_increment] * @issue_ancestors.size)
        end


        def subject_for_issue_with_no_width_limit(issue, options)
            while @issue_ancestors.any? && !issue.is_descendant_of?(@issue_ancestors.last)
              @issue_ancestors.pop
              options[:indent] -= options[:indent_increment]
            end
            output = case options[:format]
            when :html
              css_classes = ''
              css_classes << ' issue-overdue' if issue.overdue?
              css_classes << ' issue-behind-schedule' if issue.behind_schedule?
              css_classes << ' icon icon-issue' unless Setting.gravatar_enabled? && issue.assigned_to
              css_classes << ' issue-closed' if issue.closed?
              if issue.start_date && issue.due_before && issue.done_ratio
                progress_date = calc_progress_date(issue.start_date,
                                                   issue.due_before, issue.done_ratio)
                css_classes << ' behind-start-date' if progress_date < self.date_from
                css_classes << ' over-end-date' if progress_date > self.date_to
              end
              s = "".html_safe
              if issue.assigned_to.present?
                assigned_string = l(:field_assigned_to) + ": " + issue.assigned_to.name
                s << view.avatar(issue.assigned_to,
                                 :class => 'gravatar icon-gravatar',
                                 :size => 10,
                                 :title => assigned_string).to_s.html_safe
              end
              s << view.link_to_issue(issue).html_safe
              subject = view.content_tag(:span, s, :class => css_classes).html_safe
              html_subject_with_no_width_limit(options, subject, :css => "issue-subject",
                           :title => issue.subject, :id => "issue-#{issue.id}") + "\n"
            when :image
              image_subject(options, issue.subject)
            when :pdf
              pdf_new_page?(options)
              pdf_subject(options, issue.subject)
            end
            unless issue.leaf?
              @issue_ancestors << issue
              options[:indent] += options[:indent_increment]
            end
            output
        end




        #  -----   without_concidering_versions -----------

        def common_params_without_considering_versions
            { :controller => 'gantts', :action => 'show_without_version', :project_id => @project }
        end

        def params_without_considering_versions
            common_params_without_considering_versions.merge({:zoom => zoom, :year => year_from,
                             :month => month_from, :months => months})
        end


        def render_project_without_concidering_versions(project, options={})

            subject_for_project(project, options) unless options[:only] == :lines
            line_for_project(project, options) unless options[:only] == :subjects
            options[:top] += options[:top_increment]
            options[:indent] += options[:indent_increment]
            @number_of_rows += 1
            return if abort?
            issues = project_issues(project)
            sort_issues!(issues)
            if issues
              render_issues_with_no_width_limit(issues, options)
              return if abort?
            end
            versions = project_versions(project)
            versions.each do |version|
              #render_version(project, version, options)
            end
            # Remove indent to hit the next sibling
            options[:indent] -= options[:indent_increment]
        end

        def render_without_concidering_versions(options={})

            options = {:top => 0, :top_increment => 20,
                       :indent_increment => 20, :render => :subject,
                       :format => :html}.merge(options)
            indent = options[:indent] || 4
            @subjects = '' unless options[:only] == :lines
            @lines = '' unless options[:only] == :subjects
            @number_of_rows = 0
            Project.project_tree(projects) do |project, level|
              options[:indent] = indent + level * options[:indent_increment]
              render_project_without_concidering_versions(project, options)
              break if abort?
            end
            @subjects_rendered = true unless options[:only] == :lines
            @lines_rendered = true unless options[:only] == :subjects
            render_end(options)
        end

        # Renders the subjects of the Gantt chart, the left side.
        def subjects_without_concidering_versions(options={})
            render_without_concidering_versions(options.merge(:only => :subjects)) unless @subjects_rendered
            @subjects
        end

        # Renders the lines of the Gantt chart, the right side
        def lines_without_concidering_versions(options={})
            render_without_concidering_versions(options.merge(:only => :lines)) unless @lines_rendered
            @lines
        end

        def to_pdf_without_concidering_versions
            pdf = ::Redmine::Export::PDF::ITCPDF.new(current_language)
            pdf.SetTitle("#{l(:label_gantt)} #{project}")
            pdf.alias_nb_pages
            pdf.footer_date = format_date(Date.today)
            pdf.AddPage("L")
            pdf.SetFontStyle('B', 12)
            pdf.SetX(15)
            pdf.RDMCell(PDF::LeftPaneWidth, 20, project.to_s)
            pdf.Ln
            pdf.SetFontStyle('B', 9)
            subject_width = PDF::LeftPaneWidth
            header_height = 5
            headers_height = header_height
            show_weeks = false
            show_days = false
            if self.months < 7
              show_weeks = true
              headers_height = 2 * header_height
              if self.months < 3
                show_days = true
                headers_height = 3 * header_height
              end
            end
            g_width = PDF.right_pane_width
            zoom = (g_width) / (self.date_to - self.date_from + 1)
            g_height = 120
            t_height = g_height + headers_height
            y_start = pdf.GetY
            # Months headers
            month_f = self.date_from
            left = subject_width
            height = header_height
            self.months.times do
              width = ((month_f >> 1) - month_f) * zoom
              pdf.SetY(y_start)
              pdf.SetX(left)
              pdf.RDMCell(width, height, "#{month_f.year}-#{month_f.month}", "LTR", 0, "C")
              left = left + width
              month_f = month_f >> 1
            end
            # Weeks headers
            if show_weeks
              left = subject_width
              height = header_height
              if self.date_from.cwday == 1
                # self.date_from is monday
                week_f = self.date_from
              else
                # find next monday after self.date_from
                week_f = self.date_from + (7 - self.date_from.cwday + 1)
                width = (7 - self.date_from.cwday + 1) * zoom-1
                pdf.SetY(y_start + header_height)
                pdf.SetX(left)
                pdf.RDMCell(width + 1, height, "", "LTR")
                left = left + width + 1
              end
              while week_f <= self.date_to
                width = (week_f + 6 <= self.date_to) ? 7 * zoom : (self.date_to - week_f + 1) * zoom
                pdf.SetY(y_start + header_height)
                pdf.SetX(left)
                pdf.RDMCell(width, height, (width >= 5 ? week_f.cweek.to_s : ""), "LTR", 0, "C")
                left = left + width
                week_f = week_f + 7
              end
            end
            # Days headers
            if show_days
              left = subject_width
              height = header_height
              wday = self.date_from.cwday
              pdf.SetFontStyle('B', 7)
              (self.date_to - self.date_from + 1).to_i.times do
                width = zoom
                pdf.SetY(y_start + 2 * header_height)
                pdf.SetX(left)
                pdf.RDMCell(width, height, day_name(wday).first, "LTR", 0, "C")
                left = left + width
                wday = wday + 1
                wday = 1 if wday > 7
              end
            end
            pdf.SetY(y_start)
            pdf.SetX(15)
            pdf.RDMCell(subject_width + g_width - 15, headers_height, "", 1)
            # Tasks
            top = headers_height + y_start
            options = {
              :top => top,
              :zoom => zoom,
              :subject_width => subject_width,
              :g_width => g_width,
              :indent => 0,
              :indent_increment => 5,
              :top_increment => 5,
              :format => :pdf,
              :pdf => pdf
            }
            render(options)
            pdf.Output
        end

    end
end

Redmine::Helpers::Gantt.send(:include, LibRedmineHelpersPatch)
