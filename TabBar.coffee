# button that creates a ripple effect when clicked
class RippleButton extends Layer
	constructor: (@options={}) ->
		_.defaults @options,
			backgroundColor: "white"
			rippleColor: undefined
			rippleOptions: time: 0.25, curve: Bezier.easeOut
			triggerOnClick: true
		super @options
		if @rippleColor is undefined
			@rippleColor = @backgroundColor.darken 10

		# layer that contains @_ripple circle
		@_clipper = new Layer
			size: @size
			parent: @
			clip: true
			backgroundColor: ""

		# circle that animates to create ripple effect
		@_ripple = new Layer
			name: "ripple"
			borderRadius: "50%"
			backgroundColor: @rippleColor
			parent: @_clipper
			size: 0
		@on "change:size", ->
			@_clipper.size = @size
		@_clipper.onClick (event, target) =>
			if @triggerOnClick is true
				@sendRipple event,target

	# triggers ripple animation
	# parameters event and target come from click event
	sendRipple: (event, target) ->
		clickPoint = target.convertPointToLayer(event.point, target)
		r = @selectChild("ripple")
		r.size = 0
		r.midX = clickPoint.x
		r.midY = clickPoint.y
		r.opacity = 1
		radius = @_longestRadius clickPoint, @
		rippleAnimation = new Animation r,
			size: radius * 2
			x: clickPoint.x - radius
			y: clickPoint.y - radius
			options: @rippleOptions
		fadeAnimation = new Animation r,
			opacity: 0
			options:
				time:
					rippleAnimation.options.time * 2.5
				curve:
					rippleAnimation.options.curve
		rippleAnimation.restart()
		fadeAnimation.restart()

	_longestRadius: (point, layer) ->
		pointToUpperLeft = Math.sqrt( Math.pow(point.x, 2) + Math.pow(point.y, 2))
		pointToUpperRight = Math.sqrt( Math.pow(layer.width - point.x, 2) + Math.pow(point.y, 2))
		pointToLowerLeft = Math.sqrt( Math.pow(point.x, 2) + Math.pow(layer.height - point.y, 2))
		pointToLowerRight = Math.sqrt( Math.pow(layer.width - point.x, 2) + Math.pow(layer.height - point.y, 2))
		return Math.max pointToUpperLeft, pointToUpperRight, pointToLowerLeft, pointToLowerRight

	@define "rippleOptions",
		get: -> @options.rippleOptions
		set: (value) -> @options.rippleOptions = value
	@define "rippleColor",
		get: -> @options.rippleColor
		set: (value) -> @options.rippleColor = value
	@define "triggerOnClick",
		get: -> @options.triggerOnClick
		set: (value) -> @options.triggerOnClick = value

class TabContent extends Layer
	constructor: (@options={}) ->
		_.defaults @options,
			backgroundColor: ""
			name: "TabContent"
			clip: true
		super @options
		@currentPageIndex = undefined #current page index
		@priorPageIndex = undefined #prior page index
		@pages = []

		# handle swiping to change tabs
		@onSwipeRightStart ->
			@_selectPreviousPage()
		@onSwipeLeftStart ->
			@_selectNextPage()

		# handle size change
		@on "change:size", ->
			@layoutPages()

	# call for each page to add
	addPage: (page) ->
		@pages.push page
		page.parent = @
		page.animationOptions = @animationOptions
		page.point = x: -page.width, y: 0
		@layoutPages()

	layoutPages: Utils.debounce 0.01, ->
		for page, i in @pages
			page.size = @size
			if @tabBar.selectedTabIndex is i
				page.x = 0
				@currentPageIndex = i
			else
				page.x = -page.width


	# selects tab to right. called on swipe
	_selectNextPage: ->
		if @currentPageIndex + 1 < @pages.length
			@tabBar.selectTab @currentPageIndex + 1

	# selects tab to left. called on swipe
	_selectPreviousPage: ->
		if @currentPageIndex > 0
			@tabBar.selectTab @currentPageIndex - 1

	# called from the TabBar and slides the page into position.
	selectPage: (index) ->
		return if index is @currentPageIndex
		currentLayer = @pages[index]
		priorLayer = @pages[@currentPageIndex]
		# the current tab is to the right, so animate from the left
		if  index > @currentPageIndex
			currentLayer.x = Screen.width
			priorLayer.animate x: -priorLayer.width
			currentLayer.animate x: 0
		# the current tab is to the left, so animate from the right
		else if index < @currentPageIndex
			currentLayer.x = -currentLayer.width
			priorLayer.animate x: Screen.width
			currentLayer.animate x: 0
		@priorPageIndex = @currentPageIndex
		@currentPageIndex = index
		@emit "change:page",
			{index: @currentPageIndex, layer: @pages[@currentPageIndex]},
			{index: @priorPageIndex, layer: @pages[@priorPageIndex]}
	@define "currentPage",
		get: -> @pages[@currentPageIndex]

