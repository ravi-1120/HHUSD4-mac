/**
* @author - Brian Pfeil, Merck & Co.,Inc.
* @className - MRK_CommunicationUtils.cls
* @description - Various utilities to support Communications capabilities
* @createdate - July 8th, 2013
*
*/

public class MRK_CommunicationUtils {
    public MRK_CommunicationUtils() {
        
    }

    private static Integer getRandomInt(Integer lower, Integer upper) {
        return Math.round( Math.random() * (upper - lower) ) + lower;
    }

    private static Object getRandomElement(Object[] items) {
        return items[getRandomInt(0, items.size() - 1 )];
    }

    public static void generateCommunications() {

        Communication_MRK__c templateCommunication = [select Id, Body_MRK__c from Communication_MRK__c where Title_MRK__c = 'Template Communication'];

        String[] sourceValues = new String[]{};
        for (Schema.PicklistEntry pe : Communication_MRK__c.Source_MRK__c.getDescribe().getPicklistValues()) {
            sourceValues.add( pe.getValue() );
        }

        String[] categoryValues = new String[]{};
        for (Schema.PicklistEntry pe : Communication_MRK__c.Category_MRK__c.getDescribe().getPicklistValues()) {
            categoryValues.add( pe.getValue() );
        }


        String[] titleList = new String[]{'Change to OPUS Program for Acute Care Hospital Customers Effective September 1, 2011','Transitions of Care (ToC) Resource Update','PNEUMOVAX 23: Prework for Competition','UPDATED - Ophthalmics WAVE 2 Field-Based Employees:  Guidance for Obtaining a Merck American Express Corporate Card','UPDATED: Ophthalmics WAVE 2 Field-Based Employees:  REVISED COMET/SAP Employee Expense Management (EEM) Transition Plan','Pending INVANZ Push Bulletin','MM&P AUGUST Annual PI Exams Due: CANCIDAS®, DULERA®, & ISENTRESS®','AUGUST Annual PI Exams Due: CANCIDAS®, DULERA®, & ISENTRESS®','FAQs Regarding Merck/Roche US Co-Promotion Agreement','*NOW AVAILABLE*  ELECTRONIC SALES AID for AZASITE®','*NOW AVAILABLE*  ELECTRONIC SALES AID for AZASITE®','EMEND: Update to 2011 Merck Medical Forum (MMF) Lecture (LCT) Talk Title','DULERA.com - HCP and Consumer Website Updates','"UPDATED! LIVE Phone PIRs by GMIO Extended to Nov 11, 2011  "','Solutions Consultant Email Consent Process','Journey for Control (JFC) Resource Update','AFLURIA: Shipping for 2011/2012 Prebook orders of AFLURIA','Resource Update for JANUMET and JANUVIA – Destroy and Discard Select Resources','Sample Allocation Changes for DULERA','Updated  - National Neurology Disease Focus Teleconference Schedule for remainder of 2011','MMF – New Guidance on Peer Discussion Group Programs (PDG) and New 2011 Merck Medical Forum (MMF) Talk Title for ISENTRESS','ROME Resource Update(s) for Nasonex','An Updated Tablet Report is Now Available to all Representatives who support MAXALT/MAXALT-MLT','NEW – 2S2011 Representative Guide for MAXALT/MAXALT-MLT','Update - Materials for Athero 2S Workshops','VARIVAX: DIFFERENCES IN THE APPEARANCE OF PACKAGING','Action Required: Updated versions of the PI/PPI for EMEND and EMEND for Injection are now available.','DULERA Direct Mail Communications to Health Care Professionals (HCPs)','Treatment Week 4 Testing Requirement','2011 Oncology Sales Incentive Plan (SIP) Payout Changes','Oncology Reimbursement: New 2011 eMedical Forums (eMF) Now Available for Use','Merck Vaccines: Save the Date Train the Trainer','Decommission of MyCall Platform','PNEUMOVAX 23: Prework for 2S District Meetings','FAQ for SYLATRON','Perspective on simvastatin label update published in NEJM','Responses to customer questions around the EARLY-ACS Trial','Customer Marketing:  UPDATE - Vaccine Integrated Health System Program (Vaccine IHS Program)','Merck ExpressCheck Phase II – Coming Soon','Merck Vaccines: TRICARE to Include Covered Vaccines Under Pharmacy Benefit','RECOMBIVAX HB:  National Relaunch of RECOMBIVAX HB (adult formulation) and PI Update','MM&P-AVAILABLE SERIES COMPLETION RESOURCES FOR GARDASIL® [HUMAN PAPILLOMAVIRUS QUADRIVALENT (TYPES 6, 11, 16, 18) VACCINE RECOMBINANT]','Customer Marketing:  New analysis tools to support Merck Contracts','New Resource: Dosing Card for PRIMAXIN (imipenem)','Sample Send information during Insight/Customer Finder blackout period','Fertility Team ROME Update - Ovulation Induction Booklets','MM&P-Managed Care Newsletter and Outreach Letter Template Resources to Support Adult Vaccination','ZETIA: Expanded indication','New Asset: Glassman/MOA Card for Emend','Legal Hold Promotional Material for AVELOX and CIPRO','Legal Hold Promotional Material for AVELOX and CIPRO','Customer Marketing:  Training and Customer Resources for Merck Contracts and Pricing Programs','ZOSTAVAX®: New Information Regarding the Patient Rebate Program (PRP) for ZOSTAVAX (Zoster Vaccine Live)'};
        
        List<Communication_MRK__c> commList = new List<Communication_MRK__c>();
        Integer idx = 0;
        for (String title : titleList) {
            Integer n = (idx + 1);
            Communication_MRK__c c = new Communication_MRK__c(
                Title_MRK__c = title,
                Summary_MRK__c = 'The purpose of this communication is to provide you with information about ' + title,
                Body_MRK__c = templateCommunication.Body_MRK__c,
                Source_MRK__c = 'General;' + (String)getRandomElement(sourceValues) + ';',
                Category_MRK__c = (String)getRandomElement(categoryValues),
                Priority_MRK__c = 'Normal Approval',
                Flesch_Kincaid_Grade_Level_MRK__c=30,
                Time_to_Complete_MRK__c = 20,
                Status_MRK__c = 'Released',
                Effective_Date_MRK__c = Date.today().addDays( -Math.round( Math.random() * (365 * 2) ) ),
                Expiration_Date_MRK__c = Date.today().addDays( 365 + Math.round( Math.random() * (365) ) ),
                Content_Owner_MRK__c='PFEILBR',
                Push_as_Notification_MRK__c = (Math.random() > 0.5),
                Active_MRK__c = true
            );
            commList.add(c);
            idx++;
        }

        insert commList;


        List<Attachment> templateAttachmentList = [select Id, ParentId, Name, IsPrivate, ContentType, Body, BodyLength, OwnerId, Description from Attachment WHERE Name IN ('2012 green Ribbon Recognition_District.doc', 'Policy Letter No. 1A', 'AFLURIA Roles and Responsiblities FINAL.pdf', '2013 - Prioritized Accounts List.xls')];
        List<Attachment> attachmentList = new List<Attachment>();

        List<Communication_Target_MRK__c> commTargetList = new List<Communication_Target_MRK__c>();

        for (Communication_MRK__c c : commList) {

            for (Attachment a : templateAttachmentList) {
                Attachment ac = a.clone();
                ac.parentId = c.Id;
                attachmentList.add(ac);
            }

            // 2 targets per communication
            for (Integer i = 0; i < 2; i++) {
                Communication_Target_MRK__c ct = new Communication_Target_MRK__c(
                    Communication_MRK__c = c.Id,
                    Type_MRK__c = (Math.random() > 0.5) ? 'Action' : 'Background',
                    Profile_MRK__c = 'MRK - Sales Director;MRK - Sales Manager;MRK - Contact Center Sales Representative;MRK - Sales Representative',
                    Product_MRK__c = 'General;AFLURIA;AR: DISEASE AWARENESS;ASMANEX;AVELOX;AVELOX IV;AZASITE;CANCIDAS;CELESTONE;CELESTONE SOLUSPAN;CERVARIX;CHLOR-TRIMETON;CHLOR-TRIMETON D;CILASTATIN;CIPRO;CIPRO I.V.;CIPRO XR;CLARINEX;CLARINEX-D;CLARITIN;CLARITIN-D;COMPLEX 15;COMVAX;COPPERTONE;CORICIDIN;CORICIDIN D;CORRECTOL;COSOPT;COSOPT PF;COZAAR;CRIXIVAN;CUSHION GRIP;CUSTOM FIT ORTHOTICS;CYCLESSA;DALIRESP;DESOGEN;DR. SCHOLL\'S;DRIXORAL;DULERA;EMEND;EMEND_PONV;ENGERIX-B;FINASTERIDE;FOLLISTIM;FOLLISTIM AQ;FOLLISTIM AQ PEN DEVICE;FORADIL;FORADIL DEMO;FOSAMAX;FOSAMAX_PLUS_D;GANIRELIX;GARDASIL;GUANIDINE;GYNE-LOTRIMIN;HAVRIX;HYZAAR;IMDUR;IMIPENEM-CILASTATIN;IMPLANON;INDOMETHACIN;INSPIREASE;INTEGRILIN;INTRON A NOVOFINE NEEDLE DEVICE;INTRON-A;INVANZ;ISENTRESS;JANUMET;JANUMET XR;JANUVIA;JUVISYNC;KOMBIGLYZE XR;LEVITRA;LIPTRUZET;LISINOPRIL;LOSARTAN POTASSIUM;LOSARTAN POTASSIUM HCTZ;LOTRIMIN;LOTRIMIN ULTRA;LOTRISONE;LOVASTATIN;M-M-R II;MAXALT;MAXALT MLT;MEXSANA;MIRALAX;MKT_ASMNT - ATHERO;MKT_ASMNT-ADHF;MOMETAMAX;MUMPSVAX',
                    Team_MRK__c = 'EST PRODS BUSINESS UNIT;Field Support;Government;HEALTH SCIENCE ASSOCIATES;HOSPITAL;MMP - HEALTH CARE SYSTEMS;MMP HOSP & FEDERAL ACCTS;MMP PHARMACY & SPECIALTY;NBG - HAIR SPECIALTY;NEURO-PSYCH SALES FORCE;NORTH CENTRAL;NORTH EAST;SOLUTION CONSULTANTS;SOUTH EAST;USHH Special Assignment;VIROLOGY;WEST;WOMENS HEALTH SALES FORCE;MERCK & CO.'
                );
                commTargetList.add(ct);             
            }

        }

        insert attachmentList;
        insert commTargetList;
    }

    public static void generateCommunicationEvents() {

        Integer numberToGenerate = 1;

        String[] categoryValues = new String[]{};
        for (Schema.PicklistEntry pe : Communication_Event_MRK__c.Category_MRK__c.getDescribe().getPicklistValues()) {
            categoryValues.add( pe.getValue() );
        }

        List<Communication_Event_MRK__c> eventList = new List<Communication_Event_MRK__c>();

        String[] titleList = new String[]{'PNEUMOVAX 23: OPTION 1 - LIVE WEBCAST', 'DUE: Policy Letter #3 Exam - Certification - 2013', 'Save the Date: National Teleconference for ZOSTAVAX - Option 1'};

        /*
        for (Integer i = 0; i < numberToGenerate; i++) {
            titleList.add('Test Event ' + i);           
        }
        */

        Integer index = 0;
        for (String title : titleList) {
            Communication_Event_MRK__c e = new Communication_Event_MRK__c(
                Active_MRK__c=true,
                Title_MRK__c=title,
                Description_MRK__c='Description for event titled ' + title,
                Category_MRK__c = (String)getRandomElement(categoryValues),
                Contact_Type_MRK__c='Teleconference',
                Content_Owner_MRK__c='PFEILBR',
                Priority_MRK__c='Normal Approval',
                Source_MRK__c='General',
                Status_MRK__c='Released',
                Location_MRK__c='location for ' + title,
                Time_to_Complete_MRK__c=10,
                Start_DateTime_MRK__c=DateTime.now().addDays(index),
                End_DateTime_MRK__c=DateTime.now().addDays(index).addHours(1)
            );
            eventList.add(e);
            index++;
        }
        insert eventList;

        List<Communication_Event_Target_MRK__c> eventTargetList = new List<Communication_Event_Target_MRK__c>();
        for (Communication_Event_MRK__c e : eventList) {

            // 2 targets per event
            for (Integer i = 0; i < 2; i++) {
                Communication_Event_Target_MRK__c ct = new Communication_Event_Target_MRK__c(
                    Communication_Event_MRK__c = e.Id,
                    Type_MRK__c = (Math.random() > 0.5) ? 'Required' : 'Optional',
                    Profile_MRK__c = 'MRK - Sales Director;MRK - Sales Manager;MRK - Contact Center Sales Representative;MRK - Contact Center Sales Director;MRK - Contact Center Sales Manager;MRK - Sales Representative',
                    Product_MRK__c = 'General;AFLURIA;AR: DISEASE AWARENESS;ASMANEX;AVELOX;AVELOX IV;AZASITE;CANCIDAS;CELESTONE;CELESTONE SOLUSPAN;CERVARIX;CHLOR-TRIMETON;CHLOR-TRIMETON D;CILASTATIN;CIPRO;CIPRO I.V.;CIPRO XR;CLARINEX;CLARINEX-D;CLARITIN;CLARITIN-D;COMPLEX 15;COMVAX;COPPERTONE;CORICIDIN;CORICIDIN D;CORRECTOL;COSOPT;COSOPT PF;COZAAR;CRIXIVAN;CUSHION GRIP;CUSTOM FIT ORTHOTICS;CYCLESSA;DALIRESP;DESOGEN;DR. SCHOLL\'S;DRIXORAL;DULERA;EMEND;EMEND_PONV;ENGERIX-B;FINASTERIDE;FOLLISTIM;FOLLISTIM AQ;FOLLISTIM AQ PEN DEVICE;FORADIL;FORADIL DEMO;FOSAMAX;FOSAMAX_PLUS_D;GANIRELIX;GARDASIL;GUANIDINE;GYNE-LOTRIMIN;HAVRIX;HYZAAR;IMDUR;IMIPENEM-CILASTATIN;IMPLANON;INDOMETHACIN;INSPIREASE;INTEGRILIN;INTRON A NOVOFINE NEEDLE DEVICE;INTRON-A;INVANZ;ISENTRESS;JANUMET;JANUMET XR;JANUVIA;JUVISYNC;KOMBIGLYZE XR;LEVITRA;LIPTRUZET;LISINOPRIL;LOSARTAN POTASSIUM;LOSARTAN POTASSIUM HCTZ;LOTRIMIN;LOTRIMIN ULTRA;LOTRISONE;LOVASTATIN;M-M-R II;MAXALT;MAXALT MLT;MEXSANA;MIRALAX;MKT_ASMNT - ATHERO;MKT_ASMNT-ADHF;MOMETAMAX;MUMPSVAX',
                    Team_MRK__c = 'EST PRODS BUSINESS UNIT;Field Support;Government;HEALTH SCIENCE ASSOCIATES;HOSPITAL;MMP - HEALTH CARE SYSTEMS;MMP HOSP & FEDERAL ACCTS;MMP PHARMACY & SPECIALTY;NBG - HAIR SPECIALTY;NEURO-PSYCH SALES FORCE;NORTH CENTRAL;NORTH EAST;SOLUTION CONSULTANTS;SOUTH EAST;USHH Special Assignment;VIROLOGY;WEST;WOMENS HEALTH SALES FORCE;MERCK & CO.'
                );
                eventTargetList.add(ct);                
            }

        }
        insert eventTargetList;

    }

    public static void permanentDelete(String soql) {
        System.debug('permanentDelete( ' + soql + ' )');
        List<sObject> l = Database.query(soql);
        delete l;
        if (l.size() > 0) {
            try { Database.emptyRecycleBin(l);} catch (Exception e) {}          
        }
    }

    public static void purgeEventsAssociatedWithCommunicationEvents() {
        permanentDelete('select id from event where RecordTypeId = \'' + MRK_CommunicationServices.communicationEventRecordTypeId + '\'');
    }

    public static void purgeCommunicationEvents() {
        permanentDelete('select Id from Communication_Event_Target_MRK__c where Communication_Event_MRK__r.Title_MRK__c != \'Template Communication\'');
        permanentDelete('select Id from Communication_Event_MRK__c where Title_MRK__c != \'Template Communication\'');      
    }

    public static void purgeCommunications() {
        permanentDelete('select Id from Communication_Activity_MRK__c where Communication_MRK__r.Title_MRK__c != \'Template Communication\'');
        permanentDelete('select Id from Communication_Target_MRK__c where Communication_MRK__r.Title_MRK__c != \'Template Communication\'');
        permanentDelete('select Id from Communication_MRK__c where Title_MRK__c != \'Template Communication\'');
    }

    public static void seedTestCommunications() {
        purgeCommunications();
        generateCommunications();
    }

    public static void seedTestCommunicationEvents() {
        purgeEventsAssociatedWithCommunicationEvents();
        purgeCommunicationEvents();
        generateCommunicationEvents();
    }

    // MRK_CommunicationUtils.LinkLoader l = new MRK_CommunicationUtils.LinkLoader();
    // l.run();
    public class LinkLoader {
        
        public LinkLoader() {}

        private List<Map<String,String>> parse(Dom.XMLNode rootNode, String containerElementName, String fieldNames) {
            List<Map<String,String>> objs = new List<Map<String,String>>();
            Dom.XMLNode containerNode = rootNode.getChildElement(containerElementName, null);
            for(Dom.XMLNode node : containerNode.getChildElements()) {
                Map<String,String> obj = new Map<String,String>();
                for (String fieldName : fieldNames.split(',')) {
                    obj.put(fieldName, node.getChildElement(fieldName, null).getText());
                }
                objs.add(obj);
            }
            return objs;      
        }
        
        private void print(List<Map<String,String>> objs) {
            for (Map<String,String> obj : objs) {
                Set<String> keySet = obj.keySet();
                for (String key : keySet) {
                    System.debug(key + ' = ' + obj.get(key));
                }
            }
        }
        
        private void deleteAllOfType(String type) {
            sObject[] objs = Database.query('select Id, Name from ' + type);
            Database.DeleteResult[] deleteResults = Database.delete(objs);
            if (objs.size() > 0) {
                Database.emptyRecycleBin(objs);
            }
        }

        public void run() {
            
            /*
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(url);
            req.setMethod('GET');
            HttpResponse res = h.send(req);
            Dom.Document doc = res.getBodyDocument();
            */

            String xml = '<Config> <EssentialLinkCategories> <EssentialLinkCategory> <Name>Recent Links</Name> <ShortName>FrequentlyUsedLinks</ShortName> <Order>1</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Departments</Name> <ShortName>Departments</ShortName> <Order>3</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Merck Sites</Name> <ShortName>MerckSites</ShortName> <Order>4</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Field Resources</Name> <ShortName>FieldResources</ShortName> <Order>9</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Career &amp; Development</Name> <ShortName>CareerDevelopment</ShortName> <Order>5</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Safety &amp; Fleet</Name> <ShortName>SafetyFleet</ShortName> <Order>7</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Personal Info &amp; Benefits</Name> <ShortName>PersonalInformationBenefits</ShortName> <Order>8</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Travel &amp; Meetings</Name> <ShortName>TravelMeetings</ShortName> <Order>6</Order> </EssentialLinkCategory> <EssentialLinkCategory> <Name>Former Schering-Plough Employees</Name> <ShortName>FormerScheringPloughEmployees</ShortName> <Order>10</Order> </EssentialLinkCategory> </EssentialLinkCategories> <EssentialLinks> <EssentialLink> <Name>SPHERE Links - SP Sourced</Name> <Url>http://one.merck.com/sites/sa/en-us/Pages/WhyisGlobalSPHEREWebsiteBeingPhasedOut.aspx</Url> <Category>FormerScheringPloughEmployees</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Travelog - SP Sourced</Name> <Url>https://e-hr.schp.com/S-PeWorld/s-pehr/spehr.asp</Url> <Category>FormerScheringPloughEmployees</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Learning Network</Name> <Url>http://fsts.merck.com/</Url> <Category>CareerDevelopment</Category> <Order>4</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Discounts &amp; Deals</Name> <Url>http://procure.merck.com/gisp/epp/EmployeePurchasePrograms.html</Url> <Category>PersonalInformationBenefits</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>ADP</Name> <Url>https://ipay.adp.com/</Url> <Category>PersonalInformationBenefits</Category> <Order>3</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Merck Partnership for Giving (P4G)</Name> <Url>https://www.easymatch.com/merckp4g</Url> <Category>PersonalInformationBenefits</Category> <Order>4</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Career Link</Name> <Url>http://careers.merck.com/na/careers/en.html</Url> <Category>CareerDevelopment</Category> <Order>1</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Career Map</Name> <Url>http://ushhcareermap.merck.com/career/index.jsp</Url> <Category>CareerDevelopment</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Educational Assistance</Name> <Url>http://hr.merck.com/polproc/us/d1.html</Url> <Category>CareerDevelopment</Category> <Order>4</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>iLead</Name> <Url>http://ilead.merck.com/</Url> <Category>CareerDevelopment</Category> <Order>6</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>myPMP</Name> <Url>http://mypmp.merck.com/</Url> <Category>CareerDevelopment</Category> <Order>8</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Career Pathway</Name> <Url>http://careerpath.merck.com/</Url> <Category>CareerDevelopment</Category> <Order>9</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>BP&amp;C - Business Practices &amp; Compliance</Name> <Url>http://bpcglobalsupportus.merck.com/</Url> <Category>Departments</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>By Design - NCM &amp; Managed Care</Name> <Url>http://bydesign.merck.com/</Url> <Category>Departments</Category> <Order>1</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>GEMS - Global Expert Management Services</Name> <Url>http://teamsite.merck.com/collaboration/GEEM_Field/default.aspx</Url> <Category>Departments</Category> <Order>3</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Office of Ethics</Name> <Url>http://ethics.merck.com/</Url> <Category>Departments</Category> <Order>3</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>GHH - U.S. Market Website</Name> <Url>http://usco.merck.com/</Url> <Category>MerckSites</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Idea Central</Name> <Url>https://ideas.merck.com/</Url> <Category>MerckSites</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Merck Services</Name> <Url>http://www.merckservices.com/</Url> <Category>MerckSites</Category> <Order>7</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Physician Desk Reference (PDR)</Name> <Url>http://pdrel.thomsonhc.com/</Url> <Category>MerckSites</Category> <Order>10</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Customer Feedback &amp; Response</Name> <Url>http://customerfocus.merck.com/na/customerfocus/index.html</Url> <Category>MerckSites</Category> <Order>12</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Merck Sharpe &amp; Dohme Credit Union</Name> <Url>http://www.msdfcu.org/</Url> <Category>MerckSites</Category> <Order>12</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Merck Employees Federal Credit Union</Name> <Url>http://www.merckcu.com</Url> <Category>MerckSites</Category> <Order>13</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Sync</Name> <Url>http://one.merck.com/sites/gcc/en-us/Pages/Home.aspx</Url> <Category>MerckSites</Category> <Order>14</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Business Cards</Name> <Url>http://merckff.cgconverge.com/</Url> <Category>FieldResources</Category> <Order>1</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Competitive Product Circulars</Name> <Url>http://tse.merck.com/int/cc/Pages/CompetitiveProductCirculars.aspx</Url> <Category>FieldResources</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Field Performance Reports</Name> <Url>http://teamsite.merck.com/collaboration/NBPT/_layouts/AccessDenied.aspx?Source=http%3A%2F%2Fteamsite%2Emerck%2Ecom%2FCOLLABORATION%2FNBPT%2FPages%2FFieldPerformanceReports%2Easpx&amp;Type=list&amp;name=%7B4174D61F%2DBF74%2D42EE%2D852E%2DB937501A4F6D%7D</Url> <Category>FieldResources</Category> <Order>3</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Hospital National Accounts</Name> <Url>http://hna.merck.com/ushhdept/hna/master.jsp</Url> <Category>FieldResources</Category> <Order>5</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Legal Hold Documents</Name> <Url>http://legalholds.merck.com/ushhdept/legalhold/master.jsp</Url> <Category>FieldResources</Category> <Order>6</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Managed Care Formulary Status</Name> <Url>http://tse.merck.com/int/cc/Documents/Spreadsheet Redirect.doc</Url> <Category>FieldResources</Category> <Order>7</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Managed Care Power Portal</Name> <Url>http://mcpowerportal.merck.com/</Url> <Category>FieldResources</Category> <Order>8</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Name Badges</Name> <Url>http://store.artcraftpromos.com/SourceFiles/SiteID21/Default.asp</Url> <Category>FieldResources</Category> <Order>10</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Office Supplies</Name> <Url>https://www.pwi-inc.com/</Url> <Category>FieldResources</Category> <Order>11</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Organizational Charts</Name> <Url>https://orgchart.merck.com/OrgChart/default.aspx</Url> <Category>FieldResources</Category> <Order>12</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Price Catalog</Name> <Url>http://economicaffairs.merck.com/ushhdept/economicaffairs/master.jsp</Url> <Category>FieldResources</Category> <Order>13</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Records Management for Field Sales</Name> <Url>http://webview.merck.com/webview/WebView.jsp?nu=F&amp;d=gdmsprd&amp;p=/IS/Enterprise%20Systems%20and%20Services/ESS%20Departments/IMD%20WebViews/US%20Field%20Sales</Url> <Category>FieldResources</Category> <Order>14</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Representative Finder</Name> <Url>http://custfind.merck.com/repfind/repfinder.jsp</Url> <Category>FieldResources</Category> <Order>15</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Scientific Request Process</Name> <Url>http://usco.merck.com/srp</Url> <Category>FieldResources</Category> <Order>16</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Solutions Playbook</Name> <Url>http://teamsite.merck.com/collaboration/css/Solutions_Playbook/Customer%20Solutions%20Group%20-%20Playbook.pdf</Url> <Category>FieldResources</Category> <Order>17</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Speaker Registry</Name> <Url>http://hss.merck.com/speakerregistry/</Url> <Category>FieldResources</Category> <Order>18</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>The Food Court</Name> <Url>http://fsnetprd.merck.com/portal/support/foodCourt.shtml</Url> <Category>FieldResources</Category> <Order>19</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Merck Vaccines Savings Plan</Name> <Url>https://login.merck.com/cleartrust/ct_logon.jsp?ct_orig_uri=http://mvspcalc.merck.com/</Url> <Category>FieldResources</Category> <Order>19</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Pharmacist Recognition Submission Form</Name> <Url>http://tse.merck.com/int/cc/Documents/1011_MERCK%20PHARMACIST%20RECOGNITION%20submission%20form.doc</Url> <Category>FieldResources</Category> <Order>20</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>AT&amp;T Connect QuickStart Guide </Name> <Url>http://tse.merck.com/int/cc/Documents/ATT%20Connect%20%20QuickStartGuide%20FBE%20-%20July%2711%20-%20FINAL.pdf</Url> <Category>FieldResources</Category> <Order>21</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Share Point/Team Site </Name> <Url>http://teamsite.merck.com</Url> <Category>FieldResources</Category> <Order>22</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Address Update (Simon – Samples/Promotional Materials)</Name> <Url>http://simon.merck.com/simon/adaptfsnetaction.do</Url> <Category>PersonalInformationBenefits</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Diversity, Work Environment &amp; University Relations Strategy</Name> <Url>http://humres.merck.com/diversity_workenv/arrangements.html</Url> <Category>PersonalInformationBenefits</Category> <Order>3</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Update Personal Information</Name> <Url>http://one.merck.com/Pages/AboutMe.aspx</Url> <Category>PersonalInformationBenefits</Category> <Order>4</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Fidelity</Name> <Url>https://401k.fidelity.com/</Url> <Category>PersonalInformationBenefits</Category> <Order>6</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Merck HR</Name> <Url>http://hr.merck.com/humres/index.jsp</Url> <Category>PersonalInformationBenefits</Category> <Order>7</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>MorganStanley SmithBarney</Name> <Url>https://www.benefitaccess.com/</Url> <Category>PersonalInformationBenefits</Category> <Order>8</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>PeopleInfo</Name> <Url>http://peopleinfo.merck.com/</Url> <Category>PersonalInformationBenefits</Category> <Order>9</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Financial Engines</Name> <Url>https://www.financialengines.com/FeContent?act=welcome</Url> <Category>PersonalInformationBenefits</Category> <Order>10</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Certificate of Insurance Request</Name> <Url>http://finance.merck.com/finance/financeadministration/im_certificateofinsurance.jsp</Url> <Category>SafetyFleet</Category> <Order>1</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>DriverCare</Name> <Url>http://drivercare.merck.com</Url> <Category>SafetyFleet</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Driver\'s Safety</Name> <Url>http://safedriving.merck.com/na/safedriving/Home.html</Url> <Category>SafetyFleet</Category> <Order>3</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Global Security</Name> <Url>http://security.merck.com/home.html</Url> <Category>SafetyFleet</Category> <Order>4</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>US Fleet</Name> <Url>http://fleet.merck.com/</Url> <Category>SafetyFleet</Category> <Order>5</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Wheels</Name> <Url>https://www.wheels.com/driver/MileageLog</Url> <Category>SafetyFleet</Category> <Order>6</Order> <RequiresConnectivity>internet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Directions to Regional Offices</Name> <Url>http://directions.merck.com/</Url> <Category>TravelMeetings</Category> <Order>1</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>My eTrip - Merck Sourced</Name> <Url>http://fstravel.merck.com/myetrip</Url> <Category>TravelMeetings</Category> <Order>2</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Search for Restaurants</Name> <Url>http://stnd.rewardsnetwork.com/advanced-search.htm</Url> <Category>TravelMeetings</Category> <Order>4</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> <EssentialLink> <Name>Set Up A Teleconference</Name> <Url>http://mts.merck.com/</Url> <Category>TravelMeetings</Category> <Order>5</Order> <RequiresConnectivity>intranet</RequiresConnectivity> </EssentialLink> </EssentialLinks> </Config>';
            Dom.Document doc = new Dom.Document();
            doc.load(xml);
            
            Dom.XMLNode docRoot = doc.getRootElement();
            
            List<Map<String,String>> categories = parse(docRoot, 'EssentialLinkCategories', 'Name,ShortName,Order');
            List<Map<String,String>> links = parse(docRoot, 'EssentialLinks', 'Name,Url,Category,Order,RequiresConnectivity');
                    
            deleteAllOfType('Resource_Link_MRK__c');
            deleteAllOfType('Resource_Link_Category_MRK__c');
            
            Map<String,Id> categoryLookup = new Map<String,Id>();
            for (Map<String,String> c : categories) {
                Resource_Link_Category_MRK__c category = new Resource_Link_Category_MRK__c(Name=c.get('Name'), Description_MRK__c=c.get('Name'),Sort_Order_MRK__c=Decimal.valueOf( c.get('Order') ) );
                insert category;
                categoryLookup.put(c.get('ShortName'), category.Id);
            }

            for (Map<String,String> l : links) {
                Id categoryId = categoryLookup.get(l.get('Category'));
                Resource_Link_MRK__c link = new Resource_Link_MRK__c(Name_MRK__c=l.get('Name'), Description_MRK__c=l.get('Name'), URL_MRK__c=l.get('Url'), Sort_Order_MRK__c=Decimal.valueOf( l.get('Order') ), Resource_Link_Category_MRK__c=categoryId, Content_Owner_MRK__c='PFEILBR', Active_MRK__c=true);
                insert link;
            }
                          
            print(categories);
            print(links);

        }

        
    }

}