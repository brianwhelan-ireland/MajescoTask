@isTest
public with sharing class AccountTriggerHandlerTest {

    private static Contact makeSalesContact(String name)
    {
        Contact newContact = new Contact(LastName = name, MarketingBudget__c = false, SalesBudget__c = true);
        return newContact;
    }

    private static Contact makeContact(String name, Boolean isMarketing,Boolean isSales)
    {
        Contact newContact = new Contact(LastName = name, MarketingBudget__c = isMarketing, SalesBudget__c = isSales);
        return newContact;
    }

    private static Account makeAccount(String accountName)
    {
        Account newAccount = new Account(Name = accountName);
        return newAccount;
    }
    
    @TestSetup
    static void makeData()
    {
        Account mainAccount = makeAccount('Main Account 1');

        insert mainAccount;

        List<Contact> contactList = new List<Contact>();

        contactList.add(makeContact('Contact 1',true,false));
        contactList.add(makeContact('Contact 2',true,true));
        contactList.add(makeContact('Contact 3',false,true));
        contactList.add(makeContact('Contact 4',false,true));
        contactList.add(makeContact('Contact 5',false,false));

        for(Contact myContact : contactList)
        {
            myContact.AccountId = mainAccount.Id;
        }

        insert contactList;

        //Bulk test data

        Integer batchSize = 400;
        Integer doubleBatchSize = batchSize * 2;

        List<Account> bulkAccounts = new List<Account>();
        while(bulkAccounts.size() < batchSize)
        {
            bulkAccounts.add(makeAccount('bulkAccount_'+bulkAccounts.size()));
        }

        insert bulkAccounts;

        List<Contact> bulkSalesContacts = new List<Contact>();
        while(bulkSalesContacts.size() < doubleBatchSize )
        {
            Contact newContact = makeSalesContact('bulkSalesContact_' + bulkSalesContacts.size());
            newContact.AccountId = bulkAccounts[MATH.mod(bulkSalesContacts.size(),batchSize)].Id;    
            bulkSalesContacts.add(newContact);
        }

        insert bulkSalesContacts;


    }

    @isTest
    static void basicCheckPositive()
    {
        Account testAccount = [SELECT Id, Budget__c FROM Account WHERE Name = 'Main Account 1'][0];

        testAccount.Budget__c = 100.00;
        
        Test.startTest();
        
        update testAccount;

        Test.stopTest();

        List<Contact> postUpdateContacts = [SELECT Id,Name, Budget__c FROM Contact WHERE Name = 'Contact%'];

        for(Contact currentOuterContact : postUpdateContacts)
        {
            switch on currentOuterContact.Name {
                when 'Contact 1' {
                    System.assertEquals(20.00, currentOuterContact.Budget__c, 'Allocation for Contact 1 is incorrect');
                }
                when 'Contact 2' {
                    System.assertEquals(40.00, currentOuterContact.Budget__c, 'Allocation for Contact 2 is incorrect');
                }
                when 'Contact 3' {
                    System.assertEquals(20.00, currentOuterContact.Budget__c, 'Allocation for Contact 3 is incorrect');
                }
                when 'Contact 4' {
                    System.assertEquals(20.00, currentOuterContact.Budget__c, 'Allocation for Contact 4 is incorrect');
                }
                when 'Contact 5' {
                    System.assertEquals(0.00, currentOuterContact.Budget__c, 'Allocation for Contact 5 is incorrect');
                }
             }
            
        }
        
    }


    @isTest
    static void basicCheckNegativeAmount()
    {
        Account testAccount = [SELECT Id, Budget__c FROM Account WHERE Name = 'Main Account 1'][0];

        testAccount.Budget__c = -100.00;
        
        Test.startTest();
        
        update testAccount;

        Test.stopTest();

        List<Contact> postUpdateContacts = [SELECT Id,Name, Budget__c FROM Contact];

        for(Contact currentContact : postUpdateContacts)
        {
            System.assertEquals(null, currentContact.Budget__c, 'Allocation for a Contact is incorrect: Should be Null');
        }
        
    }

    @isTest
    static void bulkCheckSalesFiguresMatch()
    {
        List<Account> testAccounts = [SELECT Id, Name, Budget__c FROM Account WHERE Name LIKE 'bulkAccount_%'];

        List<Contact> postUpdateContactstest = [SELECT Id, Name, AccountId, Budget__c, MarketingBudget__c, SalesBudget__c FROM Contact];

        for(Account testAccount : testAccounts)
        {
            Decimal myBudget = (Decimal)(MATH.random() * 100000);
            testAccount.Budget__c = myBudget.setScale(2,System.RoundingMode.HALF_DOWN);
        }
        
        Test.startTest();
        
        update testAccounts;

        Test.stopTest();

        //checking sales adds up correctly
        Account salesTestAccount = [SELECT Id, Name, Budget__c FROM Account WHERE Id = :testAccounts[100].Id LIMIT 1][0];
        List<Contact> salesContacts = [SELECT Id, Name, AccountId, Budget__c, MarketingBudget__c, SalesBudget__c FROM Contact WHERE AccountId = :salesTestAccount.Id];

        system.debug('salesTestAccount ' + salesTestAccount);
        system.debug('salesContacts ' + salesContacts);

        Decimal salesTotal = 0.0;
        Decimal salesPortion = salesTestAccount.Budget__c * 0.6;

        for(Contact salesContact : salesContacts)
        {
            salesTotal += salesContact.Budget__c;
        }

        system.assertEquals(salesPortion.setScale(2,System.RoundingMode.HALF_DOWN), salesTotal, 'Sales Total Does not match');

    }

}
