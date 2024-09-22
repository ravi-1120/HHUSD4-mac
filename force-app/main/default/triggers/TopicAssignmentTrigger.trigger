trigger TopicAssignmentTrigger on TopicAssignment (after insert) {
    
    Set<String> entityIdSet = new Set<String>();
    
    for(TopicAssignment ta : trigger.new)
    {
        if(ta.EntityType == 'Knowledge')
            entityIdSet.add(ta.EntityId);
    }
    
    if(entityIdSet.size() > 0)
    {
        List<Knowledge__kav> knowledgeList = [select id,
                                             (select id from TopicAssignments) 
                                              from Knowledge__kav
                                              where id in : entityIdSet];
    
        for(Knowledge__kav k : knowledgeList)
        {
            if(k.TopicAssignments.size() > 10)
                trigger.new[0].addError('Maximum topics allowed is 10.');
        }
    }
}