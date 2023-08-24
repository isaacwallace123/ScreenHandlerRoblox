local Market = game:GetService("MarketplaceService")
local SoundPath = game:GetService("SoundService").Main.Song
local Screens = game.Workspace.Screens

local RecordedLoudness = {}

local Screen = {}

local LowColor = Color3.fromHSV(0, 0, 0)
local MedColor = Color3.fromHSV(0.169556, 0.678431, 1)
local HighColor = Color3.fromHSV(0.166667, 0.637263, 0.8)
local LowestColor = Color3.fromRGB(0,0,0)

local Fade = 1
local FadeDistance = 20

function ColorMultiplier(c,f)
	return Color3.new(c.R*f,c.G*f,c.B*f)
end

function Screen.Effect()
	local Vol = RecordedLoudness[#RecordedLoudness]
	local VolP = math.clamp(Vol/250+0.2,0,1)
	
	local TimePos = math.floor(SoundPath.TimePosition*100)/100
	
	if TimePos <= 5 then
		Fade = TimePos/5
	elseif TimePos >= SoundPath.TimeLength-FadeDistance then
		local FadeDistanceRange = SoundPath.TimeLength-FadeDistance
		local NewTimePosition = TimePos-FadeDistanceRange
		Fade = 1-(NewTimePosition/FadeDistance)
	end

	local Color = LowColor:Lerp(LowestColor,1-VolP)
	local HalfColor = MedColor:Lerp(LowestColor,1-VolP)
	local LastColor = HighColor:Lerp(LowestColor,1-VolP)
	local SecondLightColor = Color:Lerp(LastColor,0.5):Lerp(Color3.new(0.9,0.9,0.9),0.25)
	SecondLightColor = ColorMultiplier(SecondLightColor,Fade)

	local VolDiv = Vol/1000

	local ColorSEQ = ColorSequence.new({
		ColorSequenceKeypoint.new(0,LowestColor),
		ColorSequenceKeypoint.new( math.clamp(VolDiv-VolDiv/2.5,0.01,0.99)-0.01 ,LowestColor),
		ColorSequenceKeypoint.new( math.clamp(VolDiv-VolDiv/2.5,0.01,0.99) ,ColorMultiplier(Color,Fade)),
		ColorSequenceKeypoint.new( math.clamp(VolDiv,0.02,0.98) ,ColorMultiplier(HalfColor,Fade)),
		ColorSequenceKeypoint.new( math.clamp(VolDiv+VolDiv/2.5,0.03,0.97) ,ColorMultiplier(LastColor,Fade)),
		ColorSequenceKeypoint.new( math.clamp(VolDiv+VolDiv/2.5,0.03,0.97)+0.01 ,LowestColor),
		ColorSequenceKeypoint.new(1,LowestColor)
	})

	for _,Model in pairs(Screens:GetChildren()) do
		if Model:IsA("Model") and Model.PrimaryPart and Model.PrimaryPart:FindFirstChild("ScreenUI") then
			for i,v in pairs(Model.PrimaryPart.ScreenUI.Main.Effects.Container:GetChildren()) do
				v.UIGradient.Color = ColorSEQ
			end
		end
	end
end


local BarList = {}

local Amount = 20
local BarGap = 0.5 / Amount

local Generated = false

for _,Model in pairs(Screens:GetChildren()) do
	if Model:IsA("Model") and Model.PrimaryPart and Model.PrimaryPart:FindFirstChild("ScreenUI") then
		BarList[Model.PrimaryPart] = {}
		
		for i=1,Amount do
			local Bar = Instance.new("Frame", Model.PrimaryPart.ScreenUI.Main.Bars.Container)

			Bar.BorderSizePixel = 0
			Bar.AnchorPoint = Vector2.new(0.5,1)
			
			local Size = 1 / Amount

			Bar.Position = UDim2.fromScale((i-1) * Size + Size/2, 1)
			Bar.Size = UDim2.fromScale((Size - BarGap), 0.2)
			
			table.insert(BarList[Model.PrimaryPart], Bar)
		end
	end
end

Generated = true

function Screen.Bars()
	if not Generated then return end
	
	if #RecordedLoudness >= Amount then
		table.remove(RecordedLoudness,1)
	end
	
	table.insert(RecordedLoudness,SoundPath.PlaybackLoudness)
	
	local ColorTable = {}
	
	for i = #RecordedLoudness,1,-1 do
		local Recorded = RecordedLoudness[i]

		local BaseColor = LowestColor:Lerp(LowColor,math.clamp(Recorded/100,0,1))
		local MidColor = BaseColor:Lerp(MedColor,math.clamp(Recorded/200,0,1))
		local FinColor = MidColor:Lerp(HighColor,math.clamp(Recorded/1500,0,1))
		
		ColorTable[i] = {
			Color = ColorMultiplier(FinColor,Fade),
			Size = math.clamp(Recorded / 350, 0, 1)
		}
	end
	
	for _,Model in pairs(BarList) do
		local BarSize = Model[1].Size
		
		for Index,Bar in pairs(Model) do
			if ColorTable[Index] then
				Bar.Size = UDim2.fromScale(BarSize.X.Scale, ColorTable[Index].Size)
				Bar.BackgroundColor3 = ColorTable[Index].Color
			end
		end
	end
end

function toHMS(s)
	return string.format("%02i:%02i", s/60, s%60)
end

function Screen.SongInfo()
	if SoundPath.IsPlaying then
		local Percent = SoundPath.TimePosition / SoundPath.TimeLength
		local CurrentTime = toHMS(math.floor(SoundPath.TimePosition))
		local FinalTime = toHMS(math.floor(SoundPath.TimeLength))
		
		for _,Model in pairs(Screens:GetChildren()) do
			if Model:IsA("Model") and Model.PrimaryPart and Model.PrimaryPart:FindFirstChild("ScreenUI") then
				Model.PrimaryPart.ScreenUI.Main.SongStats.Container.TimeContainer.Current.Text = CurrentTime
				Model.PrimaryPart.ScreenUI.Main.SongStats.Container.TimeContainer.Final.Text = FinalTime
				Model.PrimaryPart.ScreenUI.Main.SongStats.Container.TimeContainer.AudioBar.Bar.Size = UDim2.fromScale(Percent, 1)
			end
		end
	end
end

return Screen