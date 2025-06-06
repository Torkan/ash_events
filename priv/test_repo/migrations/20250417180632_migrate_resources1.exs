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

    create table(:user_roles, primary_key: false) do
      add(:id, :uuid, null: false, default: fragment("gen_random_uuid()"), primary_key: true)

      add(:created_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(:updated_at, :utc_datetime_usec,
        null: false,
        default: fragment("(now() AT TIME ZONE 'utc')")
      )

      add(:name, :text, null: false)

      add(
        :user_id,
        references(:users,
          column: :id,
          name: "user_roles_user_id_fkey",
          type: :uuid,
          prefix: "public"
        ),
        null: false
      )
    end

    create unique_index(:user_roles, [:user_id], name: "user_roles_unique_for_user_index")

    create table(:routed_users, primary_key: false) do
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
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:resource, :text, null: false)
      add(:action, :text, null: false)
      add(:action_type, :text, null: false)
      add(:user_id, :uuid)
      add(:system_actor, :text)
    end
  end

  def down do
    drop(table(:events))

    drop(table(:routed_users))

    drop_if_exists(
      unique_index(:user_roles, [:user_id], name: "user_roles_unique_for_user_index")
    )

    drop(constraint(:user_roles, "user_roles_user_id_fkey"))

    drop(table(:user_roles))

    drop(table(:users))
  end
end
