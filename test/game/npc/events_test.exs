defmodule Game.NPC.EventsTest do
  use Data.ModelCase

  @room Test.Game.Room

  alias Game.Message
  alias Game.NPC
  alias Game.NPC.Events
  alias Game.Session.Registry

  setup do
    @room.clear_says()
  end

  describe "room/entered" do
    test "say something to the room when a player enters it" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "say", message: "Hello"}}]}

      state = %{npc_spawner: npc_spawner, npc: npc}
      {:update, ^state} = Events.act_on(state, {"room/entered", {:user, :session, %{name: "Player"}}})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "do nothing when an NPC enters the room" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "say", message: "Hello"}}]}

      state = %{npc_spawner: npc_spawner, npc: npc}
      {:update, ^state} = Events.act_on(state, {"room/entered", {:npc, %{name: "Bandit"}}})

      assert @room.get_says() |> length() == 0
    end

    test "target the player when they entered" do
      Registry.register(%{id: 2})

      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/entered", action: %{type: "target"}}]}

      state = %NPC.State{npc_spawner: npc_spawner, npc: npc}
      {:update, state} = Events.act_on(state, {"room/entered", {:user, :session, %{id: 2, name: "Player"}}})
      assert state.target == {:user, 2}

      assert_received {:"$gen_cast", {:targeted, {:npc, %{id: 1}}}}
    end
  end

  describe "room/leave" do
    test "clears the target when player leaves" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: []}

      state = %NPC.State{npc_spawner: npc_spawner, npc: npc, target: {:user, 2}}
      {:update, state} = Events.act_on(state, {"room/leave", {:user, :session, %{id: 2, name: "Player"}}})
      assert is_nil(state.target)
    end

    test "leaves the target if another player leaves" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: []}

      state = %NPC.State{npc_spawner: npc_spawner, npc: npc, target: {:user, 2}}
      :ok = Events.act_on(state, {"room/leave", {:user, :session, %{id: 3, name: "Player"}}})
    end
  end

  describe "room/heard" do
    test "matches condition" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: %{regex: "hi"}, action: %{type: "say", message: "Hello"}}]}

      state = %{npc_spawner: npc_spawner, npc: npc}
      :ok = Events.act_on(state, {"room/heard", Message.new(%{name: "name"}, "Hi")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end

    test "does not match condition" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: %{regex: "hi"}, action: %{type: "say", message: "Hello"}}]}

      state = %{npc_spawner: npc_spawner, npc: npc}
      :ok = Events.act_on(state, {"room/heard", Message.new(%{name: "name"}, "Howdy")})

      assert [] = @room.get_says()
    end

    test "no condition" do
      npc_spawner = %{room_id: 1}
      npc = %{id: 1, name: "Mayor", events: [%{type: "room/heard", condition: nil, action: %{type: "say", message: "Hello"}}]}

      state = %{npc_spawner: npc_spawner, npc: npc}
      :ok = Events.act_on(state, {"room/heard", Message.new(%{name: "name"}, "Howdy")})

      [{_, message}] = @room.get_says()
      assert message.message == "Hello"
    end
  end
end
