-- captures.lua: captures, position captures and back-references
local key, value = ("  codec = av1  "):match("^%s*(%w+)%s*=%s*(%w+)%s*$")
print(key, value)

print(("hello"):match("()ll()"))         -- () captures a position
print(("say 'hi' or \"bye\""):match("([\"'])(.-)%1"))  -- %1 = same quote again

-- gmatch with several captures yields several values per iteration
for k, v in ("w=1920, h=1080, fps=30"):gmatch("(%a+)=(%d+)") do
  io.write(k, "->", v, " ")
end
print()
