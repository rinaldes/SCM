module BootstrapPaginationHelper
  class LinkRenderer < WillPaginate::ActionView::LinkRenderer
    protected
    def page_number(page)
      unless page == current_page
        link(page, page, :rel => rel_value(page))
      else
        link(page, "#", :class => 'active')
      end
    end

    def previous_or_next_pages(page, text, classname)
      if page > 0 && page <= @collection.total_pages
        link(text.html_safe, page, :class => classname)
      else
        link(text.html_safe, "#", :class => classname + ' disabledccc')
      end
    end

    def html_container(html)
      # tag(:div, tag(:ul, html), container_attributes)
      # tag(:ul, html, container_attributes)
      tag(:ul, html, {class: 'pagination pagination-sm'})
    end

    private
      def link(text, target, attributes = {})
        if target.is_a? Fixnum
          attributes[:rel] = rel_value(target)
          target = url(target)
        end
        unless target == "#"
            attributes[:href] = target
        end
        classname = attributes[:class]
        # attributes['data-remote'] = true
        attributes[:class] = ""
        # attributes.delete(:classname)
        tag(:li, tag(:a, text, attributes), {:class => classname})
      end
    end
end
