local Combat = require(script.Parent.F2Combat)
Combat.start()
script.Destroying:Connect(Combat.stop)
game:BindToClose(Combat.stop)
