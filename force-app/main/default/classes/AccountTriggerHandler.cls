public without sharing class AccountTriggerHandler 
{
    private final static Decimal SALES_PERCENTAGE = 0.6;
    private final static Decimal MARKETING_PERCENTAGE = 0.4;

    private final static String SALES = 'SALES';
    private final static String MARKETING = 'MARKETING';
    private final static String FULL = 'FULL';

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
        Map<Id,List<Contact>> myRelatedContactsMap;
        
        List<Contact> contacts = [SELECT Id, AccountId, Budget__c, MarketingBudget__c, SalesBudget__c FROM Contact WHERE AccountId IN :accounts2Budgets.keySet()];
        
        for(Contact currentContact : contacts)
        {
            if(myRelatedContactsMap.get(currentContact.AccountId) == null)
            {
                myRelatedContactsMap.put(currentContact.AccountId,new List<Contact>{currentContact});
            }
            else
            {
                List<Contact> contactList2Increase = myRelatedContactsMap.get(currentContact.AccountId);
                contactList2Increase.add(currentContact);
                myRelatedContactsMap.put(currentContact.AccountId,contactList2Increase);
            }
        }

        accounts2Contacts = myRelatedContactsMap;
    }

    public void performBudgetCalulation()
    {
        if(accounts2Budgets.size() != accounts2Contacts.size())
        {
            return;
        }

        for(Id currentAccount : accounts2Contacts.keySet())
        {
            Map<String,Integer> contactTypeBreakdown = new Map<String,Integer>();
            Map<String,Decimal> departmentSplit = new Map<String,Integer>();

            departmentSplit.put(FULL, accounts2Budgets.get(currentAccount));
            departmentSplit.put(SALES, getBudgetSplit(accounts2Budgets.get(currentAccount),SALES_PERCENTAGE));
            departmentSplit.put(MARKETING, getBudgetSplit(accounts2Budgets.get(currentAccount),MARKETING_PERCENTAGE));

            for(Contact currentContact : accounts2Contacts.get(currentAccount))
            {
                
                if(contactTypeBreakdown.get(getContactType(currentContact)) != null)
                {
                    contactTypeBreakdown.put(getContactType(currentContact), 1);
                }
                else
                {
                    Integer tempUpdate = contactTypeBreakdown.get(getContactType(currentContact));
                    contactTypeBreakdown.put(getContactType(currentContact), ++tempUpdate);
                }
            }

            for(Contact currentContact : accounts2Contacts.get(currentAccount))
            {
                Integer contactCount = contactTypeBreakdown.get(getContactType(currentContact));
                Decimal departmentAmount = departmentSplit.get(getContactType(currentContact));
                
                if(departmentAmount != null && departmentAmount > 0.0)
                {
                    currentContact.Budget__c = getContactCut(departmentAmount,contactCount);
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
        return returnAmount.round(System.RoundingMode.FLOOR);
    }

    private Decimal getContactCut(Decimal amount, Decimal contactCount)
    {
        return amount / contactCount;
    }

    private String getContactType(Contact currentContact)
    {
        if(currentContact.MarketingBudget__c && currentContact.SalesBudget__c)
        {
            return FULL;
        }
        else if(currentContact.MarketingBudget__c)
        {
            return MARKETING;
        }
        else if(currentContact.SalesBudget__c)
        {
            return SALES;
        }
        else
        {
            return 'NONE';    
        }
    }
    
}
