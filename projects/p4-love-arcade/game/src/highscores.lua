-- highscores.lua: a top-5 table, stored as text lines "SCORE NAME".
local H = {}
H.SIZE = 5

function H.parse(text)
  local list = {}
  for score, name in (text or ""):gmatch("(%d+) (%u+)") do
    list[#list + 1] = { score = tonumber(score), name = name }
  end
  return list
end

function H.serialize(list)
  local out = {}
  for i, e in ipairs(list) do out[i] = ("%d %s"):format(e.score, e.name) end
  return table.concat(out, "\n") .. "\n"
end

--- Would `score` make the table?
function H.qualifies(list, score)
  return score > 0 and (#list < H.SIZE or score > list[#list].score)
end

--- Insert and keep the best SIZE; returns the new rank (1-based) or nil.
function H.insert(list, score, name)
  local rank = #list + 1
  for i, e in ipairs(list) do
    if score > e.score then rank = i break end
  end
  if rank > H.SIZE then return nil end
  table.insert(list, rank, { score = score, name = name })
  list[H.SIZE + 1] = nil
  return rank
end

return H
