defmodule AshEvents.Events.Transformers.AddActions do
  @moduledoc false
  alias AshEvents.Helpers
  use Spark.Dsl.Transformer

  def after?(_), do: true

  @metadata_arg %Ash.Resource.Actions.Argument{
    name: :ash_events_metadata,
    allow_nil?: true,
    type: :map,
    default: %{},
    description: "The metadata to store with the event."
  }

  def transform(dsl) do
    event_log_resource = AshEvents.Events.Info.events_event_log!(dsl)
    ignored = AshEvents.Events.Info.events_ignore_actions!(dsl)
    action_versions = AshEvents.Events.Info.events_current_action_versions!(dsl)
    resource = dsl.persist.module
    all_actions = Ash.Resource.Info.actions(dsl)

    event_actions =
      all_actions
      |> Enum.reject(fn action ->
        action.name in ignored or action.type not in [:create, :update, :destroy]
      end)

    all_action_names = all_actions |> Enum.map(& &1.name)

    Enum.each(ignored, fn action_name ->
      if action_name not in all_action_names do
        raise(
          "Action :#{action_name} is listed in ignore_actions, but is not a defined action on #{resource}."
        )
      end
    end)

    action_version_names = Keyword.keys(action_versions)

    Enum.each(action_version_names, fn action_name ->
      if action_name in ignored do
        raise(
          "Action :#{action_name} in #{resource} is listed in ignore_actions, but also has an action version defined."
        )
      end

      if action_name not in all_action_names do
        raise(
          "Action :#{action_name} in #{resource} is listed in action_versions, but is not a defined action on #{resource}."
        )
      end
    end)

    Enum.reduce(event_actions, {:ok, dsl}, fn action, {:ok, dsl} ->
      original_action_name = Helpers.build_original_action_name(action.name)
      original_action = %{action | name: original_action_name, primary?: false}

      manual_action_changes =
        action.changes ++
          [
            %Ash.Resource.Change{
              change: {AshEvents.Events.RemoveLifecycleHooksChange, []},
              on: nil,
              only_when_valid?: false,
              description: nil,
              always_atomic?: false,
              where: []
            }
          ]

      manual_module =
        case action.type do
          :create -> AshEvents.CreateActionWrapper
          :update -> AshEvents.UpdateActionWrapper
          :destroy -> AshEvents.DestroyActionWrapper
        end

      manual_arguments = action.arguments ++ [@metadata_arg]

      manual_action =
        %{
          action
          | manual:
              {manual_module,
               [
                 action: action.name,
                 event_log: event_log_resource,
                 version: Keyword.get(action_versions, action.name, 1)
               ]},
            primary?: action.primary?,
            arguments: manual_arguments,
            changes: manual_action_changes
        }
        |> then(fn action ->
          case action.type do
            :update -> Map.put(action, :require_atomic?, false)
            :destroy -> Map.merge(action, %{require_atomic?: false, return_destroyed?: true})
            _ -> action
          end
        end)

      {:ok,
       dsl
       |> Spark.Dsl.Transformer.replace_entity(
         [:actions],
         manual_action,
         &(&1.name == action.name)
       )
       |> Spark.Dsl.Transformer.add_entity([:actions], original_action)}
    end)
  end
end
