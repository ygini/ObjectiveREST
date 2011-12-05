#Objective REST

##License

This project is provide under the Apache License Version 2.0. You can read more about it in the LICENSE.md file.

##Notice
This project is based on different others projects who use their own license. You can read more about it in the NOTICE.md file.

##Get and set ObjectiveREST

Be careful when you create your git clone, this project use submodule, so the best way to get your copy is:

    git clone --recursive https://github.com/ygini/ObjectiveREST.git

Or

    git clone https://github.com/ygini/ObjectiveREST.git
    git submodule init
    git submodule update

The most easiest method to use ObjectiveREST is to import the folder *ObjectiveREST/ObjectiveREST Frameworks/Common* in your project.

The most cleanest way to use ObjectiveREST is to import the good framework project in your workspace: *ObjectiveREST/ObjectiveREST Frameworks/* **[iOS | OS X]** */ObjectiveREST/ObjectiveREST iOS.xcodeproj*

For iOS and OS X application, you have to add the new imported framework in your dependancies then as a link target (Select your project in Xcode then the tab *build phases*).

###Special addition for iOS

Thanks to the really good management of library in iOS, you have to add this two options to your project's build settings

	OTHER_LDFLAGS = -ObjC
	HEADER_SEARCH_PATHS = $(TARGET_BUILD_DIR)/usr/local/include

You can simply copy this two line and past it in your build settings (Select your project in Xcode then the tab *build settings*, select any line and past).

The last step for iOS is to add CFNetwork framework to your link phase.

##Presentation
Objective REST is build to provide a REST interface to any CoreData application. We have two working mode :

* Standard model: you use your CoreData model as it is, no need if change, and you got a REST interface we basic functionality (see the appropriate section for more details).

* REST Ready model: you have to patch your CoreData model to add a custom UUID field and some method to get descriptions, comparator, etc. (see the appropriate section for more details).

To use Objective REST in your application, you have to setup the RESTManager shared instance. You need to pass all CoreData parts (model, store, context) and the server settings (TCP port, SSL certificate, users database…) and that's all. 

You have two demo application, one server and one client to see how it's work.

##Details

###Standard model

###REST Ready model

##Examples
###Configure the RESTManager

    [RESTManager sharedInstance].modelIsObjectiveRESTReady = NO;
    [RESTManager sharedInstance].authenticationDatabase = [NSDictionary dictionaryWithObject:@"password" forKey:@"username"];
    
    [RESTManager sharedInstance].tcpPort = 0; // Let the system choose the port
    [RESTManager sharedInstance].mDNSDomain = @""; // Use the network provided domain for registration. That's to say "local." on standard network or anything else if we have Wide Area Bonjour
    [RESTManager sharedInstance].mDNSName = @""; // If empty, use the device name
    [RESTManager sharedInstance].mDNSType = @"_rest._tcp"; // Should be unique to your application, the format is _application._tcp
    
    [RESTManager sharedInstance].managedObjectModel = [ICAppDelegate sharedInstance].managedObjectModel;
    [RESTManager sharedInstance].managedObjectContext = [ICAppDelegate sharedInstance].managedObjectContext;
    [RESTManager sharedInstance].persistentStoreCoordinator = [ICAppDelegate sharedInstance].persistentStoreCoordinator;
    
    [[RESTManager sharedInstance] startServer];
    

###Execute a request
####Configure the RESTClient

<<<<<<< HEAD
	[RESTClient sharedInstance].tcpPort = [_remoteService port];
	[RESTClient sharedInstance].serverAddress = [_remoteService hostName];
	[RESTClient sharedInstance].modelIsObjectiveRESTReady = NO;
	[RESTClient sharedInstance].contentType = [NSArray arrayWithObject:@"application/x-bplist"]; // Support also application/x-plist and application/json. You can use the const REST_SUPPORTED_CONTENT_TYPE to specify all standard supported method
=======
    [RESTClient sharedInstance].modelIsObjectiveRESTReady = NO;
    [RESTClient sharedInstance].tcpPort = [services port];
    [RESTClient sharedInstance].serverAddress = [services hostName];
    [RESTClient sharedInstance].contentType = [NSArray arrayWithObject:@"application/x-bplist"]; // Support also application/x-plist and application/json
>>>>>>> 16a857f48a954952c37266a98b57ac26cfe21989

####Get list of entities

    NSArray *restLinks = [[RESTClient sharedInstance] getPath:@"/"]];

The result look like:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>content</key>
		<array>
			<dict>
				<key>rest_ref</key>
				<string>http://192.168.232.1:54167/Message</string>
			</dict>
		</array>
	</dict>
	</plist>


####Get list of instance for specific entity
#####Standard Model

    NSArray *restLinks = [[RESTClient sharedInstance] getPath:@"/Message"]];

Give

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
    <key>content</key>
    	<array>
    		<dict>
    			<key>rest_ref</key>
    			<string>http://10.20.11.55:52625/x-coredata/D708F67A-3404-48B1-AEA3-389AC17BE550/Message/p1</string>
    		</dict>
    		<dict>
    			<key>rest_ref</key>
    			<string>http://10.20.11.55:52625/x-coredata/D708F67A-3404-48B1-AEA3-389AC17BE550/Message/p2</string>
    		</dict>
    		<dict>
    			<key>rest_ref</key>
    			<string>http://10.20.11.55:52625/x-coredata/D708F67A-3404-48B1-AEA3-389AC17BE550/Message/p3</string>
    		</dict>
    	</array>
    </dict>
    </plist>

#####REST Ready Model

    NSArray *restLinks = [[RESTClient sharedInstance] getPath:@"/FoodMenu"]];

Give

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>content</key>
		<array>
			<dict>
				<key>rest_ref</key>
				<string>http://127.0.0.1:1984/FoodMenu/5DC0E5F4-0191-4254-964A-8E7B1CE22524</string>
			</dict>
		</array>
	</dict>
	</plist>

Where 5DC0E5F4-0191-4254-964A-8E7B1CE22524 is the content of the field rest_uuid


####Get specific object
#####Standard Model

    NSArray *restLinks = [[RESTClient sharedInstance] getPath:@"/x-coredata/D708F67A-3404-48B1-AEA3-389AC17BE550/RCMessage/p3"]];

Or

    NSArray *restLinks = [[RESTClient sharedInstance] getAboslutePath:@"http://10.20.11.55:52625/x-coredata/D708F67A-3404-48B1-AEA3-389AC17BE550/Message/p3"]];

The result look like:

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
        <key>content</key>
    	<dict>
    		<key>date</key>
    		<date>2011-11-30T10:51:20Z</date>
    		<key>message</key>
    		<string>\o/</string>
    		<key>nickname</key>
    		<string>iPhone Simulator</string>
    	</dict>
    </dict>
    </plist>

#####REST Ready Model

    NSArray *restLinks = [[RESTClient sharedInstance] getPath:@"/FoodMenu/5DC0E5F4-0191-4254-964A-8E7B1CE22524"]];

The result look like:

	<?xml version="1.0" encoding="UTF-8"?>
	<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
	<plist version="1.0">
	<dict>
		<key>content</key>
		<dict>
			<key>content</key>
			<string>Here come the description</string>
			<key>foodNumber</key>
			<dict>
				<key>rest_ref</key>
				<string>http://127.0.0.1:1984/PhoneBookEntry/D05947AC-93A0-45A5-977B-7A0894B3B712</string>
			</dict>
			<key>name</key>
			<string>TEST</string>
			<key>price</key>
			<real>99.989997863769531</real>
			<key>rest_uuid</key>
			<string>5DC0E5F4-0191-4254-964A-8E7B1CE22524</string>
		</dict>
	</dict>
	</plist>


####Create a object

    [[RESTClient sharedInstance] postInfo:[NSDictionary dictionaryWithObject:objectInfo forKey:@"content"] toPath:@"/Message"]];

Here, objectInfo is a NSDictionary representing the object. It must use the same convention as the server. You could build it by your self or use the RESTManager:

    NSDictionary *objectInfo = [RESTManager dictionaryRepresentationWithServerAddress:[[RESTClient sharedInstance] hostInfo] forManagedObject:mo]

####Update specific object

    [[RESTClient sharedInstance] putInfo:[NSDictionary dictionaryWithObject:objectInfo forKey:@"content"] toPath:@"/x-coredata/D708F67A-3404-48B1-AEA3-389AC17BE550/RCMessage/p3"]];
    
We must specify the server information to build a correct REST link for relationship, but be careful with that, relationship base on client CoreData base used to update a server must use a REST Ready database, with internal UUID.

####Get resume for a object

No yet implemented, should be available soon but only for REST Ready database.
