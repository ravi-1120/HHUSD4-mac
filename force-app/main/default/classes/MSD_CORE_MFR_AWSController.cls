public class MSD_CORE_MFR_AWSController {
    
    public static String generateSingedURL(String resourceURL){
        try{
            //resourceURL = '/133572_1_0_rendition_viewable_rendition__v.pdf';
            //resourceURL = '/133575/1/0/Renditions/133575_1_0_rendition_viewable_rendition__v';
            MFR_Site__mdt contConDetails = MSD_CORE_MFR_AWSController.loadContentConnectorDetails();
            //key pair id from S3
            String Private_Key = contConDetails.CC_PRIVATE_KEY__c; //MSD_CORE_MFR_AWSController.getKey();
            Blob privateKey = EncodingUtil.base64Decode(Private_Key);        
            
            String keyPairId = contConDetails.CC_KEY_PAIR_ID__c;//'K2256Q2KWMJ4K4';
            
            //cloudfront full path to sign
            String urlToSign = contConDetails.domainURL__c;
                //'https://public-store-uat.hhcontentconnectortest.com/133575/1/0/Renditions/133575_1_0_rendition_viewable_rendition__v';
			urlToSign = urlToSign+resourceURL;
            //Expiry time
            Datetime dt      = Datetime.now();
            Long longTime    = dt.getTime();
            Long expiryLong  = (longTime / 1000) + 3600;
            String Expiry    = String.valueOf(expiryLong);
        
            //Policy Statement for the cloudfront full path with the expiry time
            String policyStatementText = '{"Statement":[{"Resource":"' + urlToSign + '","Condition":{"DateLessThan":{"AWS:EpochTime":' + Expiry + '}}}]}';
        
            String policyStatement = EncodingUtil.base64Encode(Blob.valueOf(policyStatementText ));
            policyStatement = policyStatement.replace('+','-');
            policyStatement = policyStatement.replace('=','_');
            policyStatement = policyStatement.replace('/','~');
        
            //genarate the signature
            Blob mac = Crypto.sign('RSA-SHA1', blob.valueof(policyStatementText),privateKey );
            String signed = EncodingUtil.base64Encode(mac);        
            signed = signed.replace('+','-');
            signed = signed.replace('=','_');
            signed = signed.replace('/','~');
        
            String signedURL = urlToSign + '?' + 'Policy=' + policyStatement + '&Signature=' + signed  + '&Key-Pair-Id=' + keyPairId ;
            System.debug(signedURL);
            return signedURL;
        }catch(Exception ex){
            System.debug(ex);
            return ex.getMessage();
        }
    }
    public static MFR_Site__mdt loadContentConnectorDetails(){
        MFR_Site__mdt conConnector;
        MFR_Site__mdt [] apiNames = [SELECT Id, CC_KEY_PAIR_ID__c ,CC_PRIVATE_KEY__c ,domainURL__c   from MFR_Site__mdt where DeveloperName ='Content_Connector'];
        if(apiNames.size()>0){
            conConnector = apiNames[0];
        }
        return conConnector;
    }
    /*
    public static String getKey(){
        String pkey = 'MIIEpgIBAAKCAQEAz/PkRKSmcsk2LyQClBghnU8uiFDepEpsbvp0TASh05YF9qMDnkzT4vambWmL9P1cwNC0n/qf8FmvqGHISYVugQbxePR5LHdH060NFfTruzY4Y506cBqp/n3Zmrk2q3VO+nGjvPrst+8qSPPmrJeXF5H0PBNQucLEz5UK4RwktNITbYEQpAh/k7iZ/aKB3ycP2wyprj6nM9Jn7rUE1SqeoPboyPn+QTLpkjlrZcw64Y5dgUgBP6uzxETuwSTrSvTepn1ogEnxExkANm4hD2ROwqAOl65UrEpbtWZuw9GeOBmcpc04UQMF+TmLb6XaASm7rk48E6AD3NtIo+ILoNVoxwIDAQABAoIBAQC1mbduepshArZe1IOr8KbqSYvJX1YPAy9Oe0m0WRc5P3pVuGYgh9dCDUOpqNKgT+IAQEJ8stGZg7jywvG1wuCNrRKTHmvzePcw057p3ck+5Eq6M0QlQiPSKvUtOTGU6gzeiP8EudyfhCzZKKX5cyhvXPZ8wCFvF7fnz7CAhaNIg9k8TB97Ol/qt0Sx2lkVOIh2d8WRlCJNzegVUSi793XDXK34ZXS/veCkjZTFDESlBRxu0ErFKtgIfkJFDsOBSuiBUoPqHq30cQwuRtq+tTHS0quWg9hCmaMaw3fHSqMud7sUOnpRcNXPFyyj610Gr7uMXjbbTft4UYPjGvhe1KKBAoGBAPCYU/O5wegzi8MIxAeYD3hvvgQOjCiMdn1ETCZJeokKcAT8kEKrK64Pa26mQ6s6hYa03jOP/OiGLySv1xelbVtCTU5DBGJyVKnAjHPHzc2Sdx3FQmJvrsDkpJQjJonPaz3fYGTiA1wml8vL8+ceRXHPD+Jlvx4UoE91H9RV+AwFAoGBAN1EgzqC9WII1GJCYcG0cP2fjRKCT5Hln2EYzFuo9VrRWF1MgUqgwHMb02KBsZkX/1BgJSBlFV0nzJkr7D2jmqZVZUEdss5PU51jQpyUTzheA+Aa/phjv0q19hZpHtSZzL565UguCUrsaPFCHJTWGHOvdrtT0ulVFyJ0+OoZEQdbAoGBAJYOu9W4VstnUtUq43DFE2kPcJkBJcOoj8JjVYdPruBIJUPG7obWUaD3Nw9FHdFu55bzud65AIlaH48nKOUzpTgU6zhTrilkm49ga3lO9fowTqC/xj60326pbEiEf+XV+1IUvv9Mw8G2xFg0dYQBqlhoR8TxprixLqdAKsD5eYKtAoGBAJd9vvMikmqKbQ7RMCj1J58dy/JuMZhMRHCwD8p5xXJmfj9yj9rOcLTeyj1ZWoTcvzsCeKjTTGs5QoVkYxxYlRtowChy8ub5vN+3A/Y8PHj1NWYMVV90e5XlOxVg53Db1Chd7/kZO9eGQNtdTkBAzQD3kyzyWSbT0UEQIRP2EYidAoGBAMPkaqCbKFPHw+McY61ZKCIAl4bv4dGvJvz2aEqSI+2DR4Q86JhD0grrXmy0U/B/LG0zEskDNQcLS75vS4knPpeS62n1lV6QPEioilmE7oQgsgH6hiYCmJtbSCuOfx6B1+95lavP/HT3Iimh7uGtNmygiuVDOJT853lhCOEGoQeY';
        return pkey;
    }*/
}