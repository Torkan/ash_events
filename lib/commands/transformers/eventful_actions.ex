defmodule AshEvents.Events.Transformers.AddActions do
  @moduledoc false
  use Spark.Dsl.Transformer

  def after?(_), do: true

  @metadata_arg %Ash.Resource.Actions.Argument{
    name: :event_metadata,
    allow_nil?: false,
    type: :map,
    default: %{},
    description: "The metadata to store with the event."
  }

  def transform(dsl) do
    event_resource = AshEvents.Events.Resource.Info.events_event_resource!(dsl)
    ignored = AshEvents.Events.Resource.Info.events_ignore_actions!(dsl)

    actions =
      Ash.Resource.Info.actions(dsl)
      |> Enum.reject(fn action ->
        action.name in ignored or action.type not in [:create, :update, :destroy]
      end)

    IO.inspect(actions, label: "ACTIONS")

    Enum.reduce(actions, {:ok, dsl}, fn action, {:ok, dsl} ->
      replaced_action_name =
        (Atom.to_string(action.name) <> "_ash_events_orig_impl") |> String.to_atom()

      replay_action_name =
        (Atom.to_string(action.name) <> "_ash_events_replay") |> String.to_atom()

      replaced_action = %{action | name: replaced_action_name, primary?: false}

      replay_module =
        case action.type do
          :create -> AshEvents.ReplayCreateWrapper
          :update -> AshEvents.ReplayUpdateWrapper
          :destroy -> AshEvents.ReplayDestroyWrapper
        end

      replay_action = %{
        action
        | name: replay_action_name,
          primary?: false,
          manual: {replay_module, [action: replaced_action_name]}
      }

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
                 action: replaced_action_name,
                 event_resource: event_resource,
                 replay_action: replay_action_name
               ]},
            primary?: action.primary?,
            arguments: manual_arguments
        }

      {:ok,
       dsl
       |> Spark.Dsl.Transformer.replace_entity(
         [:actions],
         manual_action,
         &(&1.name == action.name)
       )
       |> Spark.Dsl.Transformer.add_entity([:actions], replaced_action)
       |> Spark.Dsl.Transformer.add_entity([:actions], replay_action)}
    end)
  end
end
