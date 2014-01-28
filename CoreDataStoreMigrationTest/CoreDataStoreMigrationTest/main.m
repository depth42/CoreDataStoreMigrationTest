// CoreDataStoreMigrationTest
// Frank Illenberger
// illenberger@projectwizards.net
//
// Summary:
// Attribute values of managed objects fetched before a store migration cannot be accessed anymore after the original store instance has been released.
//
// Steps to reproduce:
// - Build and run the project CoreDataStoreMigrationTest with Xcode 5.0 under Mac OS 10.9.1
// - Check the run log
//
// Expected result:
// There should be no output from failed assertions in the run log.
//
// Actual result:
// The run log contains output like this:
//
// 2014-01-28 17:29:30.574 CoreDataStoreMigrationTest[78253:303] *** Assertion failure in void runTest()(), CoreDataStoreMigrationTest/main.m:69
// 2014-01-28 17:29:30.575 CoreDataStoreMigrationTest[78253:303] *** Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Person name is lost after store migration!'

void runTest();
NSURL* createTestDirectory();
NSManagedObjectModel* createModel();
void createStoreFileAtURLWithModel(NSURL* URL, NSManagedObjectModel* model);

int main(int argc, const char * argv[])
{
    @autoreleasepool {
        runTest();
    }
    return 0;
}

void runTest()
{
    NSURL* testDirectory = createTestDirectory();
    NSManagedObjectModel* model = createModel();

    NSURL* storeURL1 = [testDirectory URLByAppendingPathComponent:@"test1.store"];
    createStoreFileAtURLWithModel(storeURL1, model);

    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSManagedObject* person;
    @autoreleasepool {
        NSPersistentStore* store1 = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                      configuration:nil
                                                                URL:storeURL1
                                                            options:nil
                                                              error:NULL];
        NSManagedObjectContext* context = [[NSManagedObjectContext alloc] init];
        context.persistentStoreCoordinator = psc;

        NSFetchRequest* fetch = [[NSFetchRequest alloc] initWithEntityName:@"Person"];
        person = [context executeFetchRequest:fetch error:NULL][0];
        NSCAssert([[person valueForKey:@"name"] isEqualToString:@"Duffy Duck"], nil);

        NSURL* storeURL2 = [testDirectory URLByAppendingPathComponent:@"test2.store"];

        [psc migratePersistentStore:store1
                              toURL:storeURL2
                            options:nil
                           withType:NSSQLiteStoreType
                              error:NULL];
    }
    NSCAssert([[person valueForKey:@"name"] isEqualToString:@"Duffy Duck"], @"Person name is lost after store migration!");
}

NSURL* createTestDirectory()
{
    NSURL* URL = [[NSURL fileURLWithPath:NSTemporaryDirectory()] URLByAppendingPathComponent:@"CoreDataStoreMigrationTest"];
    NSFileManager* manager = NSFileManager.defaultManager;
    [manager removeItemAtURL:URL error:NULL];   // delete directory from previous run
    [manager createDirectoryAtURL:URL
      withIntermediateDirectories:YES
                       attributes:nil
                            error:NULL];
    return URL;
}

NSManagedObjectModel* createModel()
{
    NSAttributeDescription* nameAttribute = [[NSAttributeDescription alloc] init];
    nameAttribute.attributeType = NSStringAttributeType;
    nameAttribute.name = @"name";

    NSEntityDescription* personEntity = [[NSEntityDescription alloc] init];
    personEntity.name = @"Person";
    personEntity.properties = @[nameAttribute];

    NSManagedObjectModel* model = [[NSManagedObjectModel alloc] init];
    model.entities = @[personEntity];
    return model;
}

void createStoreFileAtURLWithModel(NSURL* URL, NSManagedObjectModel* model)
{
    NSCParameterAssert(URL);
    NSCParameterAssert(model);

    NSPersistentStoreCoordinator* psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSManagedObjectContext* context = [[NSManagedObjectContext alloc] init];
    context.persistentStoreCoordinator = psc;

    NSPersistentStore* store = [psc addPersistentStoreWithType:NSSQLiteStoreType
                                                 configuration:nil
                                                           URL:URL
                                                       options:nil
                                                         error:NULL];
    NSCAssert(store, nil);

    NSManagedObject* person = [NSEntityDescription insertNewObjectForEntityForName:@"Person"
                                                            inManagedObjectContext:context];
    [person setValue:@"Duffy Duck" forKey:@"name"];

    BOOL success = [context save:NULL];
    NSCAssert(success, nil);
}
