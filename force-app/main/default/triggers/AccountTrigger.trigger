trigger AccountTrigger on Account (after insert, after update) 
{
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler(Trigger.newMap);
    
    if(Trigger.isAfter)
    {
        if(Trigger.isInsert && Trigger.isUpdate)
        {
            accountTriggerHandler.getRelatedContacts();
            accountTriggerHandler.performBudgetCalulation();
            accountTriggerHandler.updateContactsBudgets();
        }
        
    }

}