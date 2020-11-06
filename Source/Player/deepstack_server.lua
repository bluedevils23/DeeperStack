--- Performs the main loop for DeepStack server.
-- @script deepstack_sever

local arguments = require 'Settings.arguments'
local socket = require('socket')
local constants = require 'Settings.constants'
require 'ACPC.acpc_game'
require 'Player.continual_resolving'


-- *
-- Import try catch functions from https://tboox.org/cn/2016/12/14/try-catch/
-- *
function try(block)

  -- get the try function
  local try = block[1]
  assert(try)

  -- get catch and finally functions
  local funcs = block[2]
  if funcs and block[3] then
      table.join2(funcs, block[2])
  end

  -- try to call it
  local ok, errors = pcall(try)
  if not ok then

      -- run the catch function
      if funcs and funcs.catch then
          funcs.catch(errors)
      end
  end

  -- run the finally function
  if funcs and funcs.finally then
      funcs.finally(ok, errors)
  end

  -- ok?
  if ok then
      return errors
  end
end



-- try
-- {
--   function ()
--     error("error message")
--   end,
--   catch
--   {
--     function (errors)
--       print(errors)
--     end
--   }
-- }

local input_port = 0
if #arg > 0 then
  input_port = tonumber(arg[1])
end

--1.0 create the ACPC game and connect to the server
local acpc_game = ACPCGame()

local continual_resolving = ContinualResolving()

local last_state = nil
local last_node = nil

-- load namespace
-- create a TCP socket and bind it to the local host, at any port
local server = assert(socket.bind("*", input_port))
local ip, port = server:getsockname()
print("listening to " .. ip .. ":" .. port)

local client = server:accept()
print("accepted client")


function getTrace()
  print(debug.traceback())
end


function convert_card_tonumber(card_string)
  if (card_string == 'T') then
    return 10
  end
  if (card_string == 'J') then
    return 11
  end
  if (card_string == 'Q') then
    return 12
  end
  if (card_string == 'K') then
    return 13
  end
  if (card_string == 'A') then
    return 14
  end
  return tonumber(card_string)
end


function sortBoardFlop(board_string)
  if board_string ~= "" then
    local a = {}
    table.insert(a, string.sub(board_string,1,2))
    table.insert(a, string.sub(board_string,3,4))
    table.insert(a, string.sub(board_string,5,6))
    --print(a)
    table.sort(a, function(left, right)
        --print (string.sub(left,1,1))
        --print (string.sub(right,1,1))
        --print (convert_card_tonumber(string.sub(left,1,1)) > convert_card_tonumber(string.sub(right,1,1)))
        return convert_card_tonumber(string.sub(left,1,1)) > convert_card_tonumber(string.sub(right,1,1))
    end )
    --print(a)
    if string.len(board_string) == 6 then
      return a[1] .. a[2] .. a[3]
    else
      return a[1] .. a[2] .. a[3] .. string.sub(board_string,7)
    end
  end
end


function run()
  local line, err = client:receive()
  -- if there was no error, send it back to the client
  if not err then
    print(line)
  else
    print(err)
    client = server:accept()
    print("accepted client")
  end

  local state
  local node
  --2.1 blocks until it's our situation/turn
  state, node = acpc_game:string_to_statenode(line)
  print(line)
  print(state)
  if state["board"] ~= nil then
    print(state['board'])
    state['board'] = sortBoardFlop(state['board'])
    print(state['board'])
    --print(node)
  else
    print(state)
  end

  --did a new hand start?
  if not last_state or last_state.hand_number ~= state.hand_number or node.street < last_node.street then
    continual_resolving:start_new_hand(state)
  end

  --2.2 use continual resolving to find a strategy and make an action in the current node
  local adviced_action = continual_resolving:compute_action(node, state)
  local action_id = adviced_action["action"]
  local betsize = adviced_action["raise_amount"]
  print(action_id)
  print(betsize)
  if betsize ~= nil then
    client:send(tostring(betsize))
  elseif action_id == constants.acpc_actions.fold then
    client:send("f")
  elseif action_id == constants.acpc_actions.ccall then
    client:send("c")
  else
    client:send("WTF")
  end
  last_state = state
  last_node = node
  collectgarbage()
end




while 1 do
  local status, err, ret = xpcall(run, getTrace)
  if status then
    print("Success")
  else
    print("Failure")
    print(err)
 end
end
