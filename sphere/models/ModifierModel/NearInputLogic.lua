local Modifier = require("sphere.models.ModifierModel.Modifier")

local NearInputLogic = Modifier:new()

NearInputLogic.type = "LogicEngineModifier"
NearInputLogic.interfaceType = "toggle"

NearInputLogic.defaultValue = true
NearInputLogic.name = "NearInputLogic"
NearInputLogic.shortName = "NIL"

NearInputLogic.getString = function(self, config)
	if not config.value then
		return
	end
	return Modifier.getString(self)
end

NearInputLogic.apply = function(self, config)
	if not config.value then
		return
	end

	self.rhythmModel.logicEngine.nearest = true
end

NearInputLogic.receive = function(self, config, event)
	if config.value == 0 then
		return
	end

	if event.name ~= "keypressed" then
		if event.name ~= "keyreleased" then 
			return
		end
	end

	local noteHandlers = self.rhythmModel.logicEngine.noteHandlers
	local currentTime = self.rhythmModel.timeEngine.currentTime
	local key = event[1]

	for _, noteHandler in pairs(noteHandlers) do
		if key == noteHandler.keyBind then
			self:getLatestAccessibleNote(noteHandler)
			local nearestNote = self:getNearestNote(noteHandler, currentTime)
			local lastNote = noteHandler.lastNote

			if not nearestNote then return end

			if lastNote.noteClass == "LongLogicalNote" then
				if lastNote:getNoteTime("end") > currentTime then
					nearestNote = lastNote
				else
					lastNote:receive(event)
				end
			end

			noteHandler.lastNote = nearestNote
			nearestNote:receive(event)
			break
		end
	end
end

NearInputLogic.getNearestNote = function(self, noteHandler, currentTime)
	local earlyNote
	local lateNote
	local startIndex = noteHandler.latestAccessibleNote.index

	for i = startIndex, noteHandler.noteCount, 1 do -- search for an early note
		local note = noteHandler.noteData[i]
		if note:getNoteTime() > currentTime and note.ended == false then
			earlyNote = note
			break
		end
	end

	for i = startIndex, noteHandler.noteCount, 1 do -- search for a late note
		local note = noteHandler.noteData[i]

		if note:getNoteTime() < currentTime and note.ended == false then
			lateNote = note
		else
			break
		end

		if not lateNote then break end
	end

	if earlyNote ~= nil and lateNote ~= nil then -- notes between currentTime
		if earlyNote:getNoteTime() - currentTime < currentTime - lateNote:getNoteTime() then
			return earlyNote -- earlyNote is closer
		else
			return lateNote -- lateNote is closer
		end
	end

	if lateNote ~= nil then -- End of the chart, no notes between currentTime
		return lateNote
	end

	if earlyNote ~= nil then -- Start of the chart, no notes between currentTime
		return earlyNote
	end
end

NearInputLogic.getLatestAccessibleNote = function(self, noteHandler)
	for i = noteHandler.latestAccessibleNote.index, noteHandler.noteCount, 1 do
		if noteHandler.noteData[i].ended == false then
			noteHandler.latestAccessibleNote = noteHandler.noteData[i]
			return
		end
	end
end

return NearInputLogic