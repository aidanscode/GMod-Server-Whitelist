if (SERVER) then

//These are the ranks allowed to add, remove, and view SteamIDs on the whitelist from ingame. This is compatible with ULX ranks
local allowedranks = { 
	"superadmin",
	"admin",
	"owner"
}
//DO NOT EDIT THE WHITELIST FROM THIS FILE, IT WILL NOT WORK
local uwhitelist = {
	"STEAM_0:1:7099", //Garry
	"STEAM_0:0:55581053", //The creator of this addon
	"STEAM_0:0:0" //SteamID of any player on a singleplayer server
}
local uaj = util.TableToJSON(uwhitelist) //uaj stands for Uwhitelist As JSON
local cwf = "" //cwf stands for Current Whitelist File
if !(file.Exists("whitelist", "DATA")) then
	file.CreateDir("whitelist")
end
if !(file.Exists("whitelist/whitelist.txt", "DATA")) then
	file.Write("whitelist/whitelist.txt", uaj)	
end
cwf = file.Read("whitelist/whitelist.txt", "DATA")
local whitelist = util.JSONToTable(cwf)

util.AddNetworkString("OpenWhitelistWindow")
util.AddNetworkString("PrintRemovedSteamID")
util.AddNetworkString("PrintAddedSteamID")
util.AddNetworkString("ChangedWhitelist")

hook.Add("CheckPassword", "CheckWhitelist", function(steamID64, ipAddress, svPass, clPass, name)
	local steamid = util.SteamIDFrom64(steamID64)
	if !(table.HasValue(whitelist, steamid)) then
		print(name.."("..steamid..") is not on the whitelist, kicking...")
		return false, "Sorry! You're not on the whitelist!"
	end
end )
hook.Add("PlayerInitialSpawn", "NotifyOfWhitelist", function(ply)
	ply:SendLua("chat.AddText(Color(0,255,0), 'You were allowed to join this server because you are on the whitelist.')")
end )
hook.Add("PlayerSay", "WhitelistChatCmd", function(ply, text)
	if (string.sub(text, 1, 10) == "!whitelist" or string.sub(text, 1, 10) == "/whitelist") then
		local rank = ply:GetUserGroup()
		if (table.HasValue(allowedranks, rank)) then
			net.Start("OpenWhitelistWindow")
				net.WriteTable(whitelist)
			net.Send(ply)
		else
			ply:SendLua("chat.AddText(Color(255,0,0), 'You have insufficient permissions.')")
		end
		return false
	end
end )

net.Receive("PrintRemovedSteamID", function()
	local removedid = net.ReadString()
	local ply = net.ReadEntity()
	local removerid = ply:SteamID()
	local name = ply:Name()
	print('The SteamID "'..removedid..'" has been removed from the whitelist by '..name..' ('..removerid..')')
end )
net.Receive("PrintAddedSteamID", function()
	local addedid = net.ReadString()
	local ply = net.ReadEntity()
	local adderid = ply:SteamID()
	local name = ply:Name()
	print('The SteamID "'..addedid..'" has been added to the whitelist by '..name..' ('..adderid..')')
end )
net.Receive("ChangedWhitelist", function()
	whitelist = net.ReadTable() //nw stands for New Whitelist
	local newcontent = util.TableToJSON(whitelist)
	file.Write("whitelist/whitelist.txt", newcontent)
end )

end

if (CLIENT) then

