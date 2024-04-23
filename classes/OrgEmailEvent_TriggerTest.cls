/**
 * Created by Brian.Armstrong on 2022-03-14.
 */
// Test class for the OrgEmailEvent_Trigger class.

@IsTest
private class OrgEmailEvent_TriggerTest {

    Static Id orgWideEmailId; 

    static testMethod void TestHelperConstructor() {
        OrgEmailEvent_Helper helper = new OrgEmailEvent_Helper();
        System.assertNotEquals(null, helper);
        System.assertNotEquals(null, helper.showEventInfoInSubject);
        System.assertNotEquals(null, helper.showEventInfoInBody);
        System.assertNotEquals(null, helper.showEventsInfoInBody);

        try {
            helper = new OrgEmailEvent_Helper();
        }
        catch (Exception e) {
        }
    }

    static Org_Email_Event__e CreateEmailEvent(string fromAddress, string toAddress, string subject, string body, boolean htmlBody) {
        Org_Email_Event__e event = new Org_Email_Event__e();
        event.From_Addresses__c = fromAddress;
        event.To_Addresses__c = toAddress;
        event.Subject__c = subject;
        event.Body__c = body;
        event.HTML_Body__c = htmlBody;
        //event.Debug__c = null;
        event.Options__c = 'tag=true';
        //event.Branding__c = false;
        return event;
    }

    // Publish events to call the event trigger.
    static testMethod void TestTrigger()
    {
        Test.StartTest();

        QueryOrgWideEmail();

        Org_Email_Event__e event1 = new Org_Email_Event__e();
        event1.From_Addresses__c = orgWideEmailId;  // some.admin@company.com in the Organization Wide Addresses.
        event1.To_Addresses__c = 'some.user@company.com';
        event1.Subject__c = 'SSOJitHandler.updateUser - test@abcd.org';
        event1.Body__c = '<p>Org Id: 00D40000000ABCDEAE, Production, Time: 2020-04-29 16:00:53 GMT, Local: 2020-04-29 16:00:53 GMT /n User Id: 0054000000ABCDAA0, User name: admin@company.com, Time zone: Pacific Standard Time</p>';
        event1.HTML_Body__c = true;
        Database.SaveResult sr = EventBus.publish(event1);
        System.assertEquals(true, true);

        Org_Email_Event__e event2 = new Org_Email_Event__e ();
        event2.From_Addresses__c = orgWideEmailId;  // some.admin@company.com in the Organization Wide Addresses.
        event2.To_Addresses__c = 'some.user@company.com';
        event2.Subject__c = 'SSOJitHandler.createUser - test@abcd.com - SAML assertion';
        event2.Body__c = 'Org Id: 00D40000000ABCDEAE, Production, Time: 2020-04-29 16:00:53 GMT, Local: 2020-04-29 16:00:53 GMT /n User Id: 0054000000ABCDAA0, User name: admin@company.com, Time zone: Pacific Standard Time';
        event2.HTML_Body__c = false;
        EventBus.publish(event2);
        System.assertEquals(true, true);

        Org_Email_Event__e event3 = new Org_Email_Event__e ();
        event3.From_Addresses__c = 'some.admin@company.com';
        event3.To_Addresses__c = 'some.user@company.com;some.admin@company.com';
        event3.Subject__c = 'SSOJitHandler.createUser - test@abcd.com - SAML assertion';
        event3.Body__c = 'Org Id: 00D40000000ABCDEAE, Production, Time: 2020-04-29 16:00:53 GMT, Local: 2020-04-29 16:00:53 GMT /n User Id: 0054000000ABCDAA0, User name: admin@company.com, Time zone: Pacific Standard Time';
        event3.HTML_Body__c = false;
        EventBus.publish(event3);
        System.assertEquals(true, true);

        Org_Email_Event__e event4 = new Org_Email_Event__e ();
        event4.From_Addresses__c = 'some.admin@company.com';
        event4.To_Addresses__c = 'some.user@company.com;some.admin@company.com;support@company.com';
        event4.Subject__c = 'SSOJitHandler.createUser - test@abcd.com - SAML assertion';
        event4.Body__c = 'Org Id: 00D40000000ABCDEAE, Production, Time: 2020-04-29 16:00:53 GMT, Local: 2020-04-29 16:00:53 GMT /n User Id: 0054000000ABCDAA0, User name: admin@company.com, Time zone: Pacific Standard Time';
        event4.HTML_Body__c = false;
        EventBus.publish(event4);
        System.assertEquals(true, true);

        Org_Email_Event__e event5 = new Org_Email_Event__e ();
        event5.From_Addresses__c = 'support@company.com';
        event5.To_Addresses__c = 'some.user@company.com';
        event5.Subject__c = 'SSOJitHandler.createUser - test@abcd.com - SAML assertion';
        event5.Body__c = 'Org Id: 00D40000000ABCDEAE, Production, Time: 2020-04-29 16:00:53 GMT, Local: 2020-04-29 16:00:53 GMT /n User Id: 0054000000ABCDAA0, User name: admin@company.com, Time zone: Pacific Standard Time';
        event5.HTML_Body__c = true;
        EventBus.publish(event5);
        System.assertEquals(true, true);

        Test.StopTest();

        System.assertEquals(true, true);
    }

