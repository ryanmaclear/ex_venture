defmodule Game.Command.Map do
  @moduledoc """
  The "map" command
  """

  use Game.Command
  use Game.Zone

  alias Game.Environment
  alias Game.Session.GMCP

  commands(["map"], parse: false)

  @impl Game.Command
  def help(:topic), do: "Map"
  def help(:short), do: "View a map of the zone"

  def help(:full) do
    """
    View the map of the zone your are in. A room is shown as the [ ] symbols. Rooms
    that are connected by open spaces between the [ ] symbols. Walls are drawn
    between rooms that are next to each other but do not have an exit connecting them.

    Sample map:


        [ ]   [ ]
            \\  |
        [ ] - [X]
            /
        [ ]


    Map Legend:
       X  - You
      [ ] - Room
       -  - Path way
       |  - Path way
       \\  - Path way
       /  - Path way

    Map colors show what the room's ecology might be:
    {blue}[ ]{/blue} - Ocean, lake, or river
    {brown}[ ]{/brown} - Mount, or road
    {dark-green}[ ]{/dark-green} - Hill, field, or meadow
    {green}[ ]{/green} - Forest, or jungle
    {grey}[ ]{/grey} - Town, or dungeon
    {light-grey}[ ]{/light-grey} - Inside
    """
  end

  @impl true
  def parse(command, _context), do: parse(command)

  @impl Game.Command
  @doc """
  Parse the command into arguments

      iex> Game.Command.Map.parse("map")
      {}

      iex> Game.Command.Map.parse("map extra")
      {:error, :bad_parse, "map extra"}

      iex> Game.Command.Map.parse("unknown")
      {:error, :bad_parse, "unknown"}
  """
  def parse(command)
  def parse("map"), do: {}

  @impl Game.Command
  @doc """
  View a map of the zone
  """
  def run(command, state)

  def run({}, state) do
    case Environment.room_type(state.save.room_id) do
      :room ->
        room_map(state)

      :overworld ->
        overworld_map(state)
    end
  end

  defp room_map(state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer})
    mini_map = room.zone_id |> @zone.map({room.x, room.y, room.map_layer}, mini: true)
    state |> GMCP.map(mini_map)

    state |> Socket.echo(map)
  end

  defp overworld_map(state = %{save: %{room_id: room_id}}) do
    {:ok, room} = Environment.look(room_id)

    map = room.zone_id |> @zone.map({room.x, room.y})
    mini_map = room.zone_id |> @zone.map({room.x, room.y}, mini: true)
    state |> GMCP.map(mini_map)

    state |> Socket.echo(map)
  end
end
