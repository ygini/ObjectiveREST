#Objective REST

##License

This project is provide under the Apache License Version 2.0. You can read more about it in the LICENSE.md file.

##Notice
This project is based on different others projects who use their own license. You can read more about it in the NOTICE.md file.

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
    [RESTManager sharedInstance].mDNSDomain = @""; // Use the network provided domain for registration. It's "local." on standard network or anything else if we have Wide Area Bonjour
    [RESTManager sharedInstance].mDNSName = @""; // If empty, use the device name
    [RESTManager sharedInstance].mDNSType = @"_rest._tcp"; // Should be unique to your application, the format is _application._tcp
    
    [RESTManager sharedInstance].managedObjectModel = [AppDelegate sharedInstance].managedObjectModel;
    [RESTManager sharedInstance].persistentStoreCoordinator = [AppDelegate sharedInstance].persistentStoreCoordinator;
    [RESTManager sharedInstance].managedObjectContext = [AppDelegate sharedInstance].managedObjectContext;
    
    [[RESTManager sharedInstance] startServer];
    
    // That's all!

###Execute a request
####Configure the RESTClient

    [RESTClient sharedInstance].tcpPort = 0;
    [RESTClient sharedInstance].modelIsObjectiveRESTReady = NO;
    [RESTClient sharedInstance].tcpPort = [services port];
    [RESTClient sharedInstance].serverAddress = [services hostName];
    [RESTClient sharedInstance].contentType = @"application/x-bplist"; // Support also application/x-plist and application/json

####Get list of entities

    [[RESTClient sharedInstance] getPath:@"/"]];

####Get list of instance for specific entity

    [[RESTClient sharedInstance] getPath:@"/RCMessage"]];

####Get specific object
####Update specific object
####Create a object
####Get resume for a object
