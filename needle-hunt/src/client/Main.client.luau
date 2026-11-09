-- Starts the client: the whole UI (UIController). The client only shows things and asks the
-- server; it never decides who found the needle or what anyone earns.
local UIController = require(script.Parent:WaitForChild("UIController"))
UIController.start()
