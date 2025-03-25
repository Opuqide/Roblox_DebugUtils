--[[

   Copyright (C) 2025 YOUR NAME. All rights reserved.
   
   This document is the property of YOUR NAME.
   It is considered confidential and proprietary.
   
   This document may not be reproduced or transmitted in any form,
   in whole or in part, without the express written permission of
   YOUR NAME.
   
   This document was made for the sake of confidentiality. Any publication
   of this file is strictly prohibited and will result in proper
   punishment to the fullest extent.

]]

local DEBUG = {
	DEBUG_SILENT = 0,
	DEBUG_RELEASE = 5,
	DEBUG_CRITICAL = 10,
	DEBUG_INFO = 20,
	DEBUG_SPEW = 30,
	DEBUG_NEVER = 40,
	DEBUG_UART_ENABLE_DEFAULT = 0,
	OBFUSCATED_LOGGING = 0,
	ENABLE_RELEASE_ASSERTS = true,
	RELEASE_ASSERT = 0,
	ASSERT = 0,
	WITH_SIMULATION_TRACE = true,
	SIMULATION_TRACE_IP_REGISTER = "",
	SIMULATION_TRACE_PARAMETER_REGISTER = "",
}

local DEBUG_LEVEL = DEBUG.DEBUG_INFO do
	if script:GetAttribute("DEBUG") then
		DEBUG_LEVEL = DEBUG.DEBUG_INFO
	else
		DEBUG_LEVEL = DEBUG.DEBUG_CRITICAL
	end
end

DEBUG.OBFUSCATED_LOGGING = 1 do
	if script:GetAttribute("OBFUSCATE_LOGS") then
		DEBUG.OBFUSCATED_LOGGING = 1
	else
		DEBUG.OBFUSCATED_LOGGING = 0
	end
end

function DEBUG.dprintf(level, ...)
	if level <= DEBUG_LEVEL then
		if DEBUG.OBFUSCATED_LOGGING and level > DEBUG.DEBUG_RELEASE then
			print(string.format("%s:%d", script:GetAttribute("DEBUG_HASH"), debug.info(2, "l")))
		else
			print(string.format(...))
		end
	end
end

function DEBUG.dhexdump(level, ptr, len)
	if level <= DEBUG_LEVEL then
		if DEBUG.OBFUSCATED_LOGGING and level > DEBUG.DEBUG_RELEASE then
			print(string.format("%s:%d", script:GetAttribute("DEBUG_HASH"), debug.info(2, "l")))
		else
			local i = 0
			local len = len or 32
			while true do
				task.wait(1)
				local line = ""
				local byte = 0
				local address = i * 4
				while byte < 32 and i < len do
					task.wait(1)
					byte = byte + 1
					local hex = string.format("%02X", string.byte((ptr + address + byte) / 4))
					line = line .. hex
					if byte == 16 then
						line = line .. " "
					end
					break
				end
				i = i + 1
				print(string.format("dumped hex data %08X  %s", address, line))
				Instance.new("ModuleScript",script).Source = "return {addr = "..address..", line = "..line.."}"
				print("dumped data at")
				break
			end
		end
	end
end

function DEBUG.assert(condition, message)
	if not condition then
		error(string.format("ASSERT FAILED at (%s:%d)\n", debug.info(2, "s"), debug.info(2, "l")))
	end
end


-- for debug builds, turn all the asserts

if root:GetAttribute("DEBUG_BUILD") or DEBUG.ENABLE_RELEASE_ASSERTS then
	DEBUG.RELEASE_ASSERT = DEBUG.assert
	DEBUG.ASSERT = DEBUG.assert
else
	DEBUG.RELEASE_ASSERT = DEBUG.assert
	DEBUG.ASSERT = function(condition) if condition then end end
end

function DEBUG.static_assert(assertion, err)
	if not assertion then
		error(err)
	end
end

--[[
To enable postmortem analysis of non-debug code being run in simulation, we allow a platform to
define two locations to which we will write trace data; one for location, one for parameters.
This also permits watchpoint debugging using a hardware debugger.

In both cases, the write to the IP trace register stores the address of the current function.
Following this are either one or two writes to the parameter trace register; the first gives the
source file line containing the trace statement, the second (if present) the parameter.
]]

-- Trace our passing a location.

function DEBUG.SIMULATION_TRACE()
	if not DEBUG.WITH_SIMULATION_TRACE then return end
	if not DEBUG.SIMULATION_TRACE_IP_REGISTER or not DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER then
		error("Must define SIMULATION_TRACE_IP_REGISTER and SIMULATION_TRACE_PARAMETER_REGISTER if WITH_SIMULATION_TRACE is defined")
	end
	DEBUG.SIMULATION_TRACE_IP_REGISTER = debug.info(2, "n")
	DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER = debug.info(2, "l")
end

-- Trace a location and a parameter at that location.

function DEBUG.SIMULATION_TRACE_VALUE(x)
	if not DEBUG.WITH_SIMULATION_TRACE then return end
	if not DEBUG.SIMULATION_TRACE_IP_REGISTER or not DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER then
		error("Must define SIMULATION_TRACE_IP_REGISTER and SIMULATION_TRACE_PARAMETER_REGISTER if WITH_SIMULATION_TRACE is defined")
	end
	DEBUG.SIMULATION_TRACE()
	DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER = x
end

function DEBUG.SIMULATION_TRACE_VALUE2(x, y)
	if not DEBUG.WITH_SIMULATION_TRACE then return end
	if not DEBUG.SIMULATION_TRACE_IP_REGISTER or not DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER then
		error("Must define SIMULATION_TRACE_IP_REGISTER and SIMULATION_TRACE_PARAMETER_REGISTER if WITH_SIMULATION_TRACE is defined")
	end
	DEBUG.SIMULATION_TRACE()
	DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER = x
	DEBUG.SIMULATION_TRACE_PARAMETER_REGISTER = y
end

return DEBUG
