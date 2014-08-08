-- Postmaster Addon for Elder Scrolls Online
-- Author: Anthony Korchak aka Zierk

PM = {}

PM.name = "Postmaster"
PM.version = 1.0
PM.author = '@Zierk'
PM.funname = "|cEE7600Postmaster|cFFFFFF"
PM.funshortname = "|cEE7600PM|cFFFFFF"
PM.funversion = "|cFFFFFFThe current version of |cEE7600Postmaster|cFFFFFF is |cFFFFB01.0.2.|r"

PMEventHandlers = {}

local TakeAll = false -- flow control for pProcessMail loops


-- default frame location for Postmaster_SavedVariables
PM.defaults = {
  location ={
    x = 200,
    y = 200,
  },
}


--[[  = = = = =  EVENT HANDLERS  = = = = =  ]]--

-- Event handler for EVENT_MAIL_OPEN_MAILBOX, shows xml frames
function pMailboxOpen(eventCode)
  if Postmaster:IsHidden() == true then Postmaster:ToggleHidden() end
end

-- Event handler for EVENT_MAIL_CLOSE_MAILBOX, hides xml frames
function pMailboxClose(eventCode)
  if Postmaster:IsHidden() == false then Postmaster:ToggleHidden() end
end

-- Event handler used to continue the ProcessMailQueue loop
function pEventHandler (eventCode, mailId)
  if TakeAll then pProcessMailQueue() end
end


--[[  = = = = =  CORE FUNCTIONS  = = = = =  ]]--

-- Function to process mail by reading, looting or deleting mail
function pProcessMailQueue()
  local numMail = GetNumMailItems()
  local mailId = MAIL_INBOX:GetOpenMailId()
  
  local senderDisplayName, senderCharacterName, subject, 
        icon, unread, fromSystem, fromCustomerService, 
        returned, numAttachments, attachedMoney, codAmount, 
        expiresInDays, secsSinceReceived = GetMailItemInfo(mailId)
        
  if numMail == 0 then TakeAll = false return end -- no mail in inbox
  if mailId == nil then return end -- safety incase loop continues and there is no mail selected
  if TakeAll == false then return end -- flow control to ensure loop does not fire when player manually interacts with mail or uses the pTake function
  if subject == "" then subject = "(No Subject)" end

  if unread then RequestReadMail(mailId) end -- if mail is unread, read mail
  if numAttachments > 0 then TakeMailAttachedItems(mailId) end -- if mail has an attached item, take it
  if attachedMoney > 0 then TakeMailAttachedMoney(mailId) end -- if mail has money attached, take it
  DeleteMail(mailId, false) -- mail is read, has no items or money attached, delete it

end

-- Function to take all attachments and money from the currently selected mail, then delete
function pTake()

  local openMailId = MAIL_INBOX:GetOpenMailId()
  local numMail = GetNumMailItems()
  
  if numMail == 0 then d(PM.funname..".Take: There is no mail in your mailbox.") return end
  
  local senderDisplayName, senderCharacterName, subject, 
        icon, unread, fromSystem, fromCustomerService, 
        returned, numAttachments, attachedMoney, codAmount, 
        expiresInDays, secsSinceReceived = GetMailItemInfo(openMailId)
        
  if unread then RequestReadMail(openMailId) end   -- failsafe incase mail is not read properly
  if numAttachments > 0 then TakeMailAttachedItems(openMailId) end
  if attachedMoney > 0 then TakeMailAttachedMoney(openMailId) end
  
  DeleteMail(openMailId, false)

  d(PM.funname .. ": Received |cffff00" .. tostring(numAttachments) .. " item(s)|cffffff and |c00ff00" .. tostring(attachedMoney).. " money|cffffff from message.")
  
end

-- Function triggered by mouse-click on the "Take All" XML button
function pTakeAll()
  local numMail = GetNumMailItems()
  
  if numMail == 0 then 
    d(PM.funname..".TakeAll: There is no mail in your mailbox.")
  else
    TakeAll = true  -- TakeAll button pressed, allow pEventHandler to loop pProcessMailQueue
    pProcessMailQueue()
  end  
end

-- save frame location after moving Postmaster XML frame
function pOnMoveStop()
    PM.vars.location.x, PM.vars.location.y = Postmaster:GetScreenRect()  
end

-- Handler for /slash commands
local function commandHandler(text)
  -- Make all input lowercase
  local  input = string.lower(text)
  
  -- General help when using slash commands
  d("|cffffff---------------------------------------------------------------------------------|r")
  d(PM.funname.." by @Zierk")
  d(PM.funshortname..": Open mailbox to interact with the Postmaster frame.")
  d(PM.funshortname..": The '|cFFFFB0Take|cFFFFFF' button will Loot and Delete the currently selected mail.")
  d(PM.funshortname..": The '|cFFFFB0TakeAll|cFFFFFF' button will Loot and Delete all mails in your inbox.")
  d(PM.funversion)
  d("|cffffff---------------------------------------------------------------------------------|r")
 
end

  -- Notification to chat, addon is loaded
local function pIntro()
  EVENT_MANAGER:UnregisterForEvent("Postmaster", EVENT_PLAYER_ACTIVATED)
  d(PM.funname.." has loaded.")
end

-- Initalizing the addon
local function pInitialize( eventCode, addOnName )
  
  if ( addOnName ~= "Postmaster" ) then return end
  
  -- Get saved frame location or set default position
  PM.vars = ZO_SavedVars:NewAccountWide("Postmaster_SavedVariables", PM.version, nil, PM.defaults)
  
  Postmaster:ClearAnchors();
  Postmaster:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, PM.vars.location.x, PM.vars.location.y)

  -- Establish EVENT handlers for RegisteredEvents
  EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_MAIL_OPEN_MAILBOX, pMailboxOpen)
  EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_MAIL_CLOSE_MAILBOX, pMailboxClose)
  EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_MAIL_READABLE, pEventHandler)
  EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_MAIL_TAKE_ATTACHED_ITEM_SUCCESS, pEventHandler)
  EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_MAIL_TAKE_ATTACHED_MONEY_SUCCESS, pEventHandler)
  EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_MAIL_REMOVED, pEventHandler)
  
  
  -- Establish /slash commands
  SLASH_COMMANDS["/postmaster"] = commandHandler
  SLASH_COMMANDS["/pm"] = commandHandler
end

-- Register events
EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_ADD_ON_LOADED, pInitialize)
EVENT_MANAGER:RegisterForEvent("Postmaster", EVENT_PLAYER_ACTIVATED, pIntro)

-- XML Handlers
PMEventHandlers.pTake = pTake
PMEventHandlers.pTakeAll = pTakeAll
PMEventHandlers.pOnMoveStop = pOnMoveStop
