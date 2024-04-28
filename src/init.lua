local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = game:GetService("Workspace").CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local Root = script
local Creator = require(Root.Creator)
local ElementsTable = require(Root.Elements)
local Acrylic = require(Root.Acrylic)
local Components = Root.Components
local NotificationModule = require(Components.Notification)

local New = Creator.New

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end
local GUI = New("ScreenGui", {
	Parent = RunService:IsStudio() and LocalPlayer.PlayerGui or game:GetService("CoreGui"),
})
ProtectGui(GUI)
NotificationModule:Init(GUI)

local RenderStepped = RunService.RenderStepped;


local Library = {
	Version = "1.1.0",

	OpenFrames = {},
	Options = {},
	Themes = require(Root.Themes).Names,

	Window = nil,
	WindowFrame = nil,
	Unloaded = false,

	Theme = "Dark",
	DialogOpen = false,
	UseAcrylic = false,
	Acrylic = false,
	Transparency = true,
	MinimizeKeybind = nil,
	MinimizeKey = Enum.KeyCode.LeftControl,

	GUI = GUI,

	button = nil,
	Cursor = nil,
	CursorOutline = nil,
	CursorState = nil,

	initFinished = false,
	
}

function Library:SafeCallback(Function, ...)
	if not Function then
		return
	end

	local Success, Event = pcall(Function, ...)
	if not Success then
		local _, i = Event:find(":%d+: ")

		if not i then
			return Library:Notify({
				Title = "Interface",
				Content = "Callback error",
				SubContent = Event,
				Duration = 5,
			})
		end

		return Library:Notify({
			Title = "Interface",
			Content = "Callback error",
			SubContent = Event:sub(i + 1),
			Duration = 5,
		})
	end
end

function Library:Round(Number, Factor)
	if Factor == 0 then
		return math.floor(Number)
	end
	Number = tostring(Number)
	return Number:find("%.") and tonumber(Number:sub(1, Number:find("%.") + Factor)) or Number
end

local Icons = require(Root.Icons).assets
function Library:GetIcon(Name)
	if Name ~= nil and Icons["lucide-" .. Name] then
		return Icons["lucide-" .. Name]
	end
	return nil
end

local Elements = {}
Elements.__index = Elements
Elements.__namecall = function(Table, Key, ...)
	return Elements[Key](...)
end

for _, ElementComponent in ipairs(ElementsTable) do
	Elements["Add" .. ElementComponent.__type] = function(self, Idx, Config)
		ElementComponent.Container = self.Container
		ElementComponent.Type = self.Type
		ElementComponent.ScrollFrame = self.ScrollFrame
		ElementComponent.Library = Library

		return ElementComponent:New(Idx, Config)
	end
end

Library.Elements = Elements

function Library:CreateWindow(Config)
	assert(Config.Title, "Window - Missing Title")

	if Library.Window then
		print("You cannot create more than one window.")
		return
	end

	Library.MinimizeKey = Config.MinimizeKey or Enum.KeyCode.LeftControl
	Library.UseAcrylic = Config.Acrylic or false
	Library.Acrylic = Config.Acrylic or false
	Library.Theme = Config.Theme or "Dark"
	if Config.Acrylic then
		Acrylic.init()
	end

	local Window = require(Components.Window)({
		Parent = GUI,
		Size = Config.Size,
		Title = Config.Title,
		SubTitle = Config.SubTitle,
		TabWidth = Config.TabWidth,
	})

	Library.Window = Window
	Library:SetTheme(Config.Theme)

	---this is our fix for getting a cursor to unlock :)
	Library.button = Instance.new("TextButton")
	Library.button.Position = UDim2.new(0, 0, 0, 0) -- Sets position to (1, 1)
	Library.button.Size = UDim2.new(0, 100, 0, 50) -- Sets size to 100x50
	Library.button.Text = ""
	Library.button.BackgroundTransparency = 1 -- Sets background transparency to 100% (fully transparent)
	Library.button.Visible = true -- Initial visibility is set based on buttonVisible variable
	Library.button.Modal = true -- Enables modal behavior
	Library.button.Parent = GUI -- Sets the button's parent to the ScreenGui

	
	print"im starting init"
		if not Library.Window.Minimized then
			task.spawn(function()
                -- TODO: add cursor fade?
                Library.CursorState = UserInputService.MouseIconEnabled

                Library.Cursor = Drawing.new('Triangle')
                Library.Cursor.Thickness = 1
                Library.Cursor.Filled = true
                Library.Cursor.Visible = true

                Library.CursorOutline = Drawing.new('Triangle')
                Library.CursorOutline.Thickness = 1
                Library.CursorOutline.Filled = false
                Library.CursorOutline.Color = Color3.new(0, 0, 0)
                Library.CursorOutline.Visible = true
				
                while not Library.Window.Minimized and not Library.initFinished  do
                    UserInputService.MouseIconEnabled = false

                    local mPos = UserInputService:GetMouseLocation()

                    Library.Cursor.Color = Color3.new(1, 1, 1)

                    Library.Cursor.PointA = Vector2.new(mPos.X, mPos.Y)
                    Library.Cursor.PointB = Vector2.new(mPos.X + 16, mPos.Y + 6)
                    Library.Cursor.PointC = Vector2.new(mPos.X + 6, mPos.Y + 16)

                    Library.CursorOutline.PointA = Library.Cursor.PointA
                    Library.CursorOutline.PointB = Library.Cursor.PointB
                    Library.CursorOutline.PointC = Library.Cursor.PointC

                    RenderStepped:Wait()
                end

               	UserInputService.MouseIconEnabled = Library.CursorState
				

                Library.Cursor:Remove()
                Library.CursorOutline:Remove()
            end)
		end

	return Window
end

function Library:ToggleModal(value)
	Library.button.Visible = value
    Library.button.Modal = value
end

function Library:SetTheme(Value)
	if Library.Window and table.find(Library.Themes, Value) then
		Library.Theme = Value
		Creator.UpdateTheme()
	end
end

function Library:Destroy()
	
	if Library.Window then
		Library.initFinished = true
		Library.Unloaded = true
		if Library.UseAcrylic then
			Library.Window.AcrylicPaint.Model:Destroy()
		end
		Creator.Disconnect()
		
		Library.GUI:Destroy()
		Library.button:Destroy()
	end
	
	Library:ToggleModal(false)
	
	Library.Cursor:Remove()
    Library.CursorOutline:Remove()
end

function Library:ToggleAcrylic(Value)
	if Library.Window then
		if Library.UseAcrylic then
			Library.Acrylic = Value
			Library.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
			if Value then
				Acrylic.Enable()
			else
				Acrylic.Disable()
			end
		end
	end
end

function Library:ToggleTransparency(Value)
	if Library.Window then
		Library.Window.AcrylicPaint.Frame.Background.BackgroundTransparency = Value and 0.35 or 0
	end
end

function Library:Notify(Config)
	return NotificationModule:New(Config)
end

if getgenv then
	getgenv().Fluent = Library
end

return Library
