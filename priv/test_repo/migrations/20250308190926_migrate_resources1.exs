defmodule AshEvents.TestRepo.Migrations.MigrateResources1 do
  @moduledoc """
  Updates resources based on their most recent snapshots.

  This file was autogenerated with `mix ash_postgres.generate_migrations`
  """

  use Ecto.Migration

  def up do
    create table(:users, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true)

      add(:created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(:updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(:email, :text, null: false)
      add(:given_name, :text, null: false)
      add(:family_name, :text, null: false)
    end

    create table(:events, primary_key: false) do
      add(:id, :bigserial, null: false, primary_key: true)
      add(:record_id, :uuid, null: false)
      add(:version, :bigint, null: false, default: 1)
      add(:metadata, :map, null: false, default: %{})
      add(:data, :map, null: false, default: %{})

      add(:occurred_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(:ash_events_resource, :text, null: false)
      add(:ash_events_action, :text, null: false)
      add(:ash_events_action_type, :text, null: false)
      add(:user_id, :uuid)
      add(:system_actor, :text)
    end
  end

  def down do
    drop(table(:events))

    drop(table(:users))
  end
end
