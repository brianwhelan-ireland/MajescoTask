trigger AccountTrigger on Account (after insert, after update) 
{
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler(Trigger.newMap);
    
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert)
        {
            accountTriggerHandler.getRelatedContacts();
            accountTriggerHandler.performBudgetCalulation();
            accountTriggerHandler.updateContactsBudgets();
        }

        if(Trigger.isUpdate)
        {
            accountTriggerHandler.getRelatedContacts();
            accountTriggerHandler.performBudgetCalulation();
            accountTriggerHandler.updateContactsBudgets();
        }
        
    }

}