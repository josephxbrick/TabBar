tabBar = new TabBar
	tabLabels: ["HOME", "GAMES", "MOVIES & TV", "BOOKS", "MUSIC", "NEWSSTAND"]

# create pages
for label in tabBar.tabLabels
	layer = new Layer
		width: Screen.width
		height: Screen.height - tabBar.height
		backgroundColor: Utils.randomColor 0.8
	Utils.labelLayer layer, label
	# add page to tabBar.tabContent
	tabBar.tabContent.addPage layer
