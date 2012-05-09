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


##Presentation
Objective REST is build to provide network capabilities to CoreData. This project is divide in two main part:

*The server: expose a ManagedObjectContext with a REST interface.
*The client: a custom AtomicStore who read and write data directly to the REST server (without caching system actually).

We haven't write any documentation at this time but we have a small demonstration based on a MP3 Player for OS X. To try it you have to run the server (who listen on TCP 1988), load some MP3 and then run the client. Before build and run the client you have to edit the value of ipdb_serverURL in the DataProvider. This URL is used at line 131 to initiate the NSPersistentStoreCoordinator.