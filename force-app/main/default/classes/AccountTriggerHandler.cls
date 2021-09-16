public with sharing class AccountTriggerHandler 
{
    private final static Decimal SALES_PERCENTAGE = 0.6;
    private final static Decimal MARKETING_PERCENTAGE = 0.4;

    private final static String SALES = 'SALES';
    private final static String MARKETING = 'MARKETING';

    private Map<Id,Decimal> accounts2Budgets = new Map<Id,Decimal>();
    private Map<Id,List<Contact>> accounts2Contacts = new Map<Id,List<Contact>>();

    private List<Contact> contacts2Update = new List<Contact>();

    public AccountTriggerHandler(Map<Id,Account> triggeredAccounts)
    {
        for(Account singleAccount : triggeredAccounts.values())
        {
            if(singleAccount.Budget__c != null && singleAccount.Budget__c > 0.00)
            {
                accounts2Budgets.put(singleAccount.Id,singleAccount.Budget__c);
            }   
            
        }

    }

    public void getRelatedContacts()
    {
        if(accounts2Budgets.size() < 0)
        {
            return;
        }
        
        Map<Id,List<Contact>> myRelatedContactsMap = new Map<Id,List<Contact>>();
        
        List<Contact> contacts = [SELECT Id, Name, AccountId, Budget__c, MarketingBudget__c, SalesBudget__c FROM Contact WHERE AccountId IN :accounts2Budgets.keySet()];
        
        for(Contact currentContact : contacts)
        {
            if(myRelatedContactsMap.get(currentContact.AccountId) != null)
            {
                List<Contact> contactList2Increase = myRelatedContactsMap.get(currentContact.AccountId);
                contactList2Increase.add(currentContact);
                myRelatedContactsMap.put(currentContact.AccountId,contactList2Increase);
            }
            else
            {
                myRelatedContactsMap.put(currentContact.AccountId,new List<Contact>{currentContact});
            }
        }

        if(myRelatedContactsMap != null)
        {
            accounts2Contacts = myRelatedContactsMap;
        }
        
    }

    public void performBudgetCalulation()
    {
        for(Id currentAccount : accounts2Contacts.keySet())
        {
            Map<String,Decimal> departmentSplit = new Map<String,Decimal>();
            Map<String,Integer> departmentCount = new Map<String,Integer>();

            departmentSplit.put(SALES, getBudgetSplit(accounts2Budgets.get(currentAccount),SALES_PERCENTAGE));
            departmentSplit.put(MARKETING, getBudgetSplit(accounts2Budgets.get(currentAccount),MARKETING_PERCENTAGE));

            for(Contact currentContact : accounts2Contacts.get(currentAccount))
            {
                if(currentContact.SalesBudget__c)
                {
                    Integer currentSalesCount = departmentCount.get(SALES);

                    if(currentSalesCount != null)
                    {
                        departmentCount.put(SALES,++currentSalesCount);
                    }
                    else
                    {
                        departmentCount.put(SALES,1);
                    }  
                }

                if(currentContact.MarketingBudget__c)
                {
                    Integer currentMarketingCount = departmentCount.get(MARKETING);

                    if(currentMarketingCount != null)
                    {
                        departmentCount.put(MARKETING,++currentMarketingCount);
                    }
                    else
                    {
                        departmentCount.put(MARKETING,1);
                    }  
                }
            }

            for(Contact currentContact : accounts2Contacts.get(currentAccount))
            {
                if(currentContact.SalesBudget__c && currentContact.MarketingBudget__c)
                {
                    Decimal sell,market;
                    sell = getContactCut(departmentSplit.get(SALES),departmentCount.get(SALES));
                    market = getContactCut(departmentSplit.get(MARKETING),departmentCount.get(MARKETING));

                    currentContact.Budget__c = sell + market;
                    contacts2Update.add(currentContact);

                }
                else if(currentContact.SalesBudget__c && !currentContact.MarketingBudget__c)
                {
                    currentContact.Budget__c = getContactCut(departmentSplit.get(SALES),departmentCount.get(SALES));
                    contacts2Update.add(currentContact);

                }
                else if(!currentContact.SalesBudget__c && currentContact.MarketingBudget__c)
                {
                    currentContact.Budget__c = getContactCut(departmentSplit.get(MARKETING),departmentCount.get(MARKETING));
                    contacts2Update.add(currentContact);
                }
            }

        }

    }

    public void updateContactsBudgets()
    {
        if(contacts2Update.size() > 0)
        {
            update contacts2Update;
        }
    }

    private Decimal getBudgetSplit(Decimal amount, Decimal split)
    {
        Decimal returnAmount = amount * split;
        return returnAmount;
    }

    private Decimal getContactCut(Decimal amount, Decimal contactCount)
    {
        Decimal returnAmount = amount / contactCount;
        return returnAmount.setScale(2,System.RoundingMode.HALF_DOWN);
    }
    
}
