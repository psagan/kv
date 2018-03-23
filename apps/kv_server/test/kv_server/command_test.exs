defmodule KVServer.CommandTest do
  use ExUnit.Case, async: true
  doctest KVServer.Command

  setup context do
    _ = start_supervised!({KV.Registry, name: context.test})
    %{registry: context.test}
  end

#  test "run create", %{registry: registry} do
#    assert KVServer.Command.run({:create, "Test"}, registry) == {:ok, "OK\r\n"}
#  end

end