local midW, midH = ScrW() / 2, ScrH() / 2
net.Receive("OpenWhitelistWindow", function()
	local mywhitelist = net.ReadTable()

	local DF = vgui.Create("DFrame")
	DF:SetSize(300,300)
	DF:SetPos( midW - ( DF:GetWide() / 2 ), midH - ( DF:GetTall() / 2) )
	DF:SetTitle("Zee's Whitelist Menu")
	DF:SetDraggable(true)
	DF:ShowCloseButton(true)
	DF:MakePopup()

	local IDlabel = vgui.Create("DLabel", DF)
	IDlabel:SetPos(5, 30)
	IDlabel:SetText("Double click a SteamID to remove it")
	IDlabel:SizeToContents()

	local DL = vgui.Create("DListView", DF)
	DL:SetMultiSelect(false)
	DL:SetPos(5,50)
	DL:SetSize(150, 245)
	DL:AddColumn("SteamIDs")
	for k, v in pairs( mywhitelist ) do
		DL:AddLine(v)
	end
	DL.DoDoubleClick = function(parent, index, line)
		chat.AddText(Color(0,255,0), "The SteamID you have removed from the whitelist has been printed into your console.")
		local removeid = line:GetValue(1)
		print("\nYou have removed this SteamID from the whitelist: "..removeid.."\n")
		table.RemoveByValue(mywhitelist, removeid)
		DL:Clear()
		for k, v in pairs(mywhitelist) do
			DL:AddLine(v)
		end
		net.Start("PrintRemovedSteamID")
			net.WriteString(removeid)
			net.WriteEntity(LocalPlayer())
		net.SendToServer()
		net.Start("ChangedWhitelist")
			net.WriteTable(mywhitelist)
		net.SendToServer()
	end

	local AddIDTxt = vgui.Create("DTextEntry", DF)
	AddIDTxt:SetPos(157, 50)
	AddIDTxt:SetSize(136, 25)
	AddIDTxt:SetText("Type a SteamID to Add")

	local AddIDBtn = vgui.Create("DButton", DF)
	AddIDBtn:SetPos(157, 80)
	AddIDBtn:SetText("Add SteamID")
	AddIDBtn:SetSize(136,25)
	AddIDBtn.DoClick = function()
		local addid = AddIDTxt:GetValue()
		table.insert(mywhitelist, 1, addid)
		DL:Clear()
		for k, v in pairs(mywhitelist) do
			DL:AddLine(v)
		end
		chat.AddText(Color(0,255,0), "The SteamID that you have added to the whitelist has been printed into your console.")
		print("\nYou have added this SteamID to the whitelist: "..addid.."\n")
		net.Start("PrintAddedSteamID")
			net.WriteString(addid)
			net.WriteEntity(LocalPlayer())
		net.SendToServer()
		net.Start("ChangedWhitelist")
			net.WriteTable(mywhitelist)
		net.SendToServer()
		AddIDTxt:SetText("Type a SteamID")
	end

	local CheckIDTxt = vgui.Create("DTextEntry", DF)
	CheckIDTxt:SetPos(157,130)
	CheckIDTxt:SetSize(136,25)
	CheckIDTxt:SetText("Type a SteamID to Check")

	local CheckIDBtn = vgui.Create("DButton", DF)
	CheckIDBtn:SetPos(157,160)
	CheckIDBtn:SetText("Check SteamID")
	CheckIDBtn:SetSize(136,25)
	CheckIDBtn.DoClick = function()
		local checkid = CheckIDTxt:GetValue()
		if (table.HasValue(mywhitelist, checkid)) then
			Derma_Message('"'..checkid..'" is on the whitelist!', 'Whitelist SteamID Checker', 'Okay')
		else
			Derma_Message('"'..checkid..'" is NOT on the whitelist!', 'Whitelist SteamID Checker', 'Okay')
		end
	end

	local RemoveIDTxt = vgui.Create("DTextEntry", DF)
	RemoveIDTxt:SetPos(157,210)
	RemoveIDTxt:SetSize(136,25)
	RemoveIDTxt:SetText("Type a SteamID to Remove")

	local RemoveIDBtn = vgui.Create("DButton", DF)
	RemoveIDBtn:SetPos(157,240)
	RemoveIDBtn:SetText("Remove SteamID")
	RemoveIDBtn:SetSize(136,25)
	RemoveIDBtn.DoClick = function()
		local txtremoveid = RemoveIDTxt:GetValue()
		if (table.HasValue(mywhitelist, txtremoveid)) then
			table.RemoveByValue(mywhitelist, txtremoveid)
			DL:Clear()
			for k, v in pairs(mywhitelist) do
				DL:AddLine(v)
			end
			net.Start("PrintRemovedSteamID")
				net.WriteString(txtremoveid)
				net.WriteEntity(LocalPlayer())
			net.SendToServer()
			net.Start("ChangedWhitelist")
				net.WriteTable(mywhitelist)
			net.SendToServer()
		else
			Derma_Message('"'..txtremoveid..'" is NOT on the whitelist!', 'Whitelist SteamID Remove Error', 'Okay')
		end
	end

	local idfinder = vgui.Create("DLabel", DF)
	idfinder:SetPos(157, 270)
	idfinder:SetText("SteamIDFinder.com")
	idfinder:SizeToContents()
end )

end