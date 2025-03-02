defmodule AshEvents.EventResource.Transformers.AddAttributes do
  @moduledoc false
  use Spark.Dsl.Transformer

  def before?(AshEvents.EventResource.Transformers.AddActions), do: true
  # def before?(AshEvents.EventResource), do: true
  def before?(_), do: false

  def transform(dsl) do
    {:ok, projection_primary_id_type} =
      AshEvents.EventResource.Info.event_resource_entity_id_type(dsl)

    dsl
    |> Ash.Resource.Builder.add_attribute(:id, :integer,
      primary_key?: true,
      writable?: false,
      generated?: true,
      allow_nil?: false
    )
    |> Ash.Resource.Builder.add_attribute(:name, :string, allow_nil?: false)
    |> Ash.Resource.Builder.add_attribute(:entity_id, projection_primary_id_type,
      allow_nil?: false
    )
    |> Ash.Resource.Builder.add_attribute(:version, :string, allow_nil?: false, default: "1.0")
    |> Ash.Resource.Builder.add_attribute(:metadata, :map,
      allow_nil?: false,
      default: %{},
      description: """
        Any relevant metadata you want to store with the event.

        Example: `%{source: "Signup form"}`
      """
    )
    |> Ash.Resource.Builder.add_attribute(:data, :map,
      allow_nil?: false,
      default: %{},
      description: """
      This is where the input arguments from the issued command gets stored.
      """
    )
    |> Ash.Resource.Builder.add_new_attribute(:occurred_at, :utc_datetime_usec,
      allow_nil?: false,
      default: &DateTime.utc_now/0
    )
  end
end