class exports.TabBar extends ScrollComponent
	constructor: (@options={}) ->
		_.defaults @options,
			tabLabels: ["TAB ONE","TAB TWO","TAB THREE"]
			width: Screen.width
			height: 46
			font: Utils.loadWebFont "Roboto"
			fontSize: 15
			ripple: true
			rippleColor = undefined
			selectedColor: "white"
			deselectedColor: "rgba(255,255,255,0.7)"
			selectedTabIndex: 0
			minimumPadding: 12  # padding on either side of tab text
			firstLastTabInset: 5  # gap between left/right side of TabBar and first/last tab
			backgroundColor: "cornflowerblue"
			animationOptions: time: 0.275, curve: Bezier.ease
		super @options

		@scrollVertical = false

		# make tabBar layer
		@tabBar = new Layer
			x: 0
			name: "tabBar"
			height: @height
			parent: @content
			backgroundColor: ""

		# make selection line
		@tabSelectionLine = new Layer
			name: "tabSelectionLine"
			height: 2
			width: 0
			backgroundColor: "white"
			y: @tabBar.height - 2
			animationOptions: @animationOptions
			parent: @tabBar

		@currentTab = undefined  # holds currently selected tab layer
		@priorTab = undefined  # holds tab layer that had previously been selected
		@tabs = []

		@on "change:width", ->
			@layoutTabs()

		@_createTabs()

