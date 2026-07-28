SoulwatchDB = SoulwatchDB or {}
SoulwatchDB.data = SoulwatchDB.data or {}

local SW = CreateFrame("Frame", "SoulwatchFrame", UIParent)

SW:RegisterEvent("PLAYER_LOGIN")
SW:RegisterEvent("RAID_ROSTER_UPDATE")
SW:RegisterEvent("PARTY_MEMBERS_CHANGED")
SW:RegisterEvent("CHAT_MSG_ADDON")
SW:RegisterEvent("CHAT_MSG_SPELL_SELF_BUFF")
SW:RegisterEvent("CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF")
SW:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS")

SW.data = SoulwatchDB.data
SW.rows = {}
SW.elapsed = 0

SW.priority = {
  ["MainTank"] = true,
}

SW.classColors = {
  WARRIOR = "|cffC79C6E",
  MAGE = "|cff69CCF0",
  PRIEST = "|cffFFFFFF",
  WARLOCK = "|cff9482C9",
  DRUID = "|cffFF7D0A",
  ROGUE = "|cffFFF569",
  HUNTER = "|cffABD473",
  SHAMAN = "|cff0070DE",
  PALADIN = "|cffF58CBA",
}

function SW:SaveData()
  SoulwatchDB.data = self.data
end

function SW:GetChannel()
  if GetNumRaidMembers and GetNumRaidMembers() > 0 then
    return "RAID"
  elseif GetNumPartyMembers and GetNumPartyMembers() > 0 then
    return "PARTY"
  end

  return nil
end

function SW:SendState(lock, target, duration)
  local channel = self:GetChannel()

  if channel and SendAddonMessage then
    SendAddonMessage(
      "SOULWATCH",
      lock..";"..(target or "")..";"..(duration or 0),
      channel
    )
  end
end

SW.AssignFrame = CreateFrame("Frame", "SoulwatchAssignFrame", UIParent)
SW.AssignFrame:SetWidth(220)
SW.AssignFrame:SetHeight(280)
SW.AssignFrame:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 8,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
SW.AssignFrame:SetBackdropColor(0.02,0.02,0.02,0.95)
SW.AssignFrame:SetBackdropBorderColor(0.65,0.15,1,1)
SW.AssignFrame:Hide()

SW.AssignScroll = CreateFrame(
  "ScrollFrame",
  "SoulwatchAssignScroll",
  SW.AssignFrame,
  "UIPanelScrollFrameTemplate"
)

SW.AssignScroll:SetPoint("TOPLEFT", SW.AssignFrame, "TOPLEFT", 15, -28)
SW.AssignScroll:SetPoint("BOTTOMRIGHT", SW.AssignFrame, "BOTTOMRIGHT", -32, 15)

SW.AssignContent = CreateFrame("Frame", nil, SW.AssignScroll)

SW.AssignContent:SetWidth(170)
SW.AssignContent:SetHeight(1)

SW.AssignScroll:SetScrollChild(SW.AssignContent)

SW.AssignButtons = {}

SW.AssignClose = CreateFrame("Button", nil, SW.AssignFrame, "UIPanelCloseButton")
SW.AssignClose:SetPoint("TOPRIGHT", SW.AssignFrame, "TOPRIGHT", -2, -2)

SW:SetWidth(320)
SW:SetHeight(180)
SW:SetPoint("CENTER", UIParent, "CENTER", 350, 0)

