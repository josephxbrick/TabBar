# TabContent (use with TabBar is optional) holds content pages that are
# controlled by the class TabBar. It won't be created unless it is accessed.
# Note that this differs from PageComponent in that when choosing non-adjacent
# tabs, you don't see the pages between the prior page and the new page fly by.
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

	# call for each page to add
	addPage: (layer) ->
		@pages.push layer
		layer.parent = @
		layer.size = @size
		layer.animationOptions = @animationOptions
		layer.point = 0
		# define states for sliding tabs in and out
		layer.states =
			default: x: 0 # shown
			hiddenToLeft: x: -layer.width
			hiddenToRight: x: layer.width
		if @tabBar.selectedTabIndex is @pages.length - 1
			layer.stateSwitch "default"
			@currentPageIndex = @pages.length - 1
		else
			layer.stateSwitch "hiddenToRight"

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
			currentLayer.stateSwitch "hiddenToRight"
			priorLayer.animate "hiddenToLeft"
			currentLayer.animate "default"
		# the current tab is to the left, so animate from the right
		else if index < @currentPageIndex
			currentLayer.stateSwitch "hiddenToLeft"
			priorLayer.animate "hiddenToRight"
			currentLayer.animate "default"
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
			selectedColor: "white"
			deselectedColor: "rgba(255,255,255,0.7)"
			selectedTabIndex: 0
			minimumPadding: 8  # padding on either side of tab text
			firstLastTabInset: 5  # gap between left/right side of TabBar and first/last tab
			backgroundColor: "#4C5BAE"
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
			@_layoutTabs()

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
			tab = new Layer
				name: "tab_#{i}"
				height: @tabBar.height
				backgroundColor: ""
				parent: @tabBar
			@tabs.push tab

			tabLabel.parent = tab
			@_labelWidths.push tabLabel.width

			# handle click
			tab.onClick (event, target) =>
				@selectTab target

		@_layoutTabs()

	# scrolls appropriately when a tab is selected
	_scrollToSelectedTab: (animated = true) ->
		return if @currentTab is undefined
		newScrollX = Math.max(0, Math.min(@currentTab.x + @currentTab.width/2 - @width/2, @tabBar.width - @width))
		if animated
			@animate scrollX: newScrollX
		else
			@scrollX = newScrollX

	_layoutTabs: ->
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
		@updateContent()


	selectTab: (value, animated = true, forceSelection = false) ->
		if Utils.inspectObjectType(value).indexOf("Layer") >= 0 # workaround for inspectObjectType bug on moble.
			layer = value
		else if Utils.inspectObjectType(value) is "Number"
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
	@define "tabContent",
		get: ->
			if @_tabContent is undefined
				return @_tabContent = @createTabContent()
			else
				return @_tabContent
	@define "minimumPadding",
		get: -> @options.minimumPadding
		set: (value) ->
			# avoid calling _layoutTabs() when this property is set from constructor
			if @__framerInstanceInfo?
				@options.minimumPadding = value
				@_layoutTabs()
	@define "firstLastTabInset",
		get: -> @options.firstLastTabInset
		set: (value) ->
			# avoid calling _layoutTabs() when this property is set from constructor
			if @__framerInstanceInfo?
				@options.firstLastTabInset = value
				@_layoutTabs()
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