# FUNCTIONS ================================================================

	# create the layer holding the pages that the tabs control (optional).
	# Created automatically if coder accesses it. (e.g., tabBar.tabContent)
	createTabContent: ->
		tcp = new TabContent
			width: Screen.width
			height: Screen.height - @height
			y: @height
			animationOptions: @animationOptions
		tcp.tabBar = @
		return tcp


	# make the tab layers
	_createTabs: ->
		# remove old tabs in case this is called after initialization
		for tab in @tabs
			tab.parent = null
			tab.destroy()

		@tabs = []
		@_labelWidths = [] # store natural widths of text labels
		for label, i in @tabLabels
			# make tab label
			tabLabel = new TextLayer
				name: "label"
				font: @font
				fontSize: @fontSize
				color: @deselectedColor
				textAlign: "center"
				text: label
				animationOptions: @animationOptions
			# make tab
			props =
				name: "tab_#{i}"
				height: @tabBar.height
				backgroundColor: @backgroundColor
				parent: @tabBar
				animationOptions: @animationOptions
			if @options.ripple is true
				tab = new RippleButton props
				tab.triggerOnClick = false
			else
				tab = new Layer props
			@tabs.push tab

			tabLabel.parent = tab
			@_labelWidths.push tabLabel.width

			# handle click
			tab.onClick (event, target) =>
				if @currentTab isnt target
					if target.constructor.name is "RippleButton"
						target.sendRipple event, target
					@selectTab target
		@layoutTabs()

	# scrolls appropriately when a tab is selected
	_scrollToSelectedTab: (animated = true) ->
		return if @currentTab is undefined
		newScrollX = Math.max(0, Math.min(@currentTab.x + @currentTab.width/2 - @width/2, @tabBar.width - @width))
		if animated
			@animate scrollX: newScrollX
		else
			@scrollX = newScrollX

	layoutTabs: ->
		widthOfAllTabs = 0
		for width in @_labelWidths
			widthOfAllTabs += width + @minimumPadding * 2

		if widthOfAllTabs >= @width - @contentInset.left - @contentInset.right
			@tabBar.width = widthOfAllTabs + @firstLastTabInset * 2
			@content.draggable.overdrag = true
			extraWidthPerTab = 0
		else
			@tabBar.width = @width
			@content.draggable.overdrag = false
			extraWidthPerTab = Math.round (@tabBar.width - widthOfAllTabs - @firstLastTabInset * 2)/@tabs.length
		runningLeft = @firstLastTabInset
		for i in [0...@_labelWidths.length]
			@tabs[i].x = runningLeft
			@tabs[i].width = @_labelWidths[i] + extraWidthPerTab + @minimumPadding * 2
			@tabs[i].selectChild("label").width = @tabs[i].width
			# center label in tab
			@tabs[i].selectChild("label").point = Align.center
			runningLeft += @tabs[i].width
		@selectTab @selectedTabIndex, false, true
		@tabSelectionLine.bringToFront()
		@updateContent()


	selectTab: (value, animated = true, forceSelection = false) ->
		if Utils.inspectObjectType(value) isnt "Number"
			layer = value
		else
			layer = @tabs[value]
		return if layer is @currentTab and not forceSelection
		@options.selectedTabIndex = _.indexOf @tabs, layer
		selectedLineProps = width: layer.width, x: layer.x
		if animated
			@tabSelectionLine.animate selectedLineProps
			layer.selectChild("label").animate color: @selectedColor
		else
			@tabSelectionLine.props = selectedLineProps
			layer.selectChild("label").color = @selectedColor
		if not forceSelection
			@priorTab = @currentTab
		if animated
			@priorTab?.selectChild("label").animate color: @deselectedColor
		else
			@priorTab?.selectChild("label").color = @deselectedColor
		@currentTab = layer
		@_scrollToSelectedTab(animated)
		if not forceSelection
			# change the page in TabContent instance, if latter exists
			@_tabContent?.selectPage @options.selectedTabIndex
			@emit "change:tab",
				{index: @selectedTabIndex
				layer: layer
				text: @currentTab.selectChild("label").text},
				{index: _.indexOf(@tabs, @priorTab)
				layer: @priorTab
				text: @priorTab?.selectChild("label").text}
		return layer

	# Getters/Setters ===================================================

	# Create the pages tabContent layer if the property is accessed (e.g., tabBar.tabContent)
	@define "newTab",
		get: ->
			if @options.ripple is true
				button = new RippleButton
			else
				button = new Layer
	@define "tabContent",
		get: ->
			if @_tabContent is undefined
				return @_tabContent = @createTabContent()
			else
				return @_tabContent
	@define "minimumPadding",
		get: -> @options.minimumPadding
		set: (value) ->
			# avoid calling layoutTabs() when this property is set from constructor
			if @__framerInstanceInfo?
				@options.minimumPadding = value
				@layoutTabs()
	@define "firstLastTabInset",
		get: -> @options.firstLastTabInset
		set: (value) ->
			# avoid calling layoutTabs() when this property is set from constructor
			if @__framerInstanceInfo?
				@options.firstLastTabInset = value
				@layoutTabs()
	@define "tabLabels",
		get: -> @options.tabLabels
		set: (value) ->
			# avoid calling _createTabs() when this property is set from constructor
			if @__framerInstanceInfo?
				@options.selectedTabIndex = Math.min(@selectedTabIndex, value.length - 1)
				@options.tabLabels = value
				@_createTabs()
	@define "selectedTabIndex",
		get: -> @options.selectedTabIndex
		set: (value) ->
			# avoid calling selectTab() when this property is set from constructor
			if @__framerInstanceInfo?
				@options.selectedTabIndex = value
				@selectTab value
	# the following are read-only after the class is created
	@define "font",
		get: -> @options.font
	@define "fontSize",
		get: -> @options.fontSize
	@define "selectedColor",
		get: -> @options.selectedColor
	@define "deselectedColor",
		get: -> @options.deselectedColor
