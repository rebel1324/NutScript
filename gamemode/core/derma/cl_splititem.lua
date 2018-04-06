do  
    surface.CreateFont("nutSplitChar", {
        font = "Impact",
        extended = true,
        size = 30,
        weight = 100,
        antialias = true,
    })

    local PANEL = {}
    local SIZE_WIDTH, SIZE_HEIGHT = 300, 155

    function PANEL:Init()
        self:SetSize(SIZE_WIDTH, SIZE_HEIGHT)
        self:MakePopup()
        self:Center()
        self:SetTitle(L"split")
        
        self.input = self:Add("DPanel")
        self.input:Dock(FILL)
        self.input.Paint = function() end
    end

    function PANEL:setItem(item)
        if (!item) then self:Close() return end
        
        self.item = item

        do 
            self.set = self.input:Add("DPanel")
            self.set:Dock(FILL)
            self.set:SetContentAlignment(5)
            self.set:DockMargin(10, 0, 10, 0)
            self.set.Paint = function() end


            self.label = self.input:Add("DLabel")
            self.label:SetText(L"splitHelp")
            self.label:SetFont("nutSmallFont")
            self.label:Dock(TOP)
            self.label:DockMargin(10, 5, 10, 0)
            self.label.Paint = function() end

            local maxQuantity = tostring(self.item:getQuantity())
            surface.SetFont("nutSplitChar")
            local tx, ty = surface.GetTextSize(maxQuantity)
            local tx2 = surface.GetTextSize("/")
            local tx3 = surface.GetTextSize("0")

            self.set2 = self.set:Add("DPanel")
            self.set2:SetWide(tx*2 + tx2*4)
            self.set2.Paint = function() end
            self.set2:SetPos((SIZE_WIDTH-24)/2 - (tx*2 + tx2*4)/2, ty/2)

            self.amount = self.set2:Add("DTextEntry")
            self.amount:Dock(LEFT)
            self.amount:SetDrawBorder(false)
            self.amount:SetPaintBackground(false)
            self.amount:SetNumeric(true)
            self.amount:SetAllowNonAsciiCharacters(false)
            self.amount:SetFont("nutSplitChar")
            self.amount:SetTextColor(color_white)
            self.amount:SetPlaceholderText("0")
            self.amount:SetWide(tx + tx3)
            self.amount:SetContentAlignment(4)
            self.amount:CenterHorizontal()
            function self.amount:AllowInput(strValue)
                local str = self:GetText()
                if (str:len() == maxQuantity:len()) then return true end
                if (self:CheckNumeric(strValue)) then return true end
            end
            self.amount.OnEnter = function()
                self:doSplit(self.amount:GetText())
            end


            self.maxLabel = self.set2:Add("DLabel")
            self.maxLabel:SetText(maxQuantity)
            self.maxLabel:Dock(RIGHT)
            self.maxLabel:SetWide(tx + tx3)
            self.maxLabel:SetFont("nutSplitChar")
            self.maxLabel:SetContentAlignment(4)

            self.splitLabel = self.set2:Add("DLabel")
            self.splitLabel:SetText(L"/")
            self.splitLabel:Dock(FILL)
            self.splitLabel:SetFont("nutSplitChar")
            self.splitLabel:SetContentAlignment(4)
        end

        self.fast = self:Add("DPanel")
        self.fast:Dock(BOTTOM)
        self.fast:DockMargin(0, 5, 0, 5)
        self.fast:SetTall(35)
        self.fast.Paint = function() end

        do
            self.split = self.fast:Add("DButton")
            self.split:Dock(RIGHT)
            self.split:DockMargin(5, 0, 0, 0)
            self.split:SetText(L"split")
            self.split.DoClick = function()
                self:doSplit(self.amount:GetText())
            end

            self.half = self.fast:Add("DButton")
            self.half:Dock(RIGHT)
            self.half:DockMargin(5, 0, 0, 0)
            self.half:SetText(L"splitHalf")
            self.half.DoClick = function()
                self:doSplit(self.item:getQuantity()/2)
            end

            self.quarter = self.fast:Add("DButton")
            self.quarter:Dock(RIGHT)
            self.quarter:DockMargin(5, 0, 0, 0)
            self.quarter:SetText(L"splitQuarter")
            self.quarter.DoClick = function()
                self:doSplit(self.item:getQuantity()/4)
            end
        end
    end

    function PANEL:noticeMe()
        self.amount:RequestFocus()
    end

    function PANEL:doSplit(amount)
        amount = tonumber(amount)

        if (amount) then
            amount = math.Round(amount)
            local item = self.item

            if (item:getQuantity() == amount or item:getQuantity() <= amount or item:getMaxQuantity() < amount) then
                nut.util.notifyLocalized("invalid", "amount")

                self:Close()
                return
            end
                            
            netstream.Start("invSplit", item:getID(), amount, item.invID)   
            self:Close()
        else
            nut.util.notifyLocalized("invalid", "amount")
            self:Close()
        end
    end

    vgui.Register("nutItemSplit", PANEL, "DFrame")
end