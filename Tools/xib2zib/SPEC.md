This program will read an Xcode .xib file and produce a much-simplified
.zib file which will reference the actual classes that Azoth provides

Top level objects are:

"File's owner"	-> whatever is passed as owner into loadNibNamed:owner:options
 - for a brand new application, it is usually the AZApplication, with a link
   to the app-delegate. For a ViewController, it'll be the view controller 
   itself.
   
"Menu" -> constructs a menu hierarchy

"window" -> bunch of properties
	"view" -> bunch of properties
		"subviews" -> bunch of properties

customView -> list of views, with their subviews


each object has a 'connections' property, to show linked connections
	- call set<property> for each property on the target at reconstruction

read/write resulting "ZIB" file via NSKeyedArchiver to serialise
 (or serialise to JSON, then compress in memory and write...)
