require_relative 'bootstrap/form_control_class'
require_relative 'bootstrap/readonly'
require_relative 'bootstrap/inline_errors_and_warnings'

module NdrUi
  # Our Bootstrp FormBuilder subclass
  class BootstrapBuilder < ActionView::Helpers::FormBuilder
    # FormBuilder defines `field_helpers`, but it is not an exhaustive
    # list; here, add any others that we may want to be aware of.
    def self.all_known_field_helpers
      field_helpers | field_helpers_from_form_options_helper | field_helpers_from_date_helper
    end

    def self.field_helpers_from_form_options_helper
      [:select, :collection_select, :grouped_collection_select,
       :time_zone_select, :collection_check_boxes, :collection_radio_buttons]
    end

    def self.field_helpers_from_date_helper
      [:date_select, :time_select, :datetime_select]
    end

    include CssHelper
    include Bootstrap::FormControlClass
    include Bootstrap::Readonly
    include Bootstrap::InlineErrorsAndWarnings

    attr_accessor :horizontal_mode

    # Creates a bootstrap control group with label tag for the specified method (and has a direct
    # equivalent in the legacy CautionBuilder). It automatically applies the error or warning class
    # to the control group if the method has errors.
    #
    # ==== Signatures
    #
    #   control_group(method, text=nil, options={}, control_options={}, controls)
    #   control_group(method, text=nil, options={}, control_options={}) do
    #     # controls
    #   end
    #
    # ==== Options
    # * <tt>options</tt> - These are standard options that are applied to the overall form-group
    #   div tag. Options include <tt>:id</tt> and <tt>:class</tt>
    # * <tt>control_options</tt> - These are standard options that are applied to the controls
    #   div tag.
    #
    # ==== Examples
    #
    # TODO: `.form-group` class (margin-left & margin-right : -15px) and `.col-*-*` class (padding-left & padding-right : 15px) should be nested in order to get the correct layout.

    #   <%= form.control_group(:title, 'Demo', {:class => "col-md-6"}, {:id => 'some_id'}, "# Controls go here") %>
    #   # => <div class="form-group col-md-6">
    #           <label for="post_title" class="control-label">Demo</label>
    #           <div id="some_id">
    #             # Controls go here
    #           </div>
    #         </div>
    #
    # You can use a block as well if your alert message is hard to fit into the message parameter. ERb example:
    #
    #   <%= form.control_group(:title, 'Demo', {:class => "col-md-6"}, {:id => 'some_id'}) do %>
    #     # Controls go here
    #   <% end %>
    #
    def control_group(methods, text = nil, options = {}, control_options = {}, controls = '', &block)
      if block_given?
        return control_group(methods, text, options, control_options, @template.capture(&block))
      else
        methods = [methods].compact unless methods.is_a?(Array)

        label_classes = ['control-label']
        label_classes << "col-md-#{label_columns}" if horizontal_mode
        label_html = if methods.present?
                       label(methods.first, text, class: label_classes.join(' '))
                     else
                       @template.content_tag(:span, text, class: label_classes.join(' '))
                     end

        control_options = css_class_options_merge(control_options) do |control_classes|
          # Only add a col-md-N class if none already specified
          if horizontal_mode && control_classes.none? { |css_class| css_class.start_with?('col-') }
            control_classes << "col-md-#{12 - label_columns}"
          end
        end

        @template.content_tag(:div,
                              label_html +
                                @template.content_tag(:div, controls, control_options),
                              control_group_options(methods, options))
      end
    end

    def control_group_options(methods, options)
      css_class_options_merge(options, %w(form-group)) do |group_classes|
        if object && methods.present?
          if methods.any? { |method| object.errors[method].present? }
            group_classes << 'has-error'
          elsif object.respond_to?(:warnings) && methods.any? { |method| object.warnings[method].present? }
            group_classes << 'has-warning'
          end
        end
      end
    end
    private :control_group_options

    # if horizontal_mode is true the label_columns defaults to 3 columns
    def label_columns
      horizontal_mode === true ? 3 : horizontal_mode
    end
  end
end
