defmodule KV.Registry do
  use GenServer


  def start_link(opts) do
    server = Keyword.fetch!(opts, :name)

    GenServer.start_link(__MODULE__, server, opts)
  end

  def lookup(table, name) do # table can be table created by :ets.create or registered name
    case :ets.lookup(table, name) do
      [{^name, pid}] -> {:ok, pid}
      [] -> :error
    end
  end

  def create(server, name) do
    GenServer.call(server, {:create, name})
  end

  def init(table) do
    names = :ets.new(table, [:named_table, read_concurrency: true])
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:create, name}, _from, {names, refs} = state) do

    # we are providing created ets table here `names`
    case lookup(names, name) do
      {:ok, pid} -> {:reply, pid, state}
      :error ->
        {:ok, bucket_pid} = DynamicSupervisor.start_child(KV.BucketSupervisor, KV.Bucket)
        :ets.insert(names, {name, bucket_pid})
        ref = Process.monitor(bucket_pid)
        refs = Map.put(refs, ref, name)
        {:reply, bucket_pid, {names, refs}}
    end
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    # remove from registry
    {name, refs} = Map.pop(refs, ref)
    :ets.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

end