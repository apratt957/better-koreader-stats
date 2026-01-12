local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local Math = require("optmath")
local util = require("util") 
local _ = require("gettext")

local BetterStats = WidgetContainer:extend{  
    name = "betterstats",  
    is_doc_only = true
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
            return self.ui.statistics and self.ui.statistics:isEnabled()  
        end,  
    }
end

function BetterStats:openBetterStats()  
    -- Access the footer module  
    local footer = self.ui.footer  
      
    -- Get book progress (returns 0.0 to 1.0)  
    local book_progress = footer:getBookProgress()  
    local book_percentage = Math.round(book_progress * 100)  
      
    -- Get chapter progress (pass true for percentage)  
    local chapter_progress = footer:getChapterProgress(true)  
    local chapter_percentage = Math.round(chapter_progress * 100)  
     
    -- Get current page info for display  
    local current_page = footer.pageno  
    local total_pages = footer.pages  
      
    -- Create progress text  
    local progress_text = string.format(  
        _("Book Progress: %d%% (%d/%d pages)\nChapter Progress: %d%%"),  
        book_percentage, current_page, total_pages,  
        chapter_percentage  
    )  
      
    UIManager:show(InfoMessage:new{  
        text = progress_text,  
        timeout = 0,  
    })  
end

return BetterStats