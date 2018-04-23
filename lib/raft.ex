defmodule Raft do
  @moduledoc """
  A simple implementation of the raft protocol

  https://raft.github.io/
  """

  use GenServer

  alias Raft.PG
  alias Raft.Server
  alias Raft.State

  require Logger

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Announce a node as running for leader
  """
  def announce_candidate(pid, term) do
    GenServer.cast(pid, {:election, :running, self(), term})
  end

  @doc """
  Vote for a node as the leader
  """
  def vote_for(pid, term) do
    GenServer.cast(pid, {:election, :cast_vote, self(), term})
  end

  @doc """
  Set the node as the new leader for a term
  """
  def new_leader(pid, term) do
    GenServer.cast(pid, {:election, :winner, self(), term})
  end

  def init(_) do
    PG.join()
    Process.send_after(self(), {:election, :start, 1}, 5_000 + :rand.uniform(5_000))

    state = %State{
      state: "candidate",
      term: 0,
      highest_seen_term: 0,
      leader_pid: nil,
      votes: []
    }

    {:ok, state}
  end

  def handle_cast({:election, :running, pid, term}, state) do
    {:ok, state} = Server.vote_leader(state, pid, term)
    {:noreply, state}
  end

  def handle_cast({:election, :cast_vote, pid, term}, state) do
    {:ok, state} = Server.vote_received(state, pid, term)
    {:noreply, state}
  end

  def handle_cast({:election, :winner, pid, term}, state) do
    {:ok, state} = Server.set_leader(state, pid, term)
    {:noreply, state}
  end

  def handle_info({:election, :start, term}, state) do
    {:ok, state} = Server.start_election(state, term)
    {:noreply, state}
  end
end
