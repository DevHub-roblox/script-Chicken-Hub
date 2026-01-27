local _ENV = (getgenv or getrenv or getfenv)()

do
	if _ENV.rz_down_message then
		_ENV.rz_down_message:Destroy()
	end

	local function CreateDownMessage(Text)
		_ENV.loadedFarm = nil
		_ENV.OnFarm = false

		local Message = Instance.new("Message", workspace)
		Message.Text = Text
		_ENV.rz_down_message = Message

		error(Text, 2)
	end

	-- 🔴 BẬT/TẮT DOWN
	local SCRIPT_DOWN = true

	-- 📝 Nội dung thông báo
	local DOWN_TEXT = [[
⚠️ SCRIPT UNDER MAINTENANCE / UPDATE ⚠️

• Please try again later!
• Discord: SynTrax Hub
• https://discord.gg/WF2sPbv3GD
• Please go to the Discord server to get the temporary script.
• Thank you for using the script.
• Version: Updating...
  
]]

	if SCRIPT_DOWN then
		CreateDownMessage(DOWN_TEXT)
	end
end
