defmodule AshEvents.Test.Events do
  @moduledoc false
  use Ash.Domain

  resources do
    resource AshEvents.Test.Events.EventResource do
      define :replay_events, action: :replay
    end

    resource AshEvents.Test.Events.SystemActor
  end
end
