
-- Abstract: Facebook Audience Network
-- Version: 1.0
-- Sample code is MIT licensed; see https://www.coronalabs.com/links/code/license
---------------------------------------------------------------------------------------

display.setStatusBar( display.HiddenStatusBar )

------------------------------
-- RENDER THE SAMPLE CODE UI
------------------------------
local sampleUI = require( "sampleUI.sampleUI" )
sampleUI:newUI( { theme="darkgrey", title="Facebook Audience Network", showBuildNum=true } )

------------------------------
-- CONFIGURE STAGE
------------------------------
display.getCurrentStage():insert( sampleUI.backGroup )
local mainGroup = display.newGroup()
display.getCurrentStage():insert( sampleUI.frontGroup )

----------------------
-- BEGIN SAMPLE CODE
----------------------

-- Preset Facebook placement IDs (replace these with your own)
-- See here for instructions: https://developers.facebook.com/docs/audience-network/getting-started
local bannerPlacementID = "YOUR_BANNER_PLACEMENT_ID"
local interstitialPlacementID = "YOUR_INTERSTITIAL_PLACEMENT_ID"

-- Multiple test devices can be included in a table array { "DEVICE_1_HASH_ID", "DEVICE_2_HASH_ID" }
-- See here for instructions: https://docs.coronalabs.com/plugin/fbAudienceNetwork/init.html
local deviceHashArray = { "YOUR_DEVICE_1_HASH_ID" }

-- Require libraries/plugins
local widget = require( "widget" )
local fbAudienceNetwork = require( "plugin.fbAudienceNetwork" )

-- Set app font
local appFont = sampleUI.appFont

-- Table of data for menu buttons
local menuButtons = {
	loadBanner = { label="Load Banner Ad", y=120 },
	showBanner = { label="Show Banner Ad", y=170 },
	hideBanner = { label="Hide Banner Ad", y=220 },
	loadInterstitial = { label="Load Interstitial Ad", y=285 },
	showInterstitial = { label="Show Interstitial Ad", y=335 }
}

-- Set local variables
local setupComplete = false

-- Create objects to visually prompt action
local bannerPrompt = display.newPolygon( mainGroup, 62, menuButtons["loadBanner"].y, { 0,-12, 12,0, 0,12 } )
bannerPrompt:setFillColor( 0.8 )
bannerPrompt.alpha = 0
local interstitialPrompt = display.newPolygon( mainGroup, 62, menuButtons["loadInterstitial"].y, { 0,-12, 12,0, 0,12 } )
interstitialPrompt:setFillColor( 0.8 )
interstitialPrompt.alpha = 0

-- Create spinner widget for indicating ad status
widget.setTheme( "widget_theme_android_holo_light" )
local spinner = widget.newSpinner( { x=display.contentCenterX, y=410, deltaAngle=10, incrementEvery=10 } )
mainGroup:insert( spinner )
spinner.alpha = 0


-- Function to manage spinner appearance/animation
local function manageSpinner( action )
	if ( action == "show" ) then
		spinner:start()
		transition.cancel( "spinner" )
		transition.to( spinner, { alpha=1, tag="spinner", time=((1-spinner.alpha)*320), transition=easing.outQuad } )
	elseif ( action == "hide" ) then
		transition.cancel( "spinner" )
		transition.to( spinner, { alpha=0, tag="spinner", time=((1-(1-spinner.alpha))*320), transition=easing.outQuad,
			onComplete=function() spinner:stop(); end } )
	end
end


-- Function to update button visibility/state
local function updateUI( params )

	-- Disable inactive buttons
	for i = 1,#params["disable"] do
		local ref = params["disable"][i]
		local button = menuButtons[ref]["object"]
		button:setEnabled( false )
		button.alpha = 0.3
	end

	-- Move/transition banner ad prompt
	if ( params.bannerPromptTo ) then
		transition.to( bannerPrompt, { y=menuButtons[params.bannerPromptTo].y, alpha=1, time=400, transition=easing.outQuad } )
	end

	-- Move/transition interstitial ad prompt
	if ( params.interstitialPromptTo ) then
		transition.to( interstitialPrompt, { y=menuButtons[params.interstitialPromptTo].y, alpha=1, time=400, transition=easing.outQuad } )
	end
	
	-- Enable new active buttons
	timer.performWithDelay( 400,
		function()
			for i = 1,#params["enable"] do
				local ref = params["enable"][i]
				local button = menuButtons[ref]["object"]
				button:setEnabled( true )
				button.alpha = 1
			end
		end
		)
end