SW:SetBackdrop({
  bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true,
  tileSize = 8,
  edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
SW:SetBackdropColor(0.02,0.02,0.02,0.92)
SW:SetBackdropBorderColor(0.65,0.15,1,1)

SW:EnableMouse(true)
SW:SetMovable(true)
SW:RegisterForDrag("LeftButton")

SW:SetScript("OnDragStart", function()
  this:StartMoving()
end)

SW:SetScript("OnDragStop", function()
  this:StopMovingOrSizing()

  local point, _, relativePoint, x, y = this:GetPoint()

  SoulwatchDB.position = {
    point = point,
    relativePoint = relativePoint,
    x = x,
    y = y
  }
end)

SW.title = SW:CreateFontString(nil,"OVERLAY","GameFontNormalLarge")
SW.title:SetPoint("TOPLEFT", SW, "TOPLEFT", 10, -8)
SW.title:SetText("|cffbb55ffSoulwatch|r")

SW.info = SW:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
SW.info:SetPoint("TOPLEFT", SW, "TOPLEFT", 12, -26)
SW.info:SetText("Left: target  |  Right: assign  |  Middle: start/reset")
SW.CloseButton = CreateFrame(
  "Button",
  nil,
  SW,
  "UIPanelCloseButton"
)

SW.CloseButton:SetPoint(
  "TOPRIGHT",
  SW,
  "TOPRIGHT",
  -2,
  -2
)

function SW:CreateRow(i)
  local row = CreateFrame("Button", nil, SW)

  row:RegisterForClicks("LeftButtonUp", "RightButtonUp", "MiddleButtonUp")

  row:SetWidth(292)
  row:SetHeight(24)
  row:SetPoint("TOPLEFT", SW, "TOPLEFT", 12, -44 - ((i-1)*26))

  row:SetBackdrop({
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileSize = 8,
    edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })

  row.icon = row:CreateTexture(nil,"ARTWORK")
  row.icon:SetWidth(18)
  row.icon:SetHeight(18)
  row.icon:SetPoint("LEFT", row, "LEFT", 5, 0)
  row.icon:SetTexture("Interface\\Icons\\Spell_Shadow_SoulGem")

  row.name = row:CreateFontString(nil,"OVERLAY","GameFontNormal")
  row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
  row.name:SetWidth(110)
  row.name:SetJustifyH("LEFT")

  row.target = row:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
  row.target:SetPoint("LEFT", row, "LEFT", 135, 0)
  row.target:SetWidth(110)
  row.target:SetJustifyH("LEFT")
  row.targetButton = CreateFrame("Button", nil, row)

row.targetButton:SetPoint("LEFT", row, "LEFT", 135, 0)
row.targetButton:SetWidth(110)
row.targetButton:SetHeight(20)

row.targetButton:RegisterForClicks("LeftButtonUp")

row.targetButton:SetScript("OnClick", function()

  DEFAULT_CHAT_FRAME:AddMessage("|cffbb55ffSoulwatch: clic target détecté.|r")

  local info = SW.data[row.lockName]

  if not info or not info.target or info.target == "" then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Soulwatch: aucune cible attribuée.|r")
    return
  end

  local bag, slot

  TargetByName(info.target, true)

  for bag = 0,4 do
    for slot = 1,GetContainerNumSlots(bag) do

      local link = GetContainerItemLink(bag, slot)

      if link then
        link = string.lower(link)

        if string.find(link, "soulstone")
or string.find(link, "pierre d'âme") then

          DEFAULT_CHAT_FRAME:AddMessage("|cff55ff55Soulwatch: pierre trouvée, utilisation.|r")

          UseContainerItem(bag, slot)

          SW:SetSoulstone(
  row.lockName,
  info.target,
  1800
)

          return
        end
      end
    end
  end

  DEFAULT_CHAT_FRAME:AddMessage("|cffff4444Soulwatch: aucune pierre d'âme trouvée.|r")
end)

  row.timer = row:CreateFontString(nil,"OVERLAY","GameFontNormal")
  row.timer:SetPoint("RIGHT", row, "RIGHT", -8, 0)

  row:SetScript("OnClick", function()
    if not row.lockName then return end

    if arg1 == "LeftButton" then
      TargetByName(row.lockName, true)

    elseif arg1 == "RightButton" then
      SW:OpenAssignMenu(row.lockName)

    elseif arg1 == "MiddleButton" then
      local info = SW.data[row.lockName]
      if not info then return end

      -- START TIMER
      if info.target and info.remaining <= 0 then
        SW:SetSoulstone(row.lockName, info.target, 1800)

      -- RESET TIMER ONLY, KEEP ASSIGN
      else
        info.remaining = 0
        info.expireTime = nil
        SW:SaveData()
        SW:UpdateRows()
        SW:SendState(row.lockName, info.target or "", 0)
      end
    end
  end)

  row:Hide()
  SW.rows[i] = row
end

local i
for i=1,10 do
  SW:CreateRow(i)
end

function SW:FormatTime(sec)
  if not sec or sec <= 0 then
    return "READY"
  end

  local m = math.floor(sec / 60)
  local s = math.floor(sec - (m*60))

  return string.format("%d:%02d", m, s)
end

function SW:AddWarlock(name)
  if not name then return end

  if not self.data[name] then
    SoulwatchDB.data[name] = {
      target = nil,
      remaining = 0,
      expireTime = nil,
      offline = nil
    }

    self.data = SoulwatchDB.data
    
  else
    self.data[name].offline = nil
  end
end

function SW:IsWarlock(unit)
  if not unit or not UnitExists(unit) then
    return nil
  end

  local _, class = UnitClass(unit)

  if class == "WARLOCK" or class == "Warlock" then
    return 1
  end

  return nil
end

function SW:GetColoredName(name)

  if not name or name == "" then
    return name
  end

  local class

  if GetNumRaidMembers and GetNumRaidMembers() > 0 then

    local i

    for i=1,GetNumRaidMembers() do

      local unit = "raid"..i

      if UnitName(unit) == name then
        _, class = UnitClass(unit)
        break
      end
    end

  else

    if UnitName("player") == name then
      _, class = UnitClass("player")
    end

    local i

    for i=1,GetNumPartyMembers() do

      local unit = "party"..i

      if UnitName(unit) == name then
        _, class = UnitClass(unit)
        break
      end
    end
  end

  if class and SW.classColors[class] then
    return SW.classColors[class]..name.."|r"
  end

  return name
end

function SW:ScanRaid()
  local active = {}
  local i
  local name
  local unit

  if GetNumRaidMembers and GetNumRaidMembers() > 0 then

    for i=1,GetNumRaidMembers() do
      unit = "raid"..i
      name = UnitName(unit)

      if name and self:IsWarlock(unit) then
        self:AddWarlock(name)

        if UnitIsConnected and UnitIsConnected(unit) then
          active[name] = 1
          self.data[name].offline = nil
        else
          active[name] = 1
          self.data[name].offline = true
        end
      end
    end

  else
    name = UnitName("player")

    if name and self:IsWarlock("player") then
      active[name] = 1
      self:AddWarlock(name)
      self.data[name].offline = nil
    end

    if GetNumPartyMembers then
      for i=1,GetNumPartyMembers() do
        unit = "party"..i
        name = UnitName(unit)

        if name and self:IsWarlock(unit) then
          self:AddWarlock(name)

          if UnitIsConnected and UnitIsConnected(unit) then
            active[name] = 1
            self.data[name].offline = nil
          else
            active[name] = 1
            self.data[name].offline = true
          end
        end
      end
    end
  end

  -- Keep tracked locks, but only mark offline if they are absent from current roster.
  local lock
  for lock in pairs(self.data) do

  if not active[lock] then

    -- remove unknown/left players
    self.data[lock] = nil

  end
end

  self:SaveData()
  self:UpdateRows()
end

function SW:SetSoulstone(lock, target, duration)
  if not lock then return end

  self:AddWarlock(lock)

  duration = duration or 1800

  self.data[lock].target = target
  self.data[lock].remaining = duration

  if duration > 0 then
    self.data[lock].expireTime = GetTime() + duration
  else
    self.data[lock].expireTime = nil
  end

  self:SaveData()
  self:UpdateRows()
  self:SendState(lock, target or "", duration)
end

function SW:SetAssignment(lock, target)
  if not lock then return end

  self:AddWarlock(lock)

  self.data[lock].target = target
  self.data[lock].remaining = 0
  self.data[lock].expireTime = nil

  self:SaveData()
  self:UpdateRows()
  self:SendState(lock, target or "", 0)
end

function SW:DetectSoulstone(msg)
  if not msg then return end

  local player = UnitName("player")
  local _, class = UnitClass("player")

  local _, _, target = string.find(msg, "You cast Soulstone Resurrection on (.+)%.")
  if target then
    self:SetSoulstone(player, target, 1800)
    return
  end

  local _, _, targetFr = string.find(msg, "Vous lancez Résurrection de Pierre d'âme sur (.+)%.")
  if targetFr then
    self:SetSoulstone(player, targetFr, 1800)
    return
  end

  local _, _, gainTarget =
  string.find(msg, "(.+) gagne Résurrection de Pierre d'âme%.")

if gainTarget then

  self:SetSoulstone(player, gainTarget, 1800)

  return
end
end

function SW:UpdateRows()
  local idx = 1
  local lock
  local info

  for lock, info in pairs(self.data) do
    local row = self.rows[idx]

    if row then
      row:Show()
      row.lockName = lock

      row.name:SetText("|cffbb55ff"..lock.."|r")

      if info.offline then
        row.target:SetText("|cff777777OFFLINE|r")
      else
        if info.target and info.target ~= "" then
          row.target:SetText(
  "-> "..SW:GetColoredName(info.target)
)
        else
          row.target:SetText("|cff66aaffREADY|r")
        end
      end

      row.timer:SetText(self:FormatTime(info.remaining))

      if info.offline then
        row:SetBackdropColor(0.15,0.15,0.15,0.9)

      elseif info.remaining and info.remaining > 0 then
        if info.remaining < 60 then
          row:SetBackdropColor(0.35,0.04,0.04,0.9)
        elseif info.remaining < 300 then
          row:SetBackdropColor(0.35,0.22,0.02,0.9)
        else
          row:SetBackdropColor(0.08,0.25,0.08,0.9)
        end

      else
        row:SetBackdropColor(0.08,0.08,0.22,0.9)
      end

      if not info.offline and SW.priority[info.target] then
        row:SetBackdropColor(0.45,0.08,0.45,0.95)
      end

      idx = idx + 1
    end
  end

  for i=idx,10 do
    self.rows[i]:Hide()
    self.rows[i].lockName = nil
  end

  local count = idx - 1
  local h = 70 + (count * 28)

  if h < 120 then
    h = 120
  end

  SW:SetHeight(h)
end

function SW:Tick()
  local lock
  local info
  local changed = nil

  for lock, info in pairs(self.data) do
    if info.expireTime then
      info.remaining = math.floor(info.expireTime - GetTime())

      if info.remaining == 120 and not info.warned120 then
        info.warned120 = true
        DEFAULT_CHAT_FRAME:AddMessage(
          "|cffff4444Soulwatch:|r "..lock.." SS expire bientôt !"
        )
      end

      if info.remaining <= 0 then
        info.remaining = 0
        info.expireTime = nil
        info.warned120 = nil
      end

      changed = 1
    end
  end

  if changed then
    self:SaveData()
    self:UpdateRows()
  end
end

SW:SetScript("OnUpdate", function()
  SW.elapsed = SW.elapsed + arg1

  if SW.elapsed >= 1 then

  SW.elapsed = 0

  SW:Tick()

  SW:ScanRaid()
end
end)

SW:SetScript("OnEvent", function()
  if event == "PLAYER_LOGIN" then
    if RegisterAddonMessagePrefix then
      RegisterAddonMessagePrefix("SOULWATCH")
    end

    SW.data = SoulwatchDB.data or {}
    SoulwatchDB.data = SW.data

    local lock
    local info

    for lock, info in pairs(SW.data) do
      if info.expireTime then
        info.remaining = math.floor(info.expireTime - GetTime())

        if info.remaining <= 0 then
          info.remaining = 0
          info.expireTime = nil
          info.warned120 = nil
        end
      else
        info.remaining = info.remaining or 0
      end
    end

    if SoulwatchDB.position then
      SW:ClearAllPoints()
      SW:SetPoint(
        SoulwatchDB.position.point,
        UIParent,
        SoulwatchDB.position.relativePoint,
        SoulwatchDB.position.x,
        SoulwatchDB.position.y
      )
    end

    SW:ScanRaid()
    SW:UpdateRows()

    DEFAULT_CHAT_FRAME:AddMessage("|cffbb55ffSoulwatch v4.1 loaded.|r")

  elseif event == "RAID_ROSTER_UPDATE"
      or event == "PARTY_MEMBERS_CHANGED" then
    SW:ScanRaid()

  elseif event == "CHAT_MSG_SPELL_SELF_BUFF" then
    SW:DetectSoulstone(arg1)

  elseif event == "CHAT_MSG_SPELL_FRIENDLYPLAYER_BUFF" then
    SW:DetectSoulstone(arg1)

  elseif event == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_BUFFS" then
    SW:DetectSoulstone(arg1)

  elseif event == "CHAT_MSG_ADDON" then
    if arg1 == "SOULWATCH" and arg2 then
      local _, _, lock, target, timer =
        string.find(arg2, "([^;]+);([^;]*);([^;]+)")

      if lock then
        timer = tonumber(timer) or 0

        SW:AddWarlock(lock)
        SW.data[lock].target = target
        SW.data[lock].remaining = timer

        if timer > 0 then
          SW.data[lock].expireTime = GetTime() + timer
        else
          SW.data[lock].expireTime = nil
          SW.data[lock].warned120 = nil
        end

        SW:SaveData()
        SW:UpdateRows()
      end
    end
  end
end)

function SW:OpenAssignMenu(lockName)
  if not lockName then return end

  local frame = SW.AssignFrame
  local x = SW:GetRight()

  frame:ClearAllPoints()

  if x and x > (GetScreenWidth() * 0.7) then
    frame:SetPoint("RIGHT", SW, "LEFT", -10, 0)
  else
    frame:SetPoint("LEFT", SW, "RIGHT", 10, 0)
  end

  local count = 0

for i=1,40 do

  local unit

  if GetNumRaidMembers and GetNumRaidMembers() > 0 then
    unit = "raid"..i
  else
    unit = "party"..i
  end

  if UnitName(unit) then
    count = count + 1
  end
end

local h = 60 + (count * 22)

if h < 120 then
  h = 120
end

if h > 320 then
  h = 320
end

frame:SetHeight(h)

frame:SetWidth(220)

  frame:Show()

  local i
  for i=1,40 do
    local button = SW.AssignButtons[i]

    if not button then
      button = CreateFrame("Button", nil, SW.AssignContent)
      button:SetWidth(150)
      button:SetHeight(20)

      if i == 1 then
        button:SetPoint(
  "TOPLEFT",
  SW.AssignContent,
  "TOPLEFT",
  0,
  0
)
      else
        button:SetPoint(
  "TOPLEFT",
  SW.AssignButtons[i-1],
  "BOTTOMLEFT",
  0,
  -2
)
      end

      button.text = button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall")
      button.text:SetAllPoints(button)
      button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")

      SW.AssignButtons[i] = button
    end

    local unit
    if GetNumRaidMembers and GetNumRaidMembers() > 0 then
      unit = "raid"..i
    else
      unit = "party"..i
    end

    local name = UnitName(unit)

    if name then
      button:Show()
      button.text:SetText(
  SW:GetColoredName(name)
)

      button:SetScript("OnClick", function()
        SW:SetAssignment(lockName, name)
        frame:Hide()
      end)
    else
      button:Hide()
    end
  end

  SW.AssignContent:SetHeight(count * 22)

end

SLASH_SOULWATCH1 = "/sw"

SlashCmdList["SOULWATCH"] = function(msg)
  if msg == "test" then
    SW:SetSoulstone("Nightyone", "MainTank", 1800)
    SW:SetSoulstone("Doomizer", "Shoupies", 420)
    return
  end

  if string.find(msg, "^me ") then
    local _, _, target = string.find(msg, "^me (.+)$")

    if target then
      SW:SetSoulstone(UnitName("player"), target, 1800)
    end
    return
  end

  if SW:IsShown() then
    SW:Hide()
  else
    SW:Show()
  end
end
