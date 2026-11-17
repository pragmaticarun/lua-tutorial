#!lua name=inventory
-- host: redis
-- Exercise 4: a Functions library with a writing function and a read-only one.
-- inv_reserve key qty -> remaining stock, or an OUT_OF_STOCK error
-- inv_available key   -> stock (callable with FCALL_RO)
redis.register_function("inv_reserve", function(keys, args)
  local qty = tonumber(args[1])
  if not qty or qty <= 0 then return redis.error_reply("ERR qty must be a positive number") end
  local stock = tonumber(redis.call("GET", keys[1]) or "0")
  if stock < qty then
    return redis.error_reply("OUT_OF_STOCK only " .. stock .. " left")
  end
  return redis.call("DECRBY", keys[1], qty)
end)

redis.register_function{
  function_name = "inv_available",
  callback = function(keys) return tonumber(redis.call("GET", keys[1]) or "0") end,
  flags = { "no-writes" },
}
