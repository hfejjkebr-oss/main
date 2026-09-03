getgenv().SCRIPT_KEY = "KEYLESS"

if not game:IsLoaded() then
repeat
game.Loaded:Wait()
until game:IsLoaded()
end

local placeId = game.PlaceId

local BloxFruitsPlaces = {
[2753915549] = true,
[4442272183] = true,
[7449423635] = true,
[73902483975735] = true,
[76401440271920] = true,
[79091703265657] = true,
[85211729168715] = true,
[92968389658553] = true,
[95165932064349] = true,
[100117331123089] = true,
[101151419317285] = true,
[113741252407134] = true,
[114279672983750] = true,
[117896981438898] = true,
[122478697296975] = true
}

local GrowAGardenPlaces = {
[73504898027860] = true,
[77085202503540] = true,
[97598239454123] = true,
[107289568786498] = true,
[112469282445074] = true,
[126987765280963] = true,
[129343810645058] = true,
[133438856880402] = true,
[137395689498699] = true
}

local MAP_BF = BloxFruitsPlaces[placeId]
local MAP_GROW_A_GARDEN = GrowAGardenPlaces[placeId]

local function Notify(text)
pcall(function()
game:GetService("StarterGui"):SetCore("SendNotification", {
Title = "SEI Hub",
Text = text,
Icon = "rbxassetid://99118312841228",
Duration = 5
})
end)
end

if MAP_BF then

Notify("Success!")  
loadstring(game:HttpGet(  
    "https://api.jnkie.com/api/v1/luascripts/public/e23e752f9b9413c0ef900d5a8e3f28d6983007d5521dddaed6282004840604c1/download"  
))()

elseif MAP_GROW_A_GARDEN then

Notify("Success!")  
loadstring(game:HttpGet(  
    "https://api.jnkie.com/api/v1/luascripts/public/142ace4536e8cfc1adf90a15db247fafb625b9791d1dcec3d89ebaafe41c395e/download"  
))()

else

Notify("This game is not supported")  
task.wait(2)  

game.Players.LocalPlayer:Kick(  
    "This game is not supported by SEI Hub"  
)  

task.wait(1)  
game:Shutdown()

end
