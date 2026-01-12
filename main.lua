local WidgetContainer = require("ui/widget/container/widgetcontainer")
local InputContainer = require("ui/widget/container/inputcontainer")
local UIManager = require("ui/uimanager")
local ProgressWidget = require("ui/widget/progresswidget")
local FrameContainer = require("ui/widget/container/framecontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local VerticalGroup = require("ui/widget/verticalgroup")
local TextWidget = require("ui/widget/textwidget")
local Math = require("optmath")
local _ = require("gettext")
local Blitbuffer = require("ffi/blitbuffer")
local Size = require("ui/size")
local Font = require("ui/font")
local Screen = require("device").screen
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local Device = require("device")
local Logger = require("logger")

local function sanitize(x)
    x = tonumber(x) or 0
    if x ~= x then return 0 end -- NaN check (NaN != NaN)
    if x < 0 then return 0 end
    if x > 1 then return 1 end
    return x
end

local BetterStats = WidgetContainer:extend{
    name = "betterstats",
    is_doc_only = true,
}

function BetterStats:init()
    self.ui.menu:registerToMainMenu(self)
end

function BetterStats:addToMainMenu(menu_items)
    menu_items.better_stats = {
        text = _("Better Stats"),
        keep_menu_open = true,
        callback = function()
            self:openBetterStats()
        end,
        enabled_func = function()
            return true
        end,
    }
end

local ProgressModalWidget = InputContainer:extend{
    name = "progressmodal",
    modal = true,
    book_progress = 0,
    chapter_progress = 0,
    error_message = nil,
    covers_fullscreen = true,
}

function ProgressModalWidget:init()
    self.ges_events = {}

    -- Tap gesture for touch devices
    if Device:isTouchDevice() then
        self.ges_events.Tap = {
            GestureRange:new{
                ges = "tap",
                range = Geom:new{
                    x = 0, y = 0,
                    w = Screen:getWidth(),
                    h = Screen:getHeight(),
                }
            }
        }
    end

    local face = Font:getFace("tfont") or Font:getFace("sans")

    -- Create VerticalGroup container
    local elements = VerticalGroup:new{
        align = "center"
    }

    -- Debug: log progress values
    Logger.info("progressmodal", "book_progress: " .. tostring(self.book_progress))
    Logger.info("progressmodal", "chapter_progress: " .. tostring(self.chapter_progress))

    -- Show error message or Book Progress text
    local bookText = self.error_message or ("Book Progress: " .. Math.round(self.book_progress * 100) .. "%")
    table.insert(elements, TextWidget:new{
        text = bookText,
        face = face,
    })

    -- Only show progress bars if there’s no error
    if not self.error_message then
        -- Ensure a minimum visual width for tiny percentages
        local function visiblePercentage(p)
            return math.max(p, 0.05) -- at least 5%
        end

        -- Book progress bar
        table.insert(elements, ProgressWidget:new{
            width = Screen:getWidth() * 0.6,
            height = Screen:scaleBySize(30),
            percentage = visiblePercentage(self.book_progress),
        })

        -- Chapter progress text
        table.insert(elements, TextWidget:new{
            text = "Chapter Progress: " .. Math.round(self.chapter_progress * 100) .. "%",
            face = face,
        })

        -- Chapter progress bar
        table.insert(elements, ProgressWidget:new{
            width = Screen:getWidth() * 0.6,
            height = Screen:scaleBySize(30),
            percentage = visiblePercentage(self.chapter_progress),
        })
    end

    -- Wrap elements in FrameContainer
    local widget = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = Size.border.window,
        padding = Size.padding.large,
        elements,
    }

    -- Center the modal
    self[1] = CenterContainer:new{
        dimen = Screen:getSize(),
        widget
    }

    self.dimen = Screen:getSize()
end


function ProgressModalWidget:onTap(_, _)
    UIManager:close(self)
    return true
end

function BetterStats:openBetterStats()
    Logger.info("betterstats", "invoked")

    -- Basic sanity: UI layer must exist
    if not self.ui or not self.ui.document then
        Logger.warn("betterstats", "no UI or no document")
        UIManager:show(ProgressModalWidget:new{
            error_message = _("No document loaded."),
        })
        return
    end

    local ok, book_progress, chapter_progress = pcall(function()
        local cp = self.ui.getCurrentPage and self.ui:getCurrentPage() or 0
        local tp = self.ui.document.getPageCount and self.ui.document:getPageCount() or 1
        if tp < 1 then tp = 1 end

        local toc = self.ui.toc
        local cpd = toc and toc.getChapterPagesDone and toc:getChapterPagesDone(cp) or 0
        local ctp = toc and toc.getChapterPageCount and toc:getChapterPageCount(cp) or tp
        if ctp < 1 then ctp = 1 end

        local cp_ratio, ch_ratio = cp/tp, cpd/ctp
        local sanitized_book_progress = sanitize(cp_ratio)
        local sanitized_chapter_progress  = sanitize(ch_ratio)

        return sanitized_book_progress, sanitized_chapter_progress
    end)

    if not ok then
        Logger.err("betterstats", "calculation failed: " .. tostring(book_progress))
        UIManager:show(ProgressModalWidget:new{
            error_message = _("Statistics unavailable for this document."),
        })
        return
    end

    UIManager:show(ProgressModalWidget:new{
        book_progress = book_progress,
        chapter_progress = chapter_progress,
    })
end

return BetterStats
