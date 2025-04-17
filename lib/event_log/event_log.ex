defmodule AshEvents.EventLog do
  @moduledoc """
    Extension to use on the Ash.Resource that will persist events.
  """

  defmodule ReplayOverride do
    defstruct [:event_log, :event_action, :versions, :route_to]
  end

  defmodule RouteTo do
    defstruct [:resource, :action]
  end

  @route_to %Spark.Dsl.Entity{
    name: :route_to,
    describe: """
    Routes the event to a different action.
    """,
    target: RouteTo,
    schema: [
      resource: [
        type: :atom,
        required: true
      ],
      action: [
        type: :atom,
        required: true
      ]
    ],
    args: [:resource, :action]
  }

  @replay_override %Spark.Dsl.Entity{
    name: :replay_override,
    describe: "Overrides the default event replay behavior for a specific resource action.",
    examples: [
      """
      replay_overrides do
        replay_override MyApp.Accounts.User, :create_ash_events_impl do
          versions([1])
          route_to MyApp.Accounts.User, :create_v1
        end
      end
      """
    ],
    target: ReplayOverride,
    schema: [
      event_log: [
        type: :atom,
        required: true
      ],
      event_action: [
        type: :atom,
        required: true
      ],
      versions: [
        type: {:list, :integer},
        doc:
          "A list of event versions to match on. The event will only be routed here if the version of the event matches one of the listed versions.",
        required: true
      ]
    ],
    args: [:event_log, :event_action],
    entities: [route_to: [@route_to]]
  }

  @replay_overrides %Spark.Dsl.Section{
    name: :replay_overrides,
    entities: [@replay_override]
  }

  @persist_actor_primary_key %Spark.Dsl.Entity{
    name: :persist_actor_primary_key,
    describe:
      "Store the actor's primary key in the event if an actor is set, and the actor matches the resource type. You can define an entry for each actor type.",
    examples: [
      "persist_actor_primary_key :user_id, MyApp.Accounts.User",
      "persist_actor_primary_key :system_actor, MyApp.SystemActor"
    ],
    no_depend_modules: [:destination],
    target: AshEvents.EventLog.PersistActorPrimaryKey,
    args: [:name, :destination],
    schema: AshEvents.EventLog.PersistActorPrimaryKey.schema()
  }

  @event_log %Spark.Dsl.Section{
    name: :event_log,
    schema: [
      clear_records_for_replay: [
        type: {:behaviour, AshEvents.ClearRecordsForReplay},
        required: false,
        doc: """
        A module with the AshEvents.ClearRecords-behaviour, that is expected to clear all
        records before an event replay.
        """
      ],
      record_id_type: [
        type: :any,
        doc:
          "The type of the primary key used by the system, which will be the type of the `record_id`-field on the events. Defaults to :uuid.",
        default: :uuid
      ]
    ],
    entities: [@persist_actor_primary_key],
    examples: [
      """
      event_log do
        record_id_type :integer # (default is :uuid)
        persist_actor_primary_key :user_id, MyApp.Accounts.User
        persist_actor_primary_key :system_actor, MyApp.SystemActor, attribute_type: :string
      end
      """
    ]
  }

  use Spark.Dsl.Extension,
    transformers: [
      AshEvents.EventLog.Transformers.AddActions,
      AshEvents.EventLog.Transformers.AddAttributes,
      AshEvents.EventLog.Transformers.ValidatePersistActorPrimaryKey
    ],
    sections: [@event_log, @replay_overrides]
end

defmodule AshEvents.EventLog.Info do
  @moduledoc "Introspection helpers for `AshEvents.EventLog`"
  use Spark.InfoGenerator,
    extension: AshEvents.EventLog,
    sections: [:event_log, :replay_overrides]
end