    // Publish events to call the event trigger.
    static testMethod void TestTriggerBlank() {
        Test.StartTest();

        Org_Email_Event__e event = new Org_Email_Event__e ();
        Database.SaveResult sr = EventBus.publish(event);
        System.assertEquals(true, true);

        event = CreateEmailEvent(null, null, null, null, null);
        EventBus.publish(event);
        System.assertEquals(true, true);

        event = CreateEmailEvent('', '', '', '', True);
        EventBus.publish(event);
        System.assertEquals(true, true);

        event = CreateEmailEvent('', '', 'Subject - event', '', True);
        EventBus.publish(event);
        System.assertEquals(true, true);

        event = CreateEmailEvent('', '', 'Subject - event', '', false);
        EventBus.publish(event);
        System.assertEquals(true, true);

        event = CreateEmailEvent('', '', '', 'Plain Text Body - event', false);
        EventBus.publish(event);
        System.assertEquals(true, true);

        Test.StopTest();

    }

    // Publish events to call the event trigger.
    static testMethod void TestTriggerDebug() {
        Test.StartTest();

        Org_Email_Event__e event;

        String subject = 'subject - event';
        String body = 'body - event';

        List<Decimal> testDebugStates = new List<Decimal> {null, OrgEmailEvent_Helper.DEBUG_FALSE, OrgEmailEvent_Helper.DEBUG_TRUE, OrgEmailEvent_Helper.DEBUG_ALLOWED, 99};
        List<Boolean> testHTMLBodyStates = new List<Boolean> {null, false, true};
        List<Boolean> testShowEventStates = new List<Boolean> {null, false, true};
        List<Boolean> testBrandingStates = new List<Boolean> {null, false, true};

        for(Decimal d : testDebugStates) {
            for(Boolean b : testHTMLBodyStates) {
                event = CreateEmailEvent('', '', subject, body + 'd=' + d + ', b=' + b, b);
                event.Debug__c = d;
                EventBus.publish(event);
                System.assertEquals(true, true);
            }
        }

        Test.StopTest();
    }


    // Publish events to call the event trigger.
    static testMethod void TestTriggerExceptions() {
        Test.StartTest();

        Org_Email_Event__e event4 = new Org_Email_Event__e ();
        event4.From_Addresses__c = 'from - event4';
        event4.To_Addresses__c = 'to - event4';
        event4.Subject__c = 'Subject - event4';
        event4.Body__c = 'Text Body - event4';
        event4.HTML_Body__c = false;
        Database.SaveResult sr = EventBus.publish(event4);
        System.assertEquals(true, true);

        Org_Email_Event__e event5 = new Org_Email_Event__e ();
        event5.To_Addresses__c = 'to - event5';
        event5.Subject__c = 'Subject - event5';
        event5.Body__c = 'Text Body - event5';
        event5.HTML_Body__c = false;
        event5.Debug__c = OrgEmailEvent_Helper.DEBUG_FALSE;
        EventBus.publish(event5);
        System.assertEquals(true, true);

        Org_Email_Event__e event6 = new Org_Email_Event__e ();
        event6.Subject__c = '';
        event6.Body__c = '';
        event6.HTML_Body__c = false;
        EventBus.publish(event6);
        System.assertEquals(true, true);

        Org_Email_Event__e event7 = new Org_Email_Event__e ();
        event7.Body__c = null;
        event7.HTML_Body__c = false;
        EventBus.publish(event7);
        System.assertEquals(true, true);

        OrgEmailEvent_Helper helper = new OrgEmailEvent_Helper();
        helper.testThrowException = true;
        List<Org_Email_Event__e> events = new List<Org_Email_Event__e> ();
        Org_Email_Event__e event = new Org_Email_Event__e();
        events.Add(event);
        helper.ProcessEmailEvents(events);

        helper = new OrgEmailEvent_Helper();
        events = new List<Org_Email_Event__e> ();
        helper.ProcessEmailEvents(events);

        helper = new OrgEmailEvent_Helper();
        helper.ProcessEmailEvents(null);

        Test.StopTest();

        System.assertEquals(true, true);
    }

