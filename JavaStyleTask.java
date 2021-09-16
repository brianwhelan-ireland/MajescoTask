
package com.claimvantage.Style;
 
import java.io.*;
import java.util.*;

// Brian.Whelan 17/09/21
/*
    Please enjoy my comments on the following code -  Its been a long long time since i have interacted with 
    Java so I apologise for any easy mistakes I have made. Thank you for your time.
*/

public class UserManager {
    private HashMap<String, String> fullNames; //this is not a clear name for what this map is going to be used for. would personally call this username2Fullnames.
 
    public UserManager(final int InitialCapacity) {
        super();
        this.fullNames = new HashMap<String, String>(InitialCapacity); // 'this' is not required here. also learned something new about hashmaps becasue of this!
    }
 
    public void add(final String username, final String fullName) { //should not have username and fullName - Either userName/fullName or username/fullname.
        this.fullNames.put(username, fullName); // 'this' is not required here.
    }
 
    public boolean hasUser(final String username) { //this whole method could just be a single return statement of 'return fullNames.containsKey(username);'. KISS principal. 
        if (this.fullNames.containsKey(username)) {
            return true;
        }
        else {
            return false;
        }
    }
 
    public void printUsernamesToFile(final File file) { //'File file' is cause for concern. Maybe call the param 'file2Write' or 'currentFile' 
        try {
            final Writer writer = new FileWriter(file); 
            //You wouldn't let someone created a HashMap called hashMap would you? 
            //From a readability standpoint calling this 'usernameWriter' would be clearer to me.
 
            Iterator<String> usernames = this.fullNames.keySet().iterator(); //I would use a more descriptive name for the Iterator than usernames - maybe usernames2Export? processUsernames?
            while (usernames.hasNext()) {
                final String username = usernames.next(); // why are we making this final? overkill? we require this value to change on each iteration.
                writer.write(username); //as mentioned - would change the name of the File Writer instance
            }
 
            writer.close();
        }
        catch (IOException e) { //empty catch statment? 
        }
    }
    
    /*
        what is the point and purpose of the following method? Is it to compare different UserManager instances full name list? If thats the case
        then we have some fundimenatal design and codebase issues here, as a class called UserManager should not be run in this regard. 
    */
 
    public boolean equals(Object o) { 
        if (o == null) {
        return false;  //if your going to have multiple return statements, at least have them at the same distance on the column 
        }
 
        if (!(o instanceof UserManager)) {
            return false;
        }
 
        final UserManager n = (UserManager) o; 
        return this.fullNames.equals(n.fullNames); 
        //'this.fullnames' should not be able to call this method 'equals', its just a HashMap!? while n.fullnames is an object, its not an instance of UserManger
        //even if for some reason this is correct - it will always just return false because of the 2 return statements
        
    }
}

