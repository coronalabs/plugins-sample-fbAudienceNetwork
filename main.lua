
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
local bannerPlacementID = "[YOUR-BANNER-PLACEMENT-ID]"
local interstitialPlacementID = "[YOUR-INTERSTITIAL-PLACEMENT-ID]"

-- Set device hash ID for testing Facebook Ads
-- Alternatively, multiple test devices can be included in a table ( {"[DEVICE-1-HASH-ID]","[DEVICE-2-HASH-ID]"} )
-- See here for instructions: https://docs.coronalabs.com/plugin/fbAudienceNetwork/init.html
local deviceHash = "[YOUR-DEVICE-HASH-ID]"

-- Require libraries/plugins
local widget = require( "widget" )
local fbAudienceNetwork = require( "plugin.fbAudienceNetwork" )

-- Set app font
local appFont = sampleUI.appFont

-- Table of data for menu buttons
local menuButtons = {
	loadBanner = { label="load banner ad", y=120, fill={ 0.16,0.36,0.56,1 } },
	showBanner = { label="show banner ad", y=170, fill={ 0.14,0.34,0.54,1 } },
	hideBanner = { label="hide banner ad", y=220, fill={ 0.12,0.32,0.52,1 } },
	loadInterstitial = { label="load interstitial ad", y=285, fill={ 0.16,0.36,0.56,1 } },
	showInterstitial = { label="show interstitial ad", y=335, fill={ 0.14,0.34,0.54,1 } }
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
	if ( setupComplete == false ) then return end

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
	end
end


-- Function to prompt/alert user for setup
local function checkSetup()

	if ( system.getInfo( "environment" ) ~= "device" ) then return end

	if ( tostring(bannerPlacementID) == "[YOUR-BANNER-PLACEMENT-ID]" or tostring(interstitialPlacementID) == "[YOUR-INTERSTITIAL-PLACEMENT-ID]" ) then
		local alert = native.showAlert( "Important", 'Confirm that you have specified your Facebook placement IDs within "main.lua" on lines 28-29. Proceed to the Facebook guide for instructions.', { "OK", "guide" },
			function( event )
				if ( event.action == "clicked" and event.index == 2 ) then
					system.openURL( "https://developers.facebook.com/docs/audience-network/getting-started" )
				end
			end )
	elseif ( tostring(deviceHash) == "[YOUR-DEVICE-HASH-ID]" ) then
		fbAudienceNetwork.init( adListener )
		fbAudienceNetwork.load( "banner", bannerPlacementID )
		local alert = native.showAlert( "Important", 'For testing the Facebook Audience Network, you must follow Facebook protocol by gathering this device’s hash ID. With this device connected, find the "Test mode device hash" within the device console log, enter it within "main.lua" on line 34, and then build/run this sample again.', { "OK" } )
	else
		setupComplete = true
	end
end


-- Button handler function
local function onButtonRelease( event )

	if ( event.target.id == "loadBanner" ) then
		fbAudienceNetwork.load( "banner", bannerPlacementID, "BANNER_HEIGHT_50" )

	elseif ( event.target.id == "showBanner" ) then
		if ( fbAudienceNetwork.isLoaded( bannerPlacementID ) == true ) then
			updateUI( { enable={ "hideBanner" }, disable={ "loadBanner","showBanner" }, bannerPromptTo="hideBanner" } )
			fbAudienceNetwork.show( "banner", bannerPlacementID, { yAlign="bottom" } )
		end

	elseif ( event.target.id == "hideBanner" ) then
		updateUI( { enable={ "loadBanner" }, disable={ "showBanner","hideBanner" }, bannerPromptTo="loadBanner" } )
		fbAudienceNetwork.hide( bannerPlacementID )

	elseif ( event.target.id == "loadInterstitial" ) then
		fbAudienceNetwork.load( "interstitial", interstitialPlacementID )

	elseif ( event.target.id == "showInterstitial" ) then
		if ( fbAudienceNetwork.isLoaded( interstitialPlacementID ) == true ) then
			fbAudienceNetwork.show( "interstitial", interstitialPlacementID )
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
			fillColor = { default = v.fill, over = v.fill },
			labelColor = { default={ 1,1,1,1 }, over={ 1,1,1,0.8 } },
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
fbAudienceNetwork.init( adListener, deviceHash )
