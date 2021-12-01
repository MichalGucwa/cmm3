# $Id: profile.tcl,v 1.8 2010/01/21 16:02:25 rmk65 Exp $
package provide userprofile 1.0

class UserProfile {

    private variable recent_sessions {}

    private method pruneRecentSessions

    public method getRecentSessions
    public method addRecentSession

    constructor { a_file } { }
}

body UserProfile::constructor { a_file } {
    showHistory