    // Publish events to call the event trigger.
    static testMethod void TestTriggerBulk()
    {
        Integer numEvents = 25;

        QueryOrgWideEmail();

        Test.StartTest();

        List<Org_Email_Event__e> events = new List<Org_Email_Event__e> ();

        for(Integer i = 1; i <= numEvents; i++) {
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = (0 == math.mod(i,2) ? 'some.admin@company.com' : orgWideEmailId);
            event.To_Addresses__c = (0 == math.mod(i,2) ? 'a@a.com; b@b.com; c@c.com; d@d.com; e@e.com; f@f.com' : null);
            event.Subject__c = 'Subject__c - Batch - ' + i + ' of ' + numEvents;
            event.Body__c = 'Body__c - Batch - ' + i + ' of ' + numEvents;
            event.HTML_Body__c = (0 == math.mod(i,2));
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_ALLOWED;
            events.Add(event);
        }
        EventBus.publish(events);

        for(Integer i = 1; i <= numEvents; i++) {
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = (0 == math.mod(i,2) ? 'some.admin@company.com' : orgWideEmailId);
            event.To_Addresses__c = (0 == math.mod(i,2) ? 'a@a.com; b@b.com; c@c.com; d@d.com; e@e.com; f@f.com' : null);
            event.Subject__c = 'Subject__c - Single - ' + i + ' of ' + numEvents;
            event.Body__c = 'Body__c - Single - ' + i + ' of ' + numEvents;
            event.HTML_Body__c = (0 == math.mod(i,2));
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_FALSE;
            EventBus.publish(event);
        }

        System.assertEquals(true, true);

        Test.StopTest();

        System.assertEquals(true, true);
    }

    // Publish events to call the event trigger.
    static testMethod void TestTriggerHelper()
    {
        OrgEmailEvent_Helper helper = new OrgEmailEvent_Helper();

        helper.showEventInfoInSubject = True;
        helper.showEventInfoInBody = True;
        helper.showEventsInfoInBody = True;

        Org_Email_Event__e event1 = new Org_Email_Event__e();
        //event1.From_Addresses__c = orgWideEmailId;  // some.admin@company.com in the Organization Wide Addresses.
        event1.To_Addresses__c = 'some.user@company.com';
        event1.Subject__c = 'SSOJitHandler.updateUser - test.vanessa.greenlee@smud.org';
        event1.Body__c = '<p>Org Id: 00D40000000ABCDEAE, Production, Time: 2020-04-29 16:00:53 GMT, Local: 2020-04-29 16:00:53 GMT /n User Id: 0054000000ABCDAA0, User name: admin@company.com, Time zone: Pacific Standard Time</p>';
        event1.HTML_Body__c = true;
        helper.ProcessEmailEvents(new List<Org_Email_Event__e> {event1});


        helper = new OrgEmailEvent_Helper();

        Integer numEvents = 3;
        Integer count = 0;
        List<Org_Email_Event__e> events = new List<Org_Email_Event__e> ();
        for(Integer i = 1; i <= numEvents; i++) {
            count++;
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = (0 == math.mod(i,2) ? 'some.admin@company.com' : orgWideEmailId);
            event.To_Addresses__c = (0 == math.mod(i,2) ? 'a@a.com; b@b.com; c@c.com; d@d.com; e@e.com; f@f.com' : null);
            event.Subject__c = 'Subject__c - Batch - ' + i + ' of ' + numEvents;
            event.Body__c = 'Body__c - Batch - ' + i + ' of ' + numEvents;
            event.HTML_Body__c = (0 == math.mod(i,2));
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_TRUE;
            event.Branding__c = true;
            events.Add(event);
        }
        helper.ProcessEmailEvents(events);

        helper = new OrgEmailEvent_Helper();

        helper.showEventInfoInSubject = False;
        helper.showEventInfoInBody = False;
        helper.showEventsInfoInBody = False;

        for(Integer i = 1; i <= numEvents; i++) {
            count++;
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = (0 == math.mod(i,2) ? 'some.admin@company.com' : orgWideEmailId);
            event.To_Addresses__c = (0 == math.mod(i,2) ? 'a@a.com; b@b.com; c@c.com; d@d.com; e@e.com; f@f.com' : null);
            event.Subject__c = 'Subject__c - Single - ' + i + ' of ' + numEvents;
            event.Body__c = 'Body__c - Single - ' + i + ' of ' + numEvents;
            event.HTML_Body__c = (0 == math.mod(i,2));
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_FALSE;
            event.Branding__c = false;
            helper.ProcessEmailEvents(new List<Org_Email_Event__e> {event});
        }

        helper = new OrgEmailEvent_Helper();

        helper.testCcEmailAddress = 'some.user@company.com';
        helper.testBccEmailAddress = 'some.user@company.com';

        for(Integer i = 1; i <= numEvents; i++) {
            count++;
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = (0 == math.mod(i,2) ? 'some.admin@company.com' : orgWideEmailId);
            event.To_Addresses__c = (0 == math.mod(i,2) ? 'a@a.com; b@b.com; c@c.com; d@d.com; e@e.com; f@f.com' : null);
            event.Subject__c = 'Subject__c - Single - ' + i + ' of ' + numEvents;
            event.Body__c = 'Body__c - Single - ' + i + ' of ' + numEvents;
            event.HTML_Body__c = (0 == math.mod(i,2));
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_FALSE;
            event.Branding__c = false;
            helper.ProcessEmailEvents(new List<Org_Email_Event__e> {event});
        }


    }

    // Publish events to call the event trigger.
    static testMethod void TestLogicForDeveloperConsole()
    {

        Integer numEvents = 3;
        Integer count = 0;

        for(Integer i = 1; i <= numEvents; i++) {
            count++;
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = null;
            event.To_Addresses__c = 'some.user@company.com';
            event.Subject__c = '(' + count + ')  Single: Bulk ' + i + ' of ' + numEvents + ', ' +  System.Now().Format('yyyy-MM-dd HH:mm:ss.SSS z');
            event.Body__c = '(' + count + ')  Single: Bulk ' + i + ' of ' + numEvents + Utilities.getUserInfoStringHTML() + Utilities.getLimitsStringHTML();
            event.HTML_Body__c = true;
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_TRUE;
            event.Branding__c = true;
            event.Options__c = String.valueOf(count);
            EventBus.publish(event);
        }

        List<Org_Email_Event__e> events = new List<Org_Email_Event__e> ();
        for(Integer i = 1; i <= numEvents; i++) {
            count++;
            Org_Email_Event__e event = new Org_Email_Event__e();
            event.From_Addresses__c = null;
            event.To_Addresses__c = 'some.user@company.com';
            event.Subject__c = '(' + count + ')  List: Bulk ' + i + ' of ' + numEvents + ', ' +  System.Now().format('yyyy-MM-dd HH:mm:ss.SSS z');
            event.Body__c = '(' + count + ')  List: Bulk ' + i + ' of ' + numEvents + Utilities.getUserInfoStringHTML() + Utilities.getLimitsStringHTML();
            event.HTML_Body__c = true;
            event.Debug__c = OrgEmailEvent_Helper.DEBUG_ALLOWED;
            event.Options__c = 'c=' + String.valueOf(count);
            events.Add(event);
        }
        EventBus.publish(events);

    }

    // Get the Org Wide Email Address.
    static void QueryOrgWideEmail()
    {
        // The query for the bt.dev address can be removed when the code is moved to production and the stable orgWideEmailId can be used.
        OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = :Constants.systemFromEmailAddresses[0]];
        if (owea.size() > 0 ) {
            orgWideEmailId = owea.get(0).Id;
        }
        System.debug('orgWideEmailId: ' + orgWideEmailId);
    }

    // Setup any test data needed.
    @testSetup static void setupTestData()
    {
        // No test data needed here.
    }

}