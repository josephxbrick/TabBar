# TabBar
Framer component that creates a Material-Design style tab bar, which scrolls if necessary.

Framer sample: [tabbar.framer](https:)

<img src="/readme_images/tabbar_example.gif" width="200">

## Getting Started

If you have Modules installed, or want to use Modules to add this module to you project, click the badge below.

<a href='https://open.framermodules.com/TabBar'>
    <img alt='Install with Framer Modules'
    src='https://www.framermodules.com/assets/badge@2x.png' width='160' height='40' />
</a>

Note that you can hit Ctrl+C in Modules (when TabBar is the active module) to copy a code example that you can then paste into your file. 

If you are not using Modules, download `tabbar.coffee`, place it in the `/modules` folder of your project, and in your coffeescript file, include the following.

`{TabBar} = require "tabbar"`

## Creating a TabBar
The following creates a tab bar with five items, with the second one selected by default.
```
tabBar = new TabBar
	tabLabels: ["WESTWORLD","THE SOPRANOS", "OZ" , "GAME OF THRONES", "TRUE BLOOD"]
  selectedTabIndex: 1 
```
* **tabLabels**: an array of strings that will be the labels of the menu items.
* **selectedTabIndex**: the zero-based index of the tab you want selected
* **font**: the font for the tab labels
* **fontSize**: the font size for the tab labels
* **selectedColor**: the color of the tab text when it's selected
* **deselectedColor**: the color of the tab text when it's deselected
* **minimumPadding**: the minimum padding on either side of the tab text. If the width of the tab bar is less then the combined with of all tabs, then this minimum padding will be utilized and the tab bar will scroll; otherwise, the padding of each tab increases automatically to fill the width of the tab bar.
* **firstLastTabInset**: the inset between the left/right end of the tab bar and the first/last tab

## Adding tab pages (optional)
You can add "pages" (layers, or Frames from Design) that correspond to each tab by adding them to the `pagesPanel` layer of the tab bar. (The `pagesPanel` is created only if you choose to do this.) The order in which the layers are added corresponds to the order of the tabs. So the first layer you add will be displayed when you choose the first tab, etc.  If you use `pagesPanel', you must have the same number of pages as you have tabs.

The following will add the the layers "layer1" through "layer5" to the tab bar `tabBar`.
```
pages = ["layer1", "layer2", "layer3", "layer4", "layer5"]
for page in pages
	tabBar.pagesPanel.addPage page
 ```
## Selecting a tab (through code) 


## Functions
### accordion.addItem()
Use the addItem() function to add a layer to an accordion. This can be a frame created in Design mode or a layer created in code. 
```
accordion.addItem(layer, expandedHeight, normalHeight, clickTarget)
```
* **layer**: (required) the layer to be added
* **expandedHeight**: (required) the height of the accordion item when expanded
* **normalheight**: (optional if not specifying `clickTarget`) the height of the accordion item when contracted. Default is the height of the provided layer.
* **clickTarget**: (optional): the layer that when clicked expands or contracts the accordion item. The default click target is the provided layer. The click target must be either the provided layer or a descendant of the provided layer.
### accordion.expandItem()
Use the expandItem() function to open an accordion item.
```
expandItem(layer, isAnimated)
```
* **layer**: the layer to expand
* **isAnimated**: (optional) boolean: whether the accordion item animates when it opens

### accordion.contractItem()
Use the contractItem() function to close an accordion item.
```
contractItem(layer, isAnimated)
```
* **layer**: the layer to contract
* **isAnimated**: (optional) boolean: whether the accordion item animates when it closes; default is true.

## Events
### accordion.on "expand", ->
The expand message is fired when an accordion item expands.
```
accordion.on "expand", (layer, newHeight, oldHeight) ->
```
* **layer** The layer that expanded
* **newHeight** The height that the layer expands to
* **oldHeight** The height the layer expands from

### accordion.on "contract", ->
The contract message is fired when an accordion item contracts.
```
accordion.on "contact", (layer, newHeight, oldHeight) ->
```
* **layer** The layer that contracted
* **newHeight** The height that the layer contracts to
* **oldHeight** The height the layer contracts from
## Sample Code
```
{Accordion} = require "accordion"

accordion = new Accordion
	width: 300
	spacing: 1
	singleSelect: true
	
# create 10 layers with normal heights of 60 and expanded heights of 200
for i in [0...10]
	layer = new Layer
		width: accordion.width
		height: 60
		backgroundColor: Utils.randomColor(0.5)
	Utils.labelLayer layer, "#{i+1}"
	accordion.addItem layer, 200
```
## Sample Framer.js Project
* [accordion.framer](https://framer.cloud/tIdTw)
