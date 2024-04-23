/**
 * Created by Brian.Armstrong on 2020-11-10.
 */

global class OrgEmailEvent_Helper {

    private final string TAG_LINE = 'Powered by Org Email Event';
    private final string TAG_LINE_HTML = '🚀 Powered by Org™ Email Event ⚡';
    private final string BRANDING = '/n' + TAG_LINE;
    private final string BRANDING_HTML = '<p style="font-size: 9px !important;">' + TAG_LINE_HTML + '</p>';

    public static final decimal DEBUG_FALSE = 0;
    public static final decimal DEBUG_TRUE = 1;
    public static final decimal DEBUG_ALLOWED = 3;

    public enum EmailPriority {Highest, High, Normal, Low, Lowest}

    // Used for debugging.
    public boolean showEventInfoInSubject; // Show info about the event in the subject.
    public boolean showEventInfoInBody;   // Show info about the event in the body.
    public boolean showEventsInfoInBody;  // Show info about all the events.

    // Organization Wide Addresses on Production.
    private static final List <String> systemFromEmailAddresses = new List<String>{'Some.Admin@company.com'};  //  Used in Platform events were there is no user.
    private Id systemOrgWideEmailAddressId;
    private Map<String, Id> orgWideEmailAddresses = new Map<String,Id>();

    // Used for debugging.
    private string eventsInfo; // A string with info about all the events.

    // List of emails.
    private List<Messaging.Email> emails;

    // Save the time that we enter the function.
    private Long enterTimeMS;

    @TestVisible boolean testThrowException = false;
    @TestVisible String testCcEmailAddress = '';
    @TestVisible String testBccEmailAddress = '';

    // Constructor.
    global OrgEmailEvent_Helper() {
        showEventInfoInSubject = False;
        showEventInfoInBody = False;
        showEventsInfoInBody = True;

        eventsInfo = '';

        emails = null;
    }

    /**
    * Create a string with information from all the email events.
    *
    * @param emailEvents
    *
    * @return string.
    */
    private string EventsInfoString(List<VC_Email_Event__e> emailEvents) {

        integer eventsSize = emailEvents.size();

        String eventUUids = 'EventUuid (' + eventsSize + '){';
        String replayIds = 'ReplayId (' + eventsSize + '){';
        String bodyLengths = 'BodyLength (' + eventsSize + '){';

        String endSyntax;
        Integer iPlusOne;
        for(Integer i = 0; i < eventsSize; i++) {
            iPlusOne = i + 1;
            endSyntax = (iPlusOne < eventsSize ? ', ' : '}');
            eventUUids = eventUUids + iPlusOne + '=' + emailEvents[i].EventUuid + endSyntax;
            replayIds = replayIds + iPlusOne + '=' + emailEvents[i].ReplayId + endSyntax;
            bodyLengths = bodyLengths + iPlusOne + '=' + (String.isNotBlank(emailEvents[i].Body__c) ? emailEvents[i].Body__c.length() : 0) + endSyntax;
        }
        return eventUUids + ', ' + replayIds + ', ' + bodyLengths;
    }


    /**
    * Information about the event that can be shown in the subject.
    *
    * @param event
    * @param count
    * @param total
    *
    * @return string.
    */
    private string SubjectEventInfoString(VC_Email_Event__e event, integer count, integer total) {
        return '[Event:' + count + '/' + total + '] ';
    }


    /**
    * Information about a single event that can be shown in the body.
    *
    * @param event
    * @param count
    * @param total
    *
    * @return string.
    */
    private string BodyEventInfoString(VC_Email_Event__e event, integer count, integer total) {
        return (event.HTML_Body__c ? '<p>' : '\n') +
                'Org Email Event(s): event #' + count + ' of ' + total +
                //' (start=' + enterTimeMS + ' ms) ' +
                ' {EventUuid=' + event.EventUuid +
                ', ReplayId=' + event.ReplayId +
                ', CreatedDate='  + (null != event.CreatedDate ? event.CreatedDate.getTime() : 0) + ' ms' +
                ', BodyLength=' + (String.isNotBlank(event.Body__c) ? event.Body__c.length() : 0) + ' bytes' +
                ', Debug=' + (null != event.Debug__c ? event.Debug__c : null) +
                ', Options=' + (null != event.Options__c ? event.Options__c : null) +
                ', Branding=' + (null != event.Branding__c ? event.Branding__c : null) +
                (event.HTML_Body__c ? '}</p><p>' : '}\n') +
                (showEventsInfoInBody ? eventsInfo : '') +
                (event.HTML_Body__c ? '</p>' : '\n');
    }

    /**
    *  Update the email subject with a count of the emails created.
    */
    /*
    private void EmailsStatusInfo(){
        if (null == emails || 0 == emails.size())
            return;

        for(Integer i = 0; i < emails.size(); i++) {
            emails[i].setSubject('[E:' + (i+1) + '/' + emails.size() + '] ' + emails[i].getSubject());
        }
    }
    */

    /**
    * Parse the email addresses passed and build a list addresses.
    *
    * @param emailAddresses - String of email addresses.
    * @param defaultAddress - Default email address.
    *
    * @return List<String>.
    */
    private List<String> ParseEmailAddresses(String emailAddresses, String defaultEmailAddress) {

        List<String> Addresses = null;
        //System.debug('emailAddresses: ' + emailAddresses);
        if (String.isNotBlank(emailAddresses)){
            if (emailAddresses.contains(';')) {
                Addresses = emailAddresses.split(';');
            } else {
                Addresses = new List<String>{emailAddresses};
            }
        } else {
            if (String.isNotBlank(defaultEmailAddress)) {
                Addresses = new List<String>{defaultEmailAddress};
            }
        }
        //System.debug('Addresses: ' + Addresses);

        return Addresses;
    }

    /**
    * Query the OrgWideEmailAddress.
    *
    * @param emailAddress
    *
    * @return OrgWideEmailAddress[].
    */
    private OrgWideEmailAddress[] QueryOrgWideEmailAddress(string emailAddress) {
        OrgWideEmailAddress[] owea = [select Id, Address from OrgWideEmailAddress where Address =: emailAddress];
        return owea;
    }

    /**
    * Process all the email events by creating emails.
    *
    * @param emailEvents - List of email events.
    */
    global void ProcessEmailEvents(List<VC_Email_Event__e> emailEvents) {
        try {
            eventsInfo = '';

            // Save the time that we enter the function.
            enterTimeMS = System.now().getTime();

            // Test class logic to test the exception logic at the end of the function.
            if (testThrowException) {
                //System.debug('Test class logic to throw exception');
                throw new MathException();
            }

            // Check that there is at least 1 emailEvent otherwise exit the method.
            if (null == emailEvents || 0 == emailEvents.size())
                return;

            //OrgWideEmailAddress[] owea = [select Id, Address from OrgWideEmailAddress where Address =: systemFromEmailAddress];
            OrgWideEmailAddress[] owea = QueryOrgWideEmailAddress(systemFromEmailAddress);
            if (owea.size() > 0 ) {
                systemOrgWideEmailAddressId = owea.get(0).Id;
                orgWideEmailAddresses.put(systemFromEmailAddress, systemOrgWideEmailAddressId);
            }

            // Create a list for the emails.
            emails = new List<Messaging.Email>();

            Integer total = emailEvents.size();
            Integer count = 0;

            //System.debug('emailEvents.size(): ' + emailEvents.size());
            for (VC_Email_Event__e emailEvent : emailEvents) {

                Boolean showDebugSubject = showEventInfoInSubject;
                Boolean showDebugBody = showEventInfoInBody;
                if (null != emailEvent.Debug__c) {
                    if (DEBUG_FALSE == emailEvent.Debug__c) {
                        showDebugSubject = false;
                        showDebugBody = false;
                    } else if(DEBUG_TRUE == emailEvent.Debug__c) {
                        showDebugSubject = true;
                        showDebugBody = true;
                    } else if(DEBUG_ALLOWED == emailEvent.Debug__c) {
                        // leave the default settings.
                    }
                }

                count++;

                string eventOptions;
                if (String.isNotBlank(emailEvent.Options__c)){
                    eventOptions = emailEvent.Options__c;
                }

                Id orgWideEmailAddressId = systemOrgWideEmailAddressId;
                //System.debug('emailEvent.From_Addresses__c: '+ emailEvent.From_Addresses__c);
                if (String.isNotBlank(emailEvent.From_Addresses__c)) {
                    string fromAddress = emailEvent.From_Addresses__c;
                    // if from address is an email address.
                    if (fromAddress.contains('@')) {
                        if (orgWideEmailAddresses.containsKey(fromAddress)) {
                            orgWideEmailAddressId = orgWideEmailAddresses.get(fromAddress);
                        } else {
                            // Get the org wide email address for the email address passed.
                            //owea = [select Id, Address from OrgWideEmailAddress where Address = :fromAddress];
                            owea = QueryOrgWideEmailAddress(fromAddress);
                            if (owea.size() > 0 ) {
                                orgWideEmailAddressId = owea.get(0).Id;
                                orgWideEmailAddresses.put(fromAddress, orgWideEmailAddressId);
                            }
                        }
                    } else {
                        try {
                            // Make sure the from address is an id.
                            orgWideEmailAddressId = Id.valueOf(emailEvent.From_Addresses__c);
                        }
                        catch (StringException e) {
                            System.debug(e.getMessage());
                        }
                    }
                }
                //System.debug('orgWideEmailAddressId: '+ orgWideEmailAddressId);

                List<String> toAddresses = ParseEmailAddresses(emailEvent.To_Addresses__c, systemFromEmailAddress);
                //System.debug('toAddresses: ' + toAddresses);

                List<String> ccAddresses = ParseEmailAddresses(testCcEmailAddress/*emailEvent.Cc_Addresses__c*/, '');
                //System.debug('ccAddresses: ' + ccAddresses);

                List<String> bccAddresses = ParseEmailAddresses(testBccEmailAddress/*emailEvent.Bcc_Addresses__c*/, '');
                //System.debug('bccAddresses: ' + bccAddresses);

                string subjectEventInfo;
                if (showDebugSubject) {
                    subjectEventInfo = SubjectEventInfoString(emailEvent, count, total);
                }
                string bodyEventInfo;
                if (showDebugBody) {
                    bodyEventInfo = BodyEventInfoString(emailEvent, count, total);
                    if (showEventsInfoInBody && String.isBlank(eventsInfo)) {
                        eventsInfo = EventsInfoString(emailEvents);
                    }
                }

                // Do we want to add a branding message to the email.
                string brandingMessage = '';
                if (emailEvent.Branding__c) {
                    if (emailEvent.HTML_Body__c)
                        brandingMessage = BRANDING_HTML;
                    else
                        brandingMessage = BRANDING;
                }

                // Build the basic email message.
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();

                email.setOrgWideEmailAddressId(orgWideEmailAddressId);  //  Set the From address.

                if (null != toAddresses) { // Set the To addresses.
                    email.setToAddresses(toAddresses);
                }
                if (null != ccAddresses) { // Set the cc addresses.
                    email.setCcAddresses(ccAddresses);
                }
                if (null != bccAddresses) { // Set the bcc addresses.
                    email.setbccAddresses(bccAddresses);
                }

                // Set the email subject.
                if (showDebugSubject) {
                    email.setSubject(subjectEventInfo + emailEvent.Subject__c);
                } else {
                    email.setSubject(emailEvent.Subject__c);
                }

                // Set the email body.
                if (emailEvent.HTML_Body__c) {
                    if (showDebugBody) {
                        email.setHTMLBody(emailEvent.Body__c + bodyEventInfo + brandingMessage);
                    } else {
                        email.setHTMLBody(emailEvent.Body__c + brandingMessage);
                    }
                } else {
                    if (showDebugBody) {
                        email.setPlainTextBody(emailEvent.Body__c + bodyEventInfo + brandingMessage);
                    } else {
                        email.setPlainTextBody(emailEvent.Body__c + brandingMessage);
                    }
                }

                email.emailPriority = EmailPriority.Normal.name();
                email.bccSender = false;
                email.saveAsActivity = false;
                email.useSignature = false;

                emails.Add(email);
            }

            // System.debug('emails(' + emails.size() + '): ' + emails);
            // If there are any emails to send.
            if (emails.size() > 0) {
                List<Messaging.SendEmailResult> results = Messaging.sendEmail(emails, false);
                //System.debug('results: ' + results);
                for(Messaging.SendEmailResult result : results) {
                    if (!result.isSuccess()) {
                        System.StatusCode statusCode = result.getErrors()[0].getStatusCode();
                        String errorMessage = result.getErrors()[0].getMessage();
                        System.debug('OrgEmailEvent_Helper, Messaging.sendEmail Failed, StatusCode: ' + statusCode + ' Message: ' + errorMessage);
                    }
                }
            }

        }
        catch(Exception e) {
            String s = 'Exception in class: OrgEmailEvent_Helper, method: ProcessEmailEvents' +
                    ', Message: ' + e.getMessage() +
                    ', Line Number: ' + e.getLineNumber() +
                    ', Stack Trace: ' + e.getStackTraceString();
            System.debug(s);
        }

    }
}