if SERVER then
	AddCSLuaFile()
	resource.AddWorkshop("686457995")
	util.AddNetworkString("TTT_SlowMotion_Start")
end

CreateConVar("ttt_sm_startsound", "entities/slow_motion/slow_motion_start.wav", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The sound file, that should be played at the start of the slow motion.")
CreateConVar("ttt_sm_endsound", "entities/slow_motion/slow_motion_end.wav", {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "The sound file, that should be played at the end of the slow motion.")
local duration = CreateConVar("ttt_sm_duration", 1, {FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE, FCVAR_REPLICATED}, "How long should the slow motion be?")

if SERVER then
	hook.Add("TTTEndRound", "TTTSlowMotion", function(result)
		if (result ~= WIN_TIMELIMIT) then
			-- use a network message, because the TTTEndRound hook
			-- doesn't give you the result on the client
			net.Start("TTT_Start_Slowmo")
			net.WriteInt(result, 4)
			net.Broadcast()

			local slowtime = duration:GetInt()
			game.SetTimeScale(0.25)
			local steps = 10
			timer.Simple(1, function()
				for i = 1, steps do -- fade out
					timer.Simple((slowtime / steps) * i, function() game.SetTimeScale(0.25 + 0.75 * ((i^2) / 100)) end)
				end
				timer.Simple(slowtime + 0.05, function() game.SetTimeScale(1) end)
			end)
			timer.Simple(slowtime + 1, function() game.SetTimeScale(1) end) -- ensure the scale is 1 again
		end
	end)
else
	local mt = 0
	local drawSlowMotion = false
	local ColorConstTable, ColorModifyTable, BloomTable
	net.Receive("TTT_SlowMotion_Start", function()
		local result = net.ReadInt(4)
		surface.PlaySound(Sound(GetConVar("ttt_sm_startsound"):GetString()))

		local slowtime = duration:GetInt()
		if (result == WIN_TRAITOR) then
			ColorConstTable = {0.14, 0, 0, 0.026, 0.88, 0.2, 0.5, 0, 2}
			BloomTable = {0.76, 3.74, 45.1, 26.03, 2, 2.58, 1, 1, 1}
		else
			ColorConstTable = {0, 0, 0.1, 0.05, 0.88, 0.65, 0, 0, 0}
			BloomTable = {0.72, 1.73, 37.89, 22.94, 2, 4.23, 1, 1, 1}
		end

		drawSlowMotion = true
		timer.Simple(slowtime + slowtime * 0.5, function() drawSlowMotion = false end)

		local fadeInStepTime = 0.01
		local fadeOutStepTime = slowtime * 1.1
		for i = 1, 20 do
			timer.Simple(fadeInStepTime * i, function() mt = (i^2) / 400 end) -- fade in
			if (i ~= 5) then
				timer.Simple(fadeOutStepTime + fadeInStepTime * 1.25 * i, function() mt = 1 - (i^2) / 400 end) -- fade out
			else
				timer.Simple(fadeOutStepTime + fadeInStepTime * 1.25 * i, function() -- fade out with sound
					mt = 1 - (i^2) / 400
					surface.PlaySound(Sound(GetConVar("ttt_sm_endsound"):GetString()))
				end)
			end
		end
	end)

	hook.Add("RenderScreenspaceEffects", "TTTSlowMotion", function()
		if (drawSlowMotion) then
			ColorModifyTable =
			{
				[ "$pp_colour_addr" ]		= ColorConstTable[1] * mt,
				[ "$pp_colour_addg" ]		= ColorConstTable[2] * mt,
				[ "$pp_colour_addb" ]		= ColorConstTable[3] * mt,
				[ "$pp_colour_brightness" ]	= ColorConstTable[4] * mt,
				[ "$pp_colour_contrast" ]	= 1 + (mt * (ColorConstTable[5]-1)),
				[ "$pp_colour_colour" ]		= 1 + (mt * (ColorConstTable[6]-1)),
				[ "$pp_colour_mulr" ]		= ColorConstTable[7] * mt,
				[ "$pp_colour_mulg" ]		= ColorConstTable[8] * mt,
				[ "$pp_colour_mulb" ]		= ColorConstTable[9] * mt
			}
			DrawToyTown(4, mt * (ScrH() * 0.2))
			DrawBloom(mt * BloomTable[1], mt * BloomTable[2], mt * BloomTable[3], mt * BloomTable[4], math.Round(mt * BloomTable[5]), mt * BloomTable[6], mt * BloomTable[7], mt * BloomTable[8], mt * BloomTable[9])
			DrawColorModify(ColorModifyTable)
		end
	end)
end