-- Ad listener function
local function adListener( event )

	-- Exit function if user hasn't set up testing parameters
	if ( setupComplete == false ) then 
		if ( event.phase == "init" ) then
			fbAudienceNetwork.load( "banner", { placementId = bannerPlacementID })
			local alert = native.showAlert( "Important", 'For testing the Facebook Audience Network, you must follow Facebook protocol by gathering this device’s hash ID. With this device connected, find the "Test mode device hash" within the device console log, enter it within "main.lua" on line 33, and then build/run this sample again.', { "OK" } )
		end

		return 
	end

	-- Successful initialization of the Facebook Audience Network
	if ( event.phase == "init" ) then
		print( "Facebook Audience Network event: initialization successful" )
		-- Enable both buttons to load ads
		updateUI( { enable={ "loadBanner","loadInterstitial" }, disable={ "showBanner","hideBanner","showInterstitial" }, bannerPromptTo="loadBanner", interstitialPromptTo="loadInterstitial" } )

	-- An ad loaded successfully
	elseif ( event.phase == "loaded" ) then
		print( "Facebook Audience Network event: " .. tostring(event.type) .. " ad loaded successfully" )
		-- Enable show button
		if ( event.type == "banner" ) then
			updateUI( { enable={ "showBanner" }, disable={ "loadBanner","hideBanner" }, bannerPromptTo="showBanner" } )
		elseif ( event.type == "interstitial" ) then
			updateUI( { enable={ "showInterstitial" }, disable={ "loadInterstitial" }, interstitialPromptTo="showInterstitial" } )
		end
		manageSpinner( "hide" )

	-- An interstitial ad was closed by the user
	elseif ( event.phase == "closed" ) then
		print( "Facebook Audience Network event: " .. tostring(event.type) .. " ad closed by user" )
		-- Enable button to load another interstitial; disable button to show interstitial
		updateUI( { enable={ "loadInterstitial" }, disable={ "showInterstitial" }, interstitialPromptTo="loadInterstitial" } )

	-- The ad was clicked/tapped
	elseif ( event.phase == "clicked" ) then
		print( "Facebook Audience Network event: " .. tostring(event.type) .. " ad clicked/tapped by user" )

	-- The ad failed to load
	elseif ( event.phase == "failed" ) then
		print( "Facebook Audience Network event: " .. tostring(event.type) .. " ad failed to load" )
		-- Reset to load button
		if ( event.type == "banner" ) then
			updateUI( { enable={ "loadBanner" }, disable={ "showBanner","hideBanner" }, bannerPromptTo="loadBanner" } )
		elseif ( event.type == "interstitial" ) then
			updateUI( { enable={ "loadInterstitial" }, disable={ "showInterstitial" }, interstitialPromptTo="loadInterstitial" } )
		end
		manageSpinner( "hide" )
	end
end


-- Function to prompt/alert user for setup
local function checkSetup()

	if ( system.getInfo( "environment" ) ~= "device" ) then return end

	if ( tostring(bannerPlacementID) == "YOUR_BANNER_PLACEMENT_ID" or tostring(interstitialPlacementID) == "YOUR_INTERSTITIAL_PLACEMENT_ID" ) then
		local alert = native.showAlert( "Important", 'Confirm that you have specified your Facebook placement IDs within "main.lua" on lines 28-29. Proceed to the Facebook guide for instructions.', { "OK", "guide" },
			function( event )
				if ( event.action == "clicked" and event.index == 2 ) then
					system.openURL( "https://developers.facebook.com/docs/audience-network/getting-started" )
				end
			end )
	elseif ( tostring(deviceHashArray[1]) == "YOUR_DEVICE_1_HASH_ID" ) then
		fbAudienceNetwork.init( adListener )
	else
		setupComplete = true
	end
end


-- Button handler function
local function onButtonRelease( event )

	if ( event.target.id == "loadBanner" ) then
		fbAudienceNetwork.load( "banner", { placementId = bannerPlacementID, bannerSize = "BANNER_HEIGHT_50" })
		manageSpinner( "show" )

	elseif ( event.target.id == "showBanner" ) then
		if ( fbAudienceNetwork.isLoaded( bannerPlacementID ) == true ) then
			updateUI( { enable={ "hideBanner" }, disable={ "loadBanner","showBanner" }, bannerPromptTo="hideBanner" } )
			fbAudienceNetwork.show( "banner", { placementId = bannerPlacementID, y="bottom" } )
		end

	elseif ( event.target.id == "hideBanner" ) then
		updateUI( { enable={ "loadBanner" }, disable={ "showBanner","hideBanner" }, bannerPromptTo="loadBanner" } )
		fbAudienceNetwork.hide( bannerPlacementID )

	elseif ( event.target.id == "loadInterstitial" ) then
		fbAudienceNetwork.load( "interstitial", { placementId = interstitialPlacementID } )
		manageSpinner( "show" )

	elseif ( event.target.id == "showInterstitial" ) then
		if ( fbAudienceNetwork.isLoaded( interstitialPlacementID ) == true ) then
			fbAudienceNetwork.show( "interstitial", { placementId = interstitialPlacementID } )
		end
	end
	return true
end


-- Loop through table to display buttons
for k,v in pairs( menuButtons ) do

	local button = widget.newButton(
		{
			label = v.label,
			id = k,
			shape = "rectangle",
			width = 188,
			height = 32,
			font = appFont,
			fontSize = 16,
			fillColor = { default={ 0.12,0.32,0.52,1 }, over={ 0.132,0.352,0.572,1 } },
			labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,1 } },
			onRelease = onButtonRelease
		})
	button.x = display.contentCenterX + 10
	button.y = v.y
	button:setEnabled( false )
	button.alpha = 0.3
	menuButtons[k]["object"] = button
	mainGroup:insert( button )
end


-- Initially alert user to set up device for testing
checkSetup()

-- Initialize the Facebook Audience Network
fbAudienceNetwork.init( adListener, { testDevices = deviceHashArray } )
