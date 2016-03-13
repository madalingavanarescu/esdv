ActiveAdmin.register Target do
  permit_params :startup_id, :assigner_id, :role, :status, :title, :description, :status, :resource_url,
    :completion_instructions, :due_date_date, :due_date_time_hour, :due_date_time_minute, :slideshow_embed,
    :completed_at_date, :completed_at_time_hour, :completed_at_time_minute, :completion_comment, :rubric,
    :remote_rubric_url

  scope :all
  scope :pending
  scope :expired

  preserve_default_filters!
  filter :startup,
    collection: Startup.batched,
    label: 'Product',
    member_label: proc { |startup| startup.display_name }

  filter :role, as: :select, collection: Target.valid_roles
  filter :status, as: :select, collection: Target.valid_statuses

  member_action :duplicate, method: :get do
    target = Target.find(params[:id])
    redirect_to(
      new_admin_target_path(
        target: {
          role: target.role, title: target.title, description: target.description,
          resource_url: target.resource_url, completion_instructions: target.completion_instructions,
          due_date_date: target.due_date_date, due_date_time_hour: target.due_date.hour,
          due_date_time_minute: target.due_date.min
        }
      )
    )
  end

  action_item :duplicate, only: :show do
    link_to 'Duplicate', duplicate_admin_target_path(id: params[:id])
  end

  index do
    selectable_column

    column :product do |target|
      startup = target.startup

      a href: admin_startup_path(startup) do
        span startup.product_name

        if startup.name.present?
          span class: 'wrap-with-paranthesis' do
            startup.name
          end
        end
      end
    end

    column :role do |target|
      t("role.#{target.role}")
    end

    column :status do |target|
      if target.founder?
        'N/A'
      elsif target.expired?
        'Expired'
      else
        t("target.status.#{target.status}")
      end
    end

    column :title
    column :assigner

    actions defaults: true do |target|
      link_to 'Duplicate', duplicate_admin_target_path(target)
    end
  end

  show do |target|
    if target.timeline_events.present?
      panel 'Linked Timeline Events' do
        table_for target.timeline_events.includes(:timeline_event_type) do
          column 'Timeline Event' do |timeline_event|
            a href: admin_timeline_event_path(timeline_event) do
              "##{timeline_event.id} #{timeline_event.timeline_event_type.title}"
            end
          end

          column :description
          column :verified?
          column :created_at
        end
      end
    end

    attributes_table do
      row :product do
        startup = target.startup

        a href: admin_startup_path(startup) do
          span startup.product_name

          if startup.name.present?
            span class: 'wrap-with-paranthesis' do
              startup.name
            end
          end
        end
      end

      row :role do
        t("role.#{target.role}")
      end

      row :status do
        if target.founder?
          'N/A'
        elsif target.expired?
          'Expired'
        else
          t("target.status.#{target.status}")
        end
      end

      row :title
      row :assigner
      row :rubric do
        if target.rubric.present?
          link_to target.rubric_identifier, target.rubric.url
        end
      end

      row :description do
        target.description.html_safe
      end

      row :slideshow_embed
      row :resource_url
      row :completion_instructions
      row :due_date
      row :completed_at
      row :completion_comment
      row :created_at
      row :updated_at
    end
  end

  form partial: 'admin/targets/form'
end
