if (game:IsLoaded() or game.Loaded:Wait()) then end

local Library = {
	running = true
}

local Colors = {
	SidebarSelected = Color3.fromRGB(249, 183, 255)
}

local LookingFor = { "Players", "ReplicatedFirst", "ReplicatedStorage", "Lighting", "CoreGui" }
while (not select(1, pcall(function()
		for _, name in next, LookingFor do
			if (not game:FindService(name)) then return false end
		end

		return true
	end))) do task.wait() end

local UIS = game:GetService('UserInputService')
local RunService = game:GetService('RunService')
local Players = game:GetService('Players')
local CoreGui = game:GetService('CoreGui')
local TweenService = game:GetService('TweenService')
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
CoreGui = (RunService:IsStudio() and LocalPlayer.PlayerGui) or gethui and gethui() or CoreGui

local platform = Enum.Platform.Windows
pcall(function()
	platform = UIS:GetPlatform()
end)
local IsMobile = platform == Enum.Platform.IOS or platform == Enum.Platform.Android

-- CONNECTIONS HANDLER

local _connections = {}
local Connections = {}

function Connections:Add(connection: RBXScriptConnection)
	assert(typeof(connection) == 'RBXScriptConnection', `connection is not 'RBXScriptConnection', got '{typeof(connection)}'`);

	table.insert(_connections, connection)
end

function Connections:Disconnect()
	for _, connection in next, _connections do
		connection:Disconnect()
	end
end

-- // UI LIBRARY FUNCTIONS // --

local function Create(class: ServiceProvider, props)
	local instance = Instance.new(class)

	props.BorderSizePixel = 0
	props.AutoButtonColor = false
	props.Font = Enum.Font.SourceSans
	props.FontFace = props.Font

	for key, value in next, props or {} do
		pcall(function()
			instance[key] = value
		end)
	end

	return instance
end

local function Tween(instance, seconds, goal)
	local tween = TweenService:Create(
		instance,
		TweenInfo.new(seconds, Enum.EasingStyle.Linear),
		goal
	)

	tween:Play()

	return tween
end

-- // UI LIBRARY MAIN // --

while true do
	local UI = CoreGui:FindFirstChild('Kittenware')

	if not UI then
		break
	end

	UI:Destroy()
end

local ScreenGui = Create('ScreenGui', {
	Name = 'Kittenware',
	Parent = CoreGui
})

ScreenGui:GetPropertyChangedSignal('Parent'):Once(function()
	if script.Parent ~= CoreGui then
		Library.running = false
		Connections:Disconnect()
	end
end)

task.spawn(function()
	while true do
		ScreenGui:GetPropertyChangedSignal('Parent'):Wait()

		if (ScreenGui.Parent ~= CoreGui) then
			Library.running = false
			Connections:Disconnect()
			break
		end
	end
end)

