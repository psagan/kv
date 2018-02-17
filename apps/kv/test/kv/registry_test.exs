defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup context do
    #    The start_supervised! function will do the job of starting the KV.
    #    Registry process by calling start_link/1.
    #    The advantage of using start_supervised! is that ExUnit will
    #    guarantee that the registry process will be shutdown before the next test starts.
    #    In other words, it helps guarantee the state of one test is not going to
    #    interfere with the next one in case they depend on shared resources.
    #
    #    https://elixir-lang.org/getting-started/mix-otp/genserver.html
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

  test "spawns bucket", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    KV.Bucket.put(bucket, "milk", 3)
    assert 3 == KV.Bucket.get(bucket, "milk")
  end

  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    Agent.stop(bucket)

    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

  test "removes buckets on crash", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    Agent.stop(bucket, :shutdown)

    _ = KV.Registry.create(registry, "bogus")
    assert KV.Registry.lookup(registry, "shopping") == :error
  end

end