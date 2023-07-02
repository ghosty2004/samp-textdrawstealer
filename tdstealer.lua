script_name("Textdraw Stealer");
script_author("Ghosty2004");
script_version("1.0.0");

--[[ Modules ]]
local ev = require("samp.events");
local bit = require("bit");

--[[ Variables ]]
local TextdrawStealer = {
    cached = {},

    addToCache = function(self, textdraw)
        local customId = self:getCustomId(textdraw);
        if(self.cached[customId] == nil) then
            self.cached[customId] = textdraw;
        end
    end,

    getCustomId = function(self, textdraw)
        return self:stringToBytes(string.format("%s_%f_%f", textdraw.text, textdraw.position.x, textdraw.position.y));
    end,

    stringToBytes = function(self, str)
        local id = 0
        for i = 1, #str do
            id = id + string.byte(str, i) * i
        end
        return id
    end,

    decimalToRGBA = function(self, decimalColor)
        local rgb = ARGBToRGB(decimalColor);
        return string.format("0x%08X", bit.bor(bit.rshift(rgb, 24), bit.lshift(rgb, 8)));
    end,

    generateOutput = function(self)
        local output = string.format("new Text:ghosty2004_tdstealer[%d];", tablelength(self.cached));
        local count = 0;
        output = output .. string.format("\npublic OnFilterScriptInit()\n{", output);
        for k, v in pairs(self.cached) do
            output = output .. "\n";
            output = output .. string.format("\tghosty2004_tdstealer[%d] = TextDrawCreate(%f, %f, \"%s\");\n", count, v.position.x, v.position.y, v.text);
            output = output .. string.format("\tTextDrawFont(ghosty2004_tdstealer[%d], %d);\n", count, v.style);
            output = output .. string.format("\tTextDrawLetterSize(ghosty2004_tdstealer[%d], %f, %f);\n", count, v.letterWidth, v.letterHeight);
            output = output .. string.format("\tTextDrawAlignment(ghosty2004_tdstealer[%d], %d);\n", count, v.aligment);
            output = output .. string.format("\tTextDrawColor(ghosty2004_tdstealer[%d], %s);\n", count, self:decimalToRGBA(v.letterColor));
            output = output .. string.format("\tTextDrawSetProportional(ghosty2004_tdstealer[%d], %d);\n", count, v.proportional);
            
            if(v.box.enabled == 1) then
                output = output .. string.format("\tTextDrawUseBox(ghosty2004_tdstealer[%d], 1);\n", count);
                output = output .. string.format("\tTextDrawBoxColor(ghosty2004_tdstealer[%d], %s);\n", count, self:decimalToRGBA(v.box.color));
                output = output .. string.format("\tTextDrawTextSize(ghosty2004_tdstealer[%d], %f, %f);\n", count, v.box.sizeX, v.box.sizeY);
            else
                output = output .. string.format("\tTextDrawTextSize(ghosty2004_tdstealer[%d], %f, %f);\n", count, v.lineWidth, v.lineHeight);
            end

            output = output .. string.format("\tTextDrawSetShadow(ghosty2004_tdstealer[%d], %d);\n", count, v.shadow);
            output = output .. string.format("\tTextDrawSetOutline(ghosty2004_tdstealer[%d], %d);\n", count, v.outline);
            output = output .. string.format("\tTextDrawBackgroundColor(ghosty2004_tdstealer[%d], %s);\n", count, self:decimalToRGBA(v.backgroundColor));
            
            if(v.style == 5) then
                output = output .. string.format("\tTextDrawSetPreviewModel(ghosty2004_tdstealer[%d], %d);\n", count, v.modelId);
                output = output .. string.format("\tTextDrawSetPreviewRot(ghosty2004_tdstealer[%d], %f, %f, %f, %f);\n", count, v.rotation.x, v.rotation.y, v.rotation.z, v.zoom);
                output = output .. string.format("\tTextDrawSetPreviewVehCol(ghosty2004_tdstealer[%d], %d, %d);\n", count, v.color1, v.color2);
            end

            output = output .. string.format("\tTextDrawSetSelectable(ghosty2004_tdstealer[%d], %d);\n", count, v.selectable);
            count = count + 1;
        end
        output = output .. "}";
        return output;
    end
};

local tdstealer = TextdrawStealer;

--[[ Main ]]
function main()
    repeat wait(0) until isSampAvailable()
    SCM("Loaded.");

    sampRegisterChatCommand("tdstealer", function()
        local ip, port = sampGetCurrentServerAddress();
        createDirectory("ghosty2004_tdstealer");
        local file = io.open(string.format("ghosty2004_tdstealer\\%s_%d.txt", ip, port), "w");
        file:write(string.format("%s", tdstealer:generateOutput()));
        file:close();
        SCM("Saved.");
    end)
end

--[[ Events ]]
function ev.onShowTextDraw(textdrawId, textdraw)
    lua_thread.create(function()
        wait(0);
        local boxEnabled, boxColor, boxSizeX, boxSizeY = sampTextdrawGetBoxEnabledColorAndSize(textdrawId)
        textdraw.aligment = sampTextdrawGetAlign(textdrawId);
        textdraw.proportional = sampTextdrawGetProportional(textdrawId);
        textdraw.box = {
            enabled = boxEnabled,
            color = boxColor,
            sizeX = boxSizeX,
            sizeY = boxSizeY
        }
        SCM(string.format("Textdraw %d added to cache. (box: %d)", textdrawId, boxEnabled));
        tdstealer:addToCache(textdraw);
    end)
end

--[[ Functions ]]
function SCM(text)
    tag = "{FF5656}[Ghosty2004 Textdraw Stealer]: ";
    sampAddChatMessage(tag .. text, -1);
end

function explodeARGB(input)
    return 
        bit.band(bit.rshift(input, 24), 255),
        bit.band(bit.rshift(input, 16), 255),
        bit.band(bit.rshift(input, 8), 255),
        bit.band(input, 255)
end

function joinARGB(alpha, red, green, blue)
    local result = 0;
    result = bit.bor(result, bit.band(blue, 0xFF));
    result = bit.bor(result, bit.lshift(bit.band(green, 0xFF), 8));
    result = bit.bor(result, bit.lshift(bit.band(red, 0xFF), 16));
    result = bit.bor(result, bit.lshift(bit.band(alpha, 0xFF), 24));
    return result;
end


function ARGBToRGB(input)
    local alpha, red, green, blue = explodeARGB(input);
    return joinARGB(alpha, blue, green, red);
end

function tablelength(T)
    local count = 0;
    for _ in pairs(T) do count = count + 1 end;
    return count;
end