function Library:Create()
	local Window = Create('Frame', {
		Active = true,
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(.5, .5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = .2,

		Size = IsMobile and UDim2.new(0, 600, 0, 400) or UDim2.new(0, 800, 0, 600),
		Position = UDim2.new(.5, 0, .5, 0)
	});

	local MobileButton = Create('TextButton', {
		Active = true,
		Parent = ScreenGui,
		AnchorPoint = Vector2.new(1, .5),
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		BackgroundTransparency = .2,

		Size = UDim2.new(0, 60, 0, 60),
		Position = UDim2.new(.9, 0, .5, 0),
		Rotation = 0,
		Text = '',
		ZIndex = 999
	})

	-- Stylize button
	do
		local UIStroke = Create('UIStroke', {
			Parent = MobileButton,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Color3.new(1,1,1),
			Thickness = 5,
			Transparency = 0.5,
		})

		local UIGradient = Create('UIGradient', {
			Parent = UIStroke,

			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
				ColorSequenceKeypoint.new(.25, Colors.SidebarSelected),
				ColorSequenceKeypoint.new(1, Colors.SidebarSelected),
			}),

			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(.75, 1),
				NumberSequenceKeypoint.new(1, 1),
			})
		})

		Create('UICorner', {
			Parent = MobileButton,
			CornerRadius = UDim.new(0, 50)
		})

		Connections:Add(MobileButton.MouseButton1Click:Connect(function()
			Window.Visible = not Window.Visible
		end))

		task.spawn(function()
			while Library.running do
				Tween(MobileButton, 2, {
					Rotation = 360
				}).Completed:Wait()

				MobileButton.Rotation = 0
			end
		end)
	end


	local DragBar = Create('Frame', {
		Active = true,
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.fromRGB(30, 30, 30),
		Parent = Window,
		Size = UDim2.new(1, 0, 0, 30),
		-- BackgroundTransparency = 1,
	})

	do
		local AbsolutePosition = Window.AbsolutePosition
		Window.AnchorPoint = Vector2.new()
		Window.Position = UDim2.new(0, AbsolutePosition.X, 0, AbsolutePosition.Y)

		local AbsolutePosition = MobileButton.AbsolutePosition
		MobileButton.AnchorPoint = Vector2.new()
		MobileButton.Position = UDim2.new(0, AbsolutePosition.X, 0, AbsolutePosition.Y)
	end

	Create('UICorner', {
		Parent = Window,
		CornerRadius = UDim.new(0, 10)
	}):Clone().Parent = DragBar

	-- Non-important stuff
	do
		-- Drag
		do
			local camera = workspace.CurrentCamera
			local dragging = false

			local function get_bounds (instance, v2)
				local absolute_size = instance.AbsoluteSize

				local left_bounds = (camera.ViewportSize.Y - absolute_size.Y)
				local right_bounds = (camera.ViewportSize.X - absolute_size.X)

				local x = v2.X
				local y = v2.Y

				return ((right_bounds < x and right_bounds) or (x <= 0 and 0) or x),
				((left_bounds < y and left_bounds) or (y <= 0 and 0) or y)
			end

			Connections:Add(DragBar.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					local mpos =  Vector2.new(input.Position.X, input.Position.Y)

					dragging = true
					local pos = Window.AbsolutePosition

					local lastpos = nil
					while Library.running and dragging do
						local currpos = Vector2.new(Mouse.X, Mouse.Y)
						local delta = currpos - mpos

						if lastpos == nil or (currpos.X ~= lastpos.X or currpos.Y ~= lastpos.Y) then
							local x, y = get_bounds(Window, Vector2.new(pos.X + delta.X, pos.Y + delta.Y))
							lastpos = currpos
							Tween(Window, .05, {
								Position = UDim2.new(
									0,
									x,
									0,
									y
								)
							})
						end
						task.wait()
					end
				end
			end))

			Connections:Add(DragBar.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.Focus or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
				then
					dragging = false
				end
			end))

			local bdragging = false
			Connections:Add(MobileButton.InputBegan:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
					local mpos =  Vector2.new(input.Position.X, input.Position.Y)

					bdragging = true
					local pos = MobileButton.AbsolutePosition

					local lastpos = nil
					while Library.running and bdragging do
						local currpos = Vector2.new(Mouse.X, Mouse.Y)
						local delta = currpos - mpos

						if lastpos == nil or (currpos.X ~= lastpos.X or currpos.Y ~= lastpos.Y) then
							local x, y = get_bounds(MobileButton, Vector2.new(pos.X + delta.X, pos.Y + delta.Y))
							lastpos = currpos
							Tween(MobileButton, .05, {
								Position = UDim2.new(
									0,
									x,
									0,
									y
								)
							})
						end
						task.wait()
					end
				end
			end))

			Connections:Add(MobileButton.InputEnded:Connect(function(input)
				if (input.UserInputType == Enum.UserInputType.Focus or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
				then
					bdragging = false
				end
			end))

			task.spawn(function()
				while (true) do
					workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Wait()
					local size = workspace.CurrentCamera.ViewportSize
					if (not Library.running) then return end
					local absolute_position = (size - Window.AbsolutePosition) - Window.AbsoluteSize
					local x, y = get_bounds(Window, Window.AbsolutePosition)
					if (x ~= 0 or y ~= 0) then
						Window.Position = UDim2.new(0, x or absolute_position.X, 0, y or absolute_position.Y)
					end

					local absolute_position = (size - MobileButton.AbsolutePosition) - MobileButton.AbsoluteSize
					local x, y = get_bounds(MobileButton, MobileButton.AbsolutePosition)
					if (x ~= 0 or y ~= 0) then
						MobileButton.Position = UDim2.new(0, x or absolute_position.X, 0, y or absolute_position.Y)
					end
				end
			end)
		end

		-- Labels
		do
			-- Title
			Create('TextLabel', {
				BackgroundTransparency = 1,
				Parent = Window,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(0, 100, 0, 25),

				Font = Enum.Font.RobotoMono,

				Text = 'Kittenware',
				TextColor3 = Color3.new(1,1,1),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Left

			}).Font = Enum.Font.RobotoMono

			local name = ((getexecutorname or identifyexecutor or function() return 'Unknown' end))()
			Create('TextLabel', {
				BackgroundTransparency = 1,
				Parent = Window,
				Position = UDim2.new(0, 75, 0, 10),
				Size = UDim2.new(0, 80, 0, 25),

				Font = Enum.Font.RobotoMono,

				Text = name,
				TextColor3 = Color3.new(1,1,1),
				TextSize = 14,
				TextXAlignment = Enum.TextXAlignment.Right
			}).Font = Enum.Font.RobotoMono
		end
	end

	-- Pages
	local Sidebar: ScrollingFrame = Create('ScrollingFrame', {
		Active = true,
		Parent = Window,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 0,

		Size = UDim2.new(0, 150, 0, Window.AbsoluteSize.Y - 40),
		Position = UDim2.new(0, 5, 0, 35),
	})

	-- dividers
	do
		Create('Frame', {
			Parent = Window,
			BackgroundTransparency = .95,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.new(0, 2, 1, -32),
			Position = UDim2.new(0, Sidebar.AbsoluteSize.X + 13, 0, 32)
		})

		Create('Frame', {
			Parent = Window,
			BackgroundTransparency = .95,
			BackgroundColor3 = Color3.fromRGB(255, 255, 255),
			Size = UDim2.new(1, 0, 0, 2),
			Position = UDim2.new(0, 0, 0, 30)
		})
	end

	local UIListLayout = Create('UIListLayout', {
		Parent = Sidebar,

		Padding = UDim.new(0, 5),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	Connections:Add(UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
		local AbsoluteContentSize = UIListLayout.AbsoluteContentSize

		Sidebar.CanvasSize = UDim2.new(0, AbsoluteContentSize.X, 0, AbsoluteContentSize.Y)
	end))

	local AbsoluteContentSize = UIListLayout.AbsoluteContentSize

	Sidebar.CanvasSize = UDim2.new(0, AbsoluteContentSize.X, 0, AbsoluteContentSize.Y)

	local module = {}
	local pages = {}
	function module:AddPage(name)
		local btn: TextButton = Create('TextButton', {
			AutoButtonColor = false,
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(60, 60, 60),

			Name = name,
			Size = UDim2.new(1, 0, 0, 30),
			Text = '',

			Parent = Sidebar,
		})

		local page: ScrollingFrame = Create('ScrollingFrame', {
			Active = true,
			BackgroundTransparency = .5,
			ClipsDescendants = true,
			BackgroundColor3 = Color3.fromRGB(30, 30, 30),
			BorderSizePixel = 0,

			Parent = Window,
			Size = UDim2.new(1, -175, 0, Window.AbsoluteSize.Y - 40),
			Position = UDim2.new(0, 170, 0, 35),

			ScrollBarThickness = 0,
			ScrollingDirection = Enum.ScrollingDirection.Y,

			Visible = false
		})

		Create('UIGridLayout', {
			Parent = page,

			CellPadding = UDim2.new(0,0,0,0),
			CellSize = UDim2.new(.5, 0, 1, 0),
			Padding = UDim.new(0, 0),
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			-- Wraps = true,
			HorizontalAlignment = Enum.HorizontalAlignment.Left, -- Start from left to right
			-- HorizontalFlex = Enum.UIFlexAlignment.SpaceBetween, -- BETA FEATURE
			-- ItemLineAlignment = Enum.ItemLineAlignment.Start, -- BETA FEATURE
			VerticalAlignment = Enum.VerticalAlignment.Top, -- Start from top to bottom
			-- VerticalFlex = Enum.UIFlexAlignment.None, -- BETA FEATURE
		})

		local lcolumn = Create('Frame', {
			Parent = page,

			Size = UDim2.new(.5, 0, 0, 50),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		})

		local rcolumn = Create('Frame', {
			Parent = page,

			Size = UDim2.new(.5, 0, 0, 0),
			BackgroundTransparency = 1,
			BackgroundColor3 = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255))
		})

		local function getcolumn()
			return #lcolumn:GetChildren() == #rcolumn:GetChildren() and lcolumn or rcolumn
		end

		-- LAYOUTS TO PUT COMPONENTS IN
		do
			local llayout: UIListLayout = Create('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left, -- Start from left to right
				VerticalAlignment = Enum.VerticalAlignment.Top, -- Start from top to bottom

				Padding = UDim.new(0, 5),
				Parent = lcolumn
			})

			local rlayout: UIListLayout = Create('UIListLayout', {
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Left, -- Start from left to right
				VerticalAlignment = Enum.VerticalAlignment.Top, -- Start from top to bottom

				Padding = UDim.new(0, 5),
				Parent = rcolumn
			})


			for _, layout : UIListLayout in next, { llayout, rlayout } do
				local olayout = layout ~= llayout and llayout or rlayout
				Connections:Add(layout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
					if (layout.AbsoluteContentSize.Y >= olayout.AbsoluteContentSize.Y) then
						page.CanvasSize = UDim2.new(0, page.AbsoluteSize.X + 5, 0, layout.AbsoluteContentSize.Y)
						return
					end

					page.CanvasSize = UDim2.new(0, page.AbsoluteSize.X + 5, 0, olayout.AbsoluteContentSize.Y)
				end))
			end

		end

		pages[btn] = page

		local Label = Create('TextLabel', {
			BackgroundTransparency = 1,
			Parent = btn,

			Font = Enum.Font.RobotoMono,
			ClipsDescendants = true,

			Text = name,
			TextSize = 18,
			Size = UDim2.new(1, -20, 1, 0),
			Position = UDim2.new(0, 10, 0, 0),

			TextColor3 = Color3.new(.6, .6, .6),
			TextXAlignment = Enum.TextXAlignment.Left
		})

		local Bar = Create('Frame', {
			BackgroundTransparency = .5,
			Parent = btn,
			Size = UDim2.new(0, 5, 1, 0),
			Position = UDim2.new(1, -5, 0, 0),

			BackgroundColor3 = Colors.SidebarSelected,
			Visible = false
		})

		local selected = Create('BoolValue', {
			Name = 'Selected',
			Value = false,
			Parent = btn,
		})

		Connections:Add(selected:GetPropertyChangedSignal('Value'):Connect(function()
			Bar.Visible = selected.Value
			page.Visible = selected.Value

			if selected.Value then
				Tween(btn, .2, {
					BackgroundTransparency = .5
				})
				Tween(Label, .2, {
					TextColor3 = Color3.new(1, 1, 1)
				})
			end
		end))

		Connections:Add(btn.MouseButton1Click:Connect(function()
			for _, _btn in next, Sidebar:GetChildren() do
				if (_btn:IsA('TextButton') and _btn ~= btn) then
					local selected = _btn:WaitForChild('Selected')

					if selected.Value then
						Tween(_btn, .2, {
							BackgroundTransparency = 1
						})

						Tween(_btn.TextLabel, .2, {
							TextColor3 = Color3.new(.6, .6, .6)
						})
					end

					pages[_btn].Visible = false
					selected.Value = false
				end
			end

			selected.Value = true
		end))

		Connections:Add(btn.MouseEnter:Connect(function()
			if selected.Value then return end
			Tween(btn, .2, {
				BackgroundTransparency = .5
			})
			Tween(Label, .2, {
				TextColor3 = Color3.new(1, 1, 1)
			})
		end))

		Connections:Add(btn.MouseLeave:Connect(function()
			if selected.Value then return end
			Tween(btn, .2, {
				BackgroundTransparency = 1
			})
			Tween(Label, .2, {
				TextColor3 = Color3.new(.6, .6, .6)
			})
		end))

		selected.Value = #Sidebar:GetChildren() == 2

		-- COMPONENTS

		local function create_components(page: Frame, is_sub: boolean)
			local modules = {}
			local y = 0

			local function create_container()
				local container: Frame = Create('Frame', {
					Active = true,
					BorderSizePixel = 0,
					BackgroundTransparency = .9,
					BackgroundColor3 = Color3.fromRGB(255, 255, 255),
					ClipsDescendants = true,
					Size = UDim2.new(1, -5, 0, 80),
					Parent = is_sub and page or getcolumn()
				})

				Create('UICorner', {
					Parent = container,
					CornerRadius = UDim.new(0, 5)
				})

				return container
			end

			local function create_label(text, parent)
				return Create('TextLabel', {
					AnchorPoint = Vector2.new(.5, 0),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Parent = parent,

					Font = Enum.Font.Fantasy,
					Position = UDim2.new(.5, 0, 0, 0),
					Size = UDim2.new(1, -50, 1, 0),
					Text = text,
					TextColor3 = Color3.fromRGB(180, 180, 180),
					TextSize = 18,

					TextXAlignment = Enum.TextXAlignment.Center
				})
			end

			local function create_button(name, parent)
				local btn : TextButton = Create('TextButton', {
					AutoButtonColor = false,
					BackgroundColor3 = Color3.fromRGB(0),
					BackgroundTransparency = .5,
					Parent = parent,

					Size = UDim2.new(1, -20, 0, 30),
					Position = UDim2.new(0, 10, 0, 10),

					Text = ''
				})

				Connections:Add(btn.MouseEnter:Connect(function()
					Tween(btn, .25, {
						BackgroundTransparency = .25
					})
				end))

				Connections:Add(btn.MouseLeave:Connect(function()
					Tween(btn, .25, {
						BackgroundTransparency = .5
					})
				end))

				Create('UICorner', {
					CornerRadius = UDim.new(0, 5),
					Parent = btn
				})

				create_label(name, btn)

				return btn
			end

			function modules:AddLabel(text: string) : (newLabel: string) -> ()
				local container = create_container()
				container.Size = UDim2.new(1, -5, 0, 50)
				local Label = create_label(text, container);

				return function(newLabel: string)
					Label.Text = `{newLabel}`
				end
			end

			function modules:AddButton(name: string, description: string?, f: () -> ())
				local container = create_container()

				local btn: TextButton = create_button(name, container)
				Connections:Add(btn.MouseButton1Click:Connect(function()
					if typeof(f) == 'function' then
						f()
					end
				end))

				container.Size = UDim2.new(1, -5, 0, typeof(description) == 'string' and description:len() > 0 and 75 or 50)

				if container.Size.Y.Offset == 75 then
					local text = create_label(description, container)

					text.TextWrapped = true
					text.AnchorPoint = Vector2.new()
					text.BackgroundTransparency = 1
					text.TextSize = 16
					text.Size = UDim2.new(1, -30, 0, 35)
					text.Position = UDim2.new(0, 15, 0, 40)
					text.TextYAlignment = Enum.TextYAlignment.Top
					text.TextXAlignment = Enum.TextXAlignment.Left
				end

				y += container.AbsoluteSize.Y
				-- create_label
			end

			function modules:AddToggle(name: string, toggle: boolean?, f: (isToggled: boolean) -> ()) : (newToggle: boolean) -> ()
				local container = create_container()
				container.Size = UDim2.new(1, -5, 0, 35)

				local label : TextLabel = Create('TextLabel', {
					AnchorPoint = Vector2.new(.5, .5),
					BackgroundTransparency = 1,
					
					Font = Enum.Font.Fantasy,
					Text = `{name}`,
					TextColor3 = Color3.fromRGB(180, 180, 180),
					TextSize = 18,
					
					Position = UDim2.new(.3, 0, .5, 0),
					Size = UDim2.new(.5, 0, 0, 25),

					Parent = container,

					TextXAlignment = Enum.TextXAlignment.Left
				})

				local box : Frame = Create('Frame', {
					AnchorPoint = Vector2.new(1, .5),
					BackgroundColor3 = Color3.new(.1,.1,.1),
					BackgroundTransparency = .5,
					ClipsDescendants = true,

					Size = UDim2.new(0, 40, 0, 20),
					Position = UDim2.new(.95, 0, .5, 0),

					Parent = container
				})
				
				
				Create('UICorner', {
					CornerRadius = UDim.new(1),
					Parent = box
				})
				
				local innerbox = box:Clone()
				innerbox.AnchorPoint = Vector2.new(0, .5)
				innerbox.ClipsDescendants = false
				innerbox.BackgroundTransparency = 1
				innerbox.Parent = box
				innerbox.BackgroundColor3 = Color3.new(1,1,1)
				innerbox.Position = UDim2.new(0, 5, .5, 0)
				innerbox.Size = UDim2.new(1, -10, .5, 0)
				
				local pointer = Create('Frame', {
					AnchorPoint = Vector2.new(0, .5),
					BackgroundColor3 = Color3.new(1, 1, 1),

					Size = UDim2.new(0, 10, 0, 10),
					Position = UDim2.new(0, 0, .5, 0),
					Parent = innerbox,
					ZIndex = 2,
					Visible = true
				})

				Create('UICorner', {
					CornerRadius = UDim.new(1, 0),
					Parent = pointer
				})

				local progress = pointer:Clone()
				progress.AnchorPoint = Vector2.new(0, .5)
				-- progress.BackgroundColor3 = Colors.SidebarSelected
				-- progress.BackgroundTransparency = .8
				progress.Parent = innerbox
				progress.ZIndex = 1
				progress.Position = UDim2.new(0, 0, .5, 0)
				progress.Size = UDim2.new(0, 0, .5, 0)

				Create('UIGradient', {
					Enabled = true,
					Color = ColorSequence.new{
						ColorSequenceKeypoint.new(0, Colors.SidebarSelected),
						ColorSequenceKeypoint.new(1, Colors.SidebarSelected)
					},
					Transparency = NumberSequence.new{
						NumberSequenceKeypoint.new(0, .5),
						NumberSequenceKeypoint.new(1, 0),
					},
					Parent = progress
				})
				
				local debounce = false

				local function callback(newToggle: boolean)
					if debounce then return end

					debounce = true
					toggle = newToggle

					Tween(pointer, .1, {
						Position = UDim2.new(toggle and 1 or 0, toggle and -10 or 0, .5, 0)
					}):Play()

					Tween(progress, .1, {
						Size = UDim2.new(toggle and 1 or 0, 0, 0, 10)
					}):Play()

					task.wait(.1)

					if typeof(f) == 'function' then
						f(toggle)
					end
					
					debounce = false
				end

				Connections:Add(Create('TextButton', {
					Size = UDim2.new(1,0,1,0),
					Parent = container,
					Text = '',

					BackgroundTransparency = 1
				}).MouseButton1Click:Connect(function()
					callback(not toggle)
				end))

				task.spawn(function()
					callback(toggle)
				end)

				return function (newToggle: boolean)
					callback(newToggle);
				end
			end

			function modules:AddSlider(name: string, min: number, max: number, value: number, f: (n: number) -> ())
				assert(typeof(min) == 'number', `'min' is not a 'number', got '{typeof(min)}'`)
				assert(typeof(max) == 'number', `'max' is not a 'number', got '{typeof(max)}'`)
				assert(typeof(value) == 'number', `'value' is not a 'number', got '{typeof(value)}'`)

				value = math.min(math.max(min, value), max)

				local NumberValue = Create('NumberValue', {
					Value = value
				})

				local container = create_container()
				container.Size = UDim2.new(1, -5, 0, 50)

				local TextBox: TextBox = Create('TextBox', {
					AnchorPoint = Vector2.new(1, .5),

					BackgroundTransparency = .5,
					BackgroundColor3 = Color3.new(),
					Position = UDim2.new(1, -20, .3, 0),
					
					Size = UDim2.new(0, 100, 0, 20),
					Parent = container,

					Font = Enum.Font.Fantasy,
					TextColor3 = Color3.fromRGB(180, 180, 180),
					TextSize = 18,
					Text = `{NumberValue.Value}`
				})

				local Pointer;
				do
					local Label = Create('TextLabel', {
						AnchorPoint = Vector2.new(.5, .5),
						BackgroundTransparency = 1,
						ClipsDescendants = false,

						Font = Enum.Font.Fantasy,
						Text = `{name}`,
						TextSize = 18,

						Parent = container,
						Position = UDim2.new(.3, 0, .3, 0),
						TextColor3 = Color3.fromRGB(180, 180, 180),

						Size = UDim2.new(.5, 0, 0, 25),
						TextXAlignment = Enum.TextXAlignment.Left
					})

					local Frame : TextButton = Create('TextButton', {
						AnchorPoint = Vector2.new(.5, .5),
						BackgroundTransparency = .5,
						BackgroundColor3 = Color3.new(),

						Position = UDim2.new(.5, 0, .5, 8),
						Size = UDim2.new(1, -30, 0, 10),

						Parent = container,
						Text = ''
					})

					Pointer = Create('Frame', {
						Active = false,
						AnchorPoint = Vector2.new(.5, .5),
						BackgroundColor3 = Colors.SidebarSelected,

						Position = UDim2.new(0, 0, .5, 0),
						Size = UDim2.new(0, 10, 0, 10),
						
						Parent = Frame,
						ZIndex = 2
					}) :: Frame

					Create('UICorner', {
						Parent = Pointer,

						CornerRadius = UDim.new(.5, 0)
					}):Clone().Parent = Frame

					Create('UIStroke', {
						Parent = Pointer,

						ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
						Color = Color3.new(255, 255, 255),
						Enabled = true,
						Thickness = 2
					})

					local Progress = Frame:Clone()
					Progress:ClearAllChildren()
					Progress.Active = false
					Progress.Parent = Frame
					Progress.BackgroundColor3 = Color3.new(1,1,1)
					Progress.AnchorPoint = Vector2.new(0, 1)
					Progress.Position = UDim2.new(0, 0, 1, 0)
					Progress.Size = UDim2.new(1, 0, 1, 0)
					Create('UICorner', {
						CornerRadius = UDim.new(.5, 0),
						Parent = Progress
					})

					Create('UIGradient', {
						Enabled = true,
						Color = ColorSequence.new{
							ColorSequenceKeypoint.new(0, Colors.SidebarSelected),
							ColorSequenceKeypoint.new(1, Colors.SidebarSelected)
						},
						Transparency = NumberSequence.new{
							NumberSequenceKeypoint.new(0, .5),
							NumberSequenceKeypoint.new(1, 0),
						},
						Parent = Progress
					})

					Connections:Add(Pointer:GetPropertyChangedSignal('Position'):Connect(function()
						Progress.Size = UDim2.new(Pointer.Position.X.Scale, 0, 1, 0)
					end))

					local isholding = false
					local function FrameCallback(X)
						isholding = true

						while isholding and Library.running do
							local X = math.min(1, math.max(0, (Mouse.X - Frame.AbsolutePosition.X) / Frame.AbsoluteSize.X))
							NumberValue.Value = math.ceil(X * max)

							Tween(Pointer, .1, {
								Position = UDim2.new(X, 0, .5, 0)
							}):Play()

							task.wait()
						end
					end

					Connections:Add(Frame.MouseButton1Down:Connect(FrameCallback))
					Connections:Add(Progress.MouseButton1Down:Connect(FrameCallback))

					Connections:Add(UIS.InputEnded:Connect(function(input, chatting)
						if chatting then
							isholding = false
							return
						end

						if input.UserInputType == Enum.UserInputType.MouseButton1 then
							isholding = false
						end
					end))

					Connections:Add(Frame.MouseButton1Up:Connect(function()
						isholding = false
					end))

					Connections:Add(NumberValue:GetPropertyChangedSignal('Value'):Connect(function()
						if not isholding then
							Tween(Pointer, .5, {
								Position = UDim2.new(NumberValue.Value / max, 0, .5, 0)
							}):Play()

							task.spawn(function()
								f(NumberValue.Value)
							end)
						end
						
						-- warn(NumberValue.Value)
						TextBox.Text = `{NumberValue.Value}`
						TextBox.PlaceholderText = `{NumberValue.Value}`
					end))

					Connections:Add(TextBox.FocusLost:Connect(function()
						local num = tonumber(TextBox.Text)

						if typeof(num) ~= 'number' then
							num = NumberValue.Value
						end

						num = math.min(math.max(min, num), max)

						TextBox.Text = num
						NumberValue.Value = num
					end))

					NumberValue.Value = 0
					NumberValue.Value = value

					local Min = Label:Clone()
					Min.BackgroundTransparency = 1
					Min.Parent = container
					Min.Size = UDim2.new(0, 30, 0, 10)
					Min.Position = UDim2.new(0, 30, .5, 18)
					Min.TextSize = 14
					Min.Text = `{min}`

					local Max = Label:Clone()
					Max.BackgroundTransparency = 1
					Max.Parent = container
					Max.Size = UDim2.new(0, 30, 0, 10)
					Max.Position = UDim2.new(1, -30, .5, 18)
					Max.TextSize = 14
					Max.Text = `{max}`
					Max.TextXAlignment = Enum.TextXAlignment.Right
				end

				Create('UICorner', {
					Parent = TextBox,
					CornerRadius = UDim.new(.25, 0)
				})
			end

			if is_sub ~= true then
				function modules:AddSubsection(name)
					local page = create_container()
					page.BackgroundTransparency = 1
					
					local container = page:Clone()
					local label_container = page:Clone()

					local UIListLayout = Create('UIListLayout', {
						Parent = container,

						Padding = UDim.new(0, 5),
						SortOrder = Enum.SortOrder.LayoutOrder,
					})

					Connections:Add(UIListLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
						local AbsoluteContentSize: Vector2 = UIListLayout.AbsoluteContentSize
						
						container.Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 5)
						page.Size = UDim2.new(1, 0, 0, AbsoluteContentSize.Y + 5)
						-- container.Size = UDim2.new(1, 0, 0, y)
					end))
					
					
					page.BackgroundTransparency = 1

					container.Size = UDim2.new(1, 0, 0, 0)
					container.Parent = page
					
					label_container.Parent = container
					label_container.BackgroundTransparency = 1
					label_container.Size = UDim2.new(1, 0, 0, 30)
					
					local label = Create('TextLabel', {
						AnchorPoint = Vector2.new(.5, 0),
						BackgroundTransparency = 1,
						BorderSizePixel = 0,
						Parent = label_container,

						Font = Enum.Font.Fantasy,
						Position = UDim2.new(.5, 0, 0, 10),
						Size = UDim2.new(1, -10, 0, 20),
						Text = name,
						TextColor3 = Color3.fromRGB(180, 180, 180),
						TextSize = 18,

						TextXAlignment = Enum.TextXAlignment.Left
					})
					


					return create_components(container, true)
				end
			end

			return modules
		end

		return create_components(page)
	end

	return module
end

return Library