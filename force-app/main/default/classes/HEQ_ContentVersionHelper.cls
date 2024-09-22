public class HEQ_ContentVersionHelper {

    public static void uploadFileWithThumbnail(String fileName, Blob fileBody) {
        // Step 1: Insert the file into ContentVersion
        ContentVersion contentVersion = new ContentVersion();
        contentVersion.Title = fileName;
        contentVersion.PathOnClient = fileName;
        contentVersion.VersionData = fileBody;
        insert contentVersion;

        // Step 2: Retrieve the ContentDocumentId
        contentVersion = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id];

        // Step 3: Fetch the base URL from custom metadata
        ThumbnailConfig__mdt config = [SELECT BaseURL__c FROM ThumbnailConfig__mdt LIMIT 1];
        String thumbnailUrl = config.BaseURL__c + contentVersion.Title + '.jpg';

        // Step 4: Update the ContentVersion record with the thumbnail URL
        contentVersion.ThumbnailUrl__c = thumbnailUrl;
        update contentVersion;
    }
}