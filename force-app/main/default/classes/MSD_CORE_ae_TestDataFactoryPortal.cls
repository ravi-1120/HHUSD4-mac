@isTest
public class MSD_CORE_ae_TestDataFactoryPortal {

    public static void createAEPortalSource() {
        MSD_CORE_Source__c source = new MSD_CORE_Source__c(Name = 'AE Self Service Portal');
        insert source;
    }

    public static User createGuestUser(){
        Profile firstProfile = [SELECT Id FROM Profile Where Name = 'AE Self Service Portal Profile'];
        User user1 = new User(LastName = 'Userton',
                            FirstName='User',
                            Alias = 'uAlias',
                            Email = 'AEuser.user@merck.com',
                            Username = Math.random() + 'AEPortal@acme.com',
                            ProfileId = firstProfile.Id,
                            TimeZoneSidKey = 'GMT',
                            LanguageLocaleKey = 'en_US',
                            EmailEncodingKey = 'UTF-8',
                            LocaleSidKey = 'en_US'
                    
        );
        insert user1;
        return user1;
    }

    public static Map<String, Object> createCaseDetail(){

        Id aeRecordType = getRecordTypeId();

        Map<String, Object> caseDetails = new Map<String, Object>{
            'stage1' => new Map<Object, Object>{
                'userChoice' => 'PSP Representative'
            },
            'stage2' => new Map<Object, Object>{
                'Adverse_Event_MVN' => aeRecordType,
                'PSPProgramName' => 'Other',
                'PSPCompany'=> 'Other',
                'PSPNumber' => 'Other',
                'PSPCompanyOther' => 'abcdefg',
                'PSPNumberOther' => '1234567',
                'PSPProgramNameOther' => 'Programother',
                'PatientID' => 'PatientId123',
                'Agentname' => 'AgentTest',
                'FieldBased'=> 'yes'
                 
            },
            'stage3' => new Map<Object, Object>{
                'ReporterType' => 'Consumer',
                'ReporterTypeLabel' => 'Consumer',
                'RepFirstName' => 'Test Name',
                'RepDOB' => 'March 23rd,1999',
                'RepAge' => '24',
                'RepGender'=> 'Male',
                'isRepPregnant' => 'yes',
                'RepGestationOrLMP' => '4 months',
                'permissionContact' => 'Yes',
                'RepLastName' => 'Test LastName',
                'RepPhone' => '9999555555',
                'RepEmail' => 'test@ae.com',
                'RepAddress' => 'TestAddress1',
                'RepCity' => 'TestCity',
                'RepZip' => '310222',
                'RepState' => 'AL',
                'RepType' => '',
                'RepFacilityName' => '',
                'ReporterHCPSame' => '',
                'HCPFirstName' => 'HCP First',
                'HCPLastName' => 'HCP Last',
                'HCPPhone' => '',
                'HCPEmail' => '',
                'HCPAddress' => '',
                'HCPCity' => '',
                'HCPZip' => '',
                'HCPState' => '',
                'HCPType' => '',
                'PatientsHC' => 'Yes',
                'HCPFacilityName' => 'Test Practice',
                'HCPPermission' => 'Yes',
                'PatientFirstName' => 'John',
                'PatientLastName' => 'Doe',
                'PatientDOB' => '1990-01-01',
                'PatientAge' => '30',
                'PatientGender' => 'Female',
                'isPatientPregnant' => 'Yes',
                'GestationOrLMP' => '10 weeks',
                'isFemale' => 'false',
                'ifPregnantYes' => 'false',
                'RepAddressLine2' => 'TestAddress2'
            },
            'stage4' => new List<Object>{
                new Map<Object,Object>{
                    'values' => new Map<Object, Object>{
                        'Product' => 'Test Product',
                        'ProductId' => 'OtherProductField',
                        'CatalogNumber' => 'CAT123',
                        'DoseFrequency' => 'Once Daily',
                        'ExpirationDate' => '2025-12-31',
                        'LotNumber' => 'LOT123',
                        'SerialNumber' => 'SER123',
                        'ModelNumber' => 'MOD123',
                        'UniqueIdentifier' => 'UID123',
                        'OperatorOfDevice' => 'Unknown'
                    }, 'id' => '1',
                    'values' => new Map<Object, Object>{
                        'Product' => 'Test Product',
                        'ProductId' => 'OtherProductField',
                        'CatalogNumber' => 'CAT123',
                        'DoseFrequency' => 'Once Daily',
                        'ExpirationDate' => '2025-12-31',
                        'LotNumber' => 'LOT123',
                        'SerialNumber' => 'SER123',
                        'ModelNumber' => 'MOD123',
                        'UniqueIdentifier' => 'UID123',
                        'OperatorOfDevice' => 'Unknown'
                    }, 'id' => '2'
                }
            },
            'stage5' => new Map<Object, Object>{
                'MPI' => 'Yes',
                'AE' => 'Test AE Description',
                'CAD' => '2023-11-07',
                'AOD' => ''
            },
            'stage6' => new Map<Object, Object>{
                'patientdeath' => 'Yes',
                'causedeath' => 'Cancer',
                'deathdate' => 'Yesterday',
                'AEhospitilization' => 'Yes',
                'illness' => 'Yes',
                'disability' => 'Yes',
                'birthdefect' => 'Yes',
                'cancer' => 'Yes',
                'overdose' => 'Yes',
                'intervention' => 'Yes',
                'indication' => 'Test indication',
                'roa' => 'Test Route of Administration',
                'TherapySD' => 'Test Date',
                'therapyque' => 'Yes',
                'TherapyED' => 'Test End Date',
                'dechallenge' => 'Unknown',
                'rechallenge' => 'Unknown',
                'sma' => 'Test Sought Medical Attention',
                'Treatmentque' => 'Yes',
                'isTreatment' => 'Test Treatment',
                'presentstatus' => 'Recovered',
                'RecoveryDate'  => 'Test 02-11-2017',
                'CM' => 'Test Concomitant Medication',
                'PMH' => 'Test Patient Medical History',
                'DRA' => 'Test Drug Reaction Allergies',
                'LDSP' => 'Test Lab Diagnostics'
            }
        };

        return caseDetails;
    }
       public static Map<String, Object> createCaseDetailHCP(){

        Id aeRecordType = getRecordTypeId();
         Map<String, Object> caseDetailsHCP = new Map<String, Object>{
            'stage1' => new Map<Object, Object>{
                'userChoice' => 'Healthcare Professional'
            },
            'stage2' => new Map<Object, Object>{
                'Adverse_Event_MVN' => aeRecordType,
                 'hcpFirstName' => 'Test Fname',
                 'hcpLastName' => 'Test Lname',
                 'hcpPhone' => '9857674326',
                 'hcpEmail' => 'test@email.com',
                 'hcpAddress' => 'test Lane 1',
                 'hcpAddressLine2' => 'test Lane 2',
                 'hcpCity' => 'test City',
                 'hcpState' => 'test State',
                 'hcpZip' => 'test Zip',
                 'hcpCountry' => 'US',
                 'licensedHCP' => 'Licensed Healthcare Professional'
                  
            },
            'stage3' => new Map<Object, Object>{
                'ReporterType' => 'Consumer',
                'ReporterTypeLabel' => 'Consumer',
                'RepFirstName' => 'Test Name',
                'RepDOB' => 'March 23rd,1999',
                'RepAge' => '24',
                'RepGender'=> 'Male',
                'isRepPregnant' => 'yes',
                'RepGestationOrLMP' => '4 months',
                'permissionContact' => 'Yes',
                'RepLastName' => 'Test LastName',
                'RepPhone' => '9999555555',
                'RepEmail' => 'test@ae.com',
                'RepAddress' => 'TestAddress1',
                'RepCity' => 'TestCity',
                'RepZip' => '310222',
                'RepState' => 'AL',
                'RepType' => '',
                'RepFacilityName' => '',
                'ReporterHCPSame' => '',
                'HCPFirstName' => 'HCP First',
                'HCPLastName' => 'HCP Last',
                'HCPPhone' => '',
                'HCPEmail' => '',
                'HCPAddress' => '',
                'PatientsHC' => 'No',
                'HCPCity' => '',
                'HCPZip' => '',
                'HCPState' => '',
                'HCPType' => '',
                'HCPFacilityName' => 'Test Practice',
                'HCPPermission' => 'Yes',
                'PatientFirstName' => 'John',
                'PatientLastName' => 'Doe',
                'PatientDOB' => '1990-01-01',
                'PatientAge' => '30',
                'PatientGender' => 'Female',
                'isPatientPregnant' => 'Yes',
                'GestationOrLMP' => '10 weeks',
                'isFemale' => 'false',
                'ifPregnantYes' => 'false',
                'RepAddressLine2' => 'TestAddress2'
            },
            'stage4' => new List<Object>{
                new Map<Object,Object>{
                    'values' => new Map<Object, Object>{
                        'Product' => 'Test Product',
                        'ProductId' => 'OtherProductField',
                        'CatalogNumber' => 'CAT123',
                        'DoseFrequency' => 'Once Daily',
                        'ExpirationDate' => '2025-12-31',
                        'LotNumber' => 'LOT123',
                        'SerialNumber' => 'SER123',
                        'ModelNumber' => 'MOD123',
                        'UniqueIdentifier' => 'UID123',
                        'OperatorOfDevice' => 'Unknown'
                    }, 'id' => '1',
                    'values' => new Map<Object, Object>{
                        'Product' => 'Test Product',
                        'ProductId' => 'OtherProductField',
                        'CatalogNumber' => 'CAT123',
                        'DoseFrequency' => 'Once Daily',
                        'ExpirationDate' => '2025-12-31',
                        'LotNumber' => 'LOT123',
                        'SerialNumber' => 'SER123',
                        'ModelNumber' => 'MOD123',
                        'UniqueIdentifier' => 'UID123',
                        'OperatorOfDevice' => 'Unknown'
                    }, 'id' => '2'
                }
            },
            'stage5' => new Map<Object, Object>{
                'MPI' => 'Yes',
                'AE' => 'Test AE Description',
                'CAD' => '2023-11-07',
                'AOD' => ''
            },
            'stage6' => new Map<Object, Object>{
                'patientdeath' => 'Yes',
                'causedeath' => 'Cancer',
                'deathdate' => 'Yesterday',
                'AEhospitilization' => 'Yes',
                'illness' => 'Yes',
                'disability' => 'Yes',
                'birthdefect' => 'Yes',
                'cancer' => 'Yes',
                'overdose' => 'Yes',
                'intervention' => 'Yes',
                'indication' => 'Test indication',
                'roa' => 'Test Route of Administration',
                'TherapySD' => 'Test Date',
                'therapyque' => 'Yes',
                'TherapyED' => 'Test End Date',
                'dechallenge' => 'Unknown',
                'rechallenge' => 'Unknown',
                'sma' => 'Test Sought Medical Attention',
                'Treatmentque' => 'Yes',
                'isTreatment' => 'Test Treatment',
                'presentstatus' => 'Recovered',
                'RecoveryDate'  => 'Test 02-11-2017',
                'CM' => 'Test Concomitant Medication',
                'PMH' => 'Test Patient Medical History',
                'DRA' => 'Test Drug Reaction Allergies',
                'LDSP' => 'Test Lab Diagnostics'
            }
        };

        return caseDetailsHCP;
    }

    public static Map<String,Object> createCaseDetail2(){
        Id aeRecordType = getRecordTypeId();
        Account acc= new Account(FirstName = 'Gayle',LastName = 'Haa');
        insert acc;
        Map<String, Object> caseDetail = createCaseDetail();
        Map<Object, Object> merckEmpMap= new Map<Object, Object>{
            'Adverse_Event_MVN' => aeRecordType,
            'WinId' => '1251634',
            'EmployeeId' => acc.Id,
            'FirstName' => 'Gayle',
            'LastName' => 'Haa',
            'Phone' => '(000) 000-0000',
            'Email' => 'gbh914@gmail.com.invalid',
            'Credential' => 'M.D.',
            'Address1' => '680 CENTRE ST',
            'City' => 'BROCKTON',
            'State' => 'MA',
            'Country' => 'US',
            'Zip' => '02302',
            'FieldBased' => 'no'
        };
        caseDetail.put('stage2', merckEmpMap);
        caseDetail.put('stage1', new Map<Object,Object>{'userChoice' => 'Merck Employee'});
        Map<Object, Object> stage3 = (Map<Object, Object>)caseDetail.get('stage3');
       stage3.put('ReporterType', 'Patient');
        stage3.put('ReporterTypeLabel', 'Patient');
        return caseDetail;
    }

    public static Map<String, Object> createCaseDetail3(){

        Map<String, Object> caseDetails = new Map<String, Object>{
            'stage2' => new Map<Object, Object>{
                'PSPProgramName' => 'Test Program',
                'PSPCompany'=> 'Test Company',
                'PSPNumber' => '1456723',
                'PSPNumberOther' => 'OtherProgram',
                'PSPProgramOther'=> 'OtherCompany',  
                'Agentname' => 'AgentTest'
            }
        };
        return caseDetails;
    }

    public static List<Object> createFileObjectList(){

        Blob testPdf = blob.toPDF('Test AE Portal PDF');
        String testBase64 = EncodingUtil.base64Encode(testPdf); 

        List<Object> uploadedFiles = new List<Object>{
            new Map<Object,Object>{
                'id' => '1700732243216_0',
                'base64' => testBase64,
                'filename' => 'Test AE Portal.pdf',
                'size' => '0.03'
            }
        };
        return uploadedFiles;
    }

    public static MSD_CORE_ae_CaseController.FileData createFileData(){
        MSD_CORE_ae_CaseController.FileData file = new MSD_CORE_ae_CaseController.FileData();
        Blob testPdf = blob.valueOf('Test AE Portal PDF');
        file.fileBlob = testPdf;
        file.fileName = 'Test AE Portal.pdf';
        return file;
    }

    static String getRecordTypeId() {
        List<RecordType> recordTypes = [SELECT Id FROM RecordType WHERE DeveloperName = 'Adverse_Event_MVN' AND SobjectType ='Case' LIMIT 1];
        if(recordTypes.size()>0){
            return recordTypes[0].Id;
        }
        return null;
    }

    public static Account setupEmployee() {
        RecordType rtEmployee = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Employee_MVN' LIMIT 1];
        Account testAccount = new Account(
            External_ID_vod__c = 'WIN-6341251',
            RecordTypeId = rtEmployee.Id,
            LastName = 'TestAccount',
            PersonEmail = 'testacc@test.com',
            Preferred_First_Name_MRK__c = 'TestFirstName',
            Preferred_Last_Name_MRK__c = 'TestLastName',
            Phone = '1234567890',
            Class_of_Trade_MRK__c = 'Test Class of Trade',
            MSD_CORE_Primary_Address_Line_1__c = 'Test Address Line 1',
            MSD_CORE_Primary_Address_Line_2__c = 'Test Address Line 2',
            MSD_CORE_Primary_Zip__c = '12345',
            MSD_CORE_Primary_City__c = 'Test City',
            MSD_CORE_Primary_State__c = 'CA'
        );
        insert testAccount;
        return testAccount;
    } 

}