# TabBar
Framer component that creates a Material-Design style tab bar, which scrolls if necessary.

Framer sample: < COMING SOON >


## Getting Started

If you have Modules installed, or want to use Modules to add this module to you project, click the badge below.

< LINK TO COME >

Note that you can hit Ctrl+C in Modules (when TabBar is the active module) to copy a code example that you can then paste into your file. 

If you are not using Modules, download `tabbar.coffee`, place it in the `/modules` folder of your project, and in your coffeescript file, include the following.

`{TabBar} = require "tabbar"`

## Creating a TabBar
The following creates a TabBar instance with five items, with the second one selected by default:
```
tabBar = new TabBar
	tabLabels: ["WESTWORLD","THE SOPRANOS", "OZ" , "GAME OF THRONES", "TRUE BLOOD"]
	selectedTabIndex: 1 
```
### Constructor Properties
* **tabLabels**: an array of strings that will be the labels of the menu items
* **selectedTabIndex**: the zero-based index of the tab you want selected (default: 0)
* **minimumPadding**: the minimum padding on either side of the tab text. If the width of the TabBar instance is less then the combined width of all tabs, then this minimum padding will be utilized and the tabs will scroll; otherwise, the padding of each tab increases automatically so the tabs fill the width of the TabBar instance (default: 8)
* **firstLastTabInset**: the inset between the left/right end of the TabBar instance and the first/last tab. (default: 5).
* **animationOptions**: the speed and curve of tab animation, which is used for the movement of the selection line, the scrolling of the tabs, and the changing of the selected/deselected tab states (default: time: 0.275, curve: Bezier.ease)
* **font**: the font for the tab labels (default: Utils.loadWebFont "Roboto"). This is read-only after the instance is created.
* **fontSize**: the font size for the tab labels (default: 15). This is read-only after the instance is created.
* **selectedColor**: the color of the tab text when it's selected (default: "white"). This is read-only after the instance is created.
* **deselectedColor**: the color of the tab text when it's deselected (default: "rgba(255, 255, 255, 0.7)". This is read-only after the instance is created.

## Adding tab pages (optional)
You can add "pages" (layers, or Frames from Design) that correspond to each tab by adding them to the `tabContent` layer of the `TabBar` instance. (The `tabContent` layer is created only if you choose to do this.) The order in which the layers are added corresponds to the order of the tabs. So the first layer you add will be displayed when you choose the first tab, etc.  If you use `tabContent`, you must have the same number of pages as you have tabs.

The following will add the the layers "layer1" through "layer5" to the TabBar instance `tabBar`:
```
pages = ["layer1", "layer2", "layer3", "layer4", "layer5"]
for page in pages
	tabBar.tabContent.addPage page
 ```
## Selecting a tab (through code) 
You can select a tab either through the layer that represents the tab (if for some reason you have a reference to it) or - more likely - by the tab's (zero-based) index, by using tabBar.selectTab(value).

### selectTab(value, animated)

* **value**: either the zero-based index of the desired tab, or the layer that makes up the tab.
* **animated**: (boolean) `true` if you want the tabs to animate when you choose the tab, or `false` if not. Default is `true`

Examples
```
tabBar.selectTab 0, false  # select the first tab without animating
tabBar.selectTab tabBar.content.children[0]  # select the first tab with animation
```
You can also select a tab by setting the selectedTabIndex property. The tabs will animate:
```
tabBar.selectedTabIndex = 0  # select the first tab
```

## Useful Properties
Here are useful properties when dealing with a TabBar instance.
### tabBar.currentTab 
The layer that contains the current tab in the tabBar instance.
### tabBar.currentTabIndex
The zero-based index of the currently selected tab.
### tabBar.tabContent
The layer - created if accessed - containing "pages" (layer, or frames from Design) that correspond to the tabs in the TabBar instance.
### tabBar.tabContent.currentPageIndex
The zero-based index of the current page in the TabBar.tabContent instance.
### tabBar.tabContent.currentPage
The layer of the  current page in the TabBar.tabContent instance.
## Responding to Events
### tabBar.on "change:tab"
Upon selecting a tab (either manually or though code), the "change:tab" message is emitted, which is handled as such:
```
tabBar.on "change:tab", (currentTab, priorTab, target) ->
```
* **currentTab**: an object representing the tab that was chosen, containing three properties:
	* **index**: the zero-based index of the tab
	* **text**: the text in the label of the tab
	* **layer**: the layer that makes up the tab

* **priorTab**: an object representing the tab that had been chosen previously, containing three properties:
	* **index**: the zero-based index of the tab
	* **text**: the text in the label of the tab
	* **layer**: the layer that makes up the tab

* **target**: this returns the TabBar instance itself.
  
For example, to print the text of the tab label of the selected tab:
```
tabBar.on "change:tab", (currentTab, priorTab, target) ->
	print currentTab.text
```
### tabBar.tabContent.on "change:page"
Similar to the `change:tab` message above, the tabContent layer of the TabBar instance emits a message when it displays a new page:
```
tabBar.tabContent.on "change:page", (currentPage, priorPage, target) ->
```
* **currentPage**: an object representing the page that is newly displayed, containing two properties
 	* **index**: the zero-based index of the page
 	* **layer**: the layer of the selected page
  
* **priorPage**: an object representing the page that had been displayed prior to the new selection, containing two properties
	* **index**: the zero-based index of the page
	* **layer**: the layer of the selected page

* **target**" the tabBar.tabContent layer itself

For example, to get a reference to the layer of the page that was just selected: 
```
tabBar.tabContent on "change:page", (currentPage, priorPage, target) ->
	tabLayer = currentPage.layer
```
## Code Sample
```
# create tabBar instance
tabBar = new TabBar
	tabLabels: ["WESTWORLD","THE SOPRANOS", "OZ" , "GAME OF THRONES", "TRUE BLOOD"] 
	height: 52
	fontSize: 17
	
pages = [westworld, sopranos, oz, got, trueblood] # an array of layers/frames created elsewhere
for page in pages
	tabBar.tabContent.addPage page
```
