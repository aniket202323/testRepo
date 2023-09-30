Create Procedure dbo.spDAML_FetchReasonTree
    @TreeId 	  	 INT = NULL,
    @UnitId 	  	 INT = NULL,
    @TreeType   INT = NULL,
    @EventType  INT = NULL
AS
DECLARE
   @SelectClause VarChar(4000),
   @WhereClause VarChar(1000),
   @OrderByClause VarChar(1000),
   @TreeDesc VarChar(50),
   @TreeIdentification VarChar(50)
-- Associated Unit.  Downtime, Waste or UserDefined
IF (@UnitId <> 0 AND @UnitId IS NOT NULL) BEGIN
   -- Downtime or Waste
   IF (@EventType = 2  OR @EventType = 3) BEGIN
 	  	 -- @TreeDesc defines the type of tree
        -- @TreeIdentification tells which column to join to
 	  	 SET @TreeDesc  = CASE WHEN @EventType = 2 THEN 'Downtime '
 	  	  	  	  	  	       ELSE 'Waste '
 	  	  	  	  	  	   END
        IF (@TreeType = 1) BEGIN -- Cause Tree
 	  	  	 SET @TreeDesc = @TreeDesc + 'Cause Tree'
 	  	  	 SET @TreeIdentification = 'Name_Id'
        END
        ELSE BEGIN -- Action Tree
 	  	  	 SET @TreeDesc = @TreeDesc + 'Action Tree'
 	  	  	 SET @TreeIdentification = 'Action_Tree_Id'
        END
        SET @SelectClause = 
 	  	 'Select Description = ''' + @TreeDesc + ''',
 	  	  	 ReasonTreeId = lt.Tree_Name_Id,
 	  	  	 ReasonTreeName = t.Tree_Name,
 	  	  	 EventReasonId = lt.Event_Reason_Id,
 	  	  	 ReasonLevel1Id = IsNull(lt.Level1_Id,0),
 	  	  	 ReasonLevel1 = IsNull(er1.Event_Reason_Name,''''),
 	  	  	 ReasonLevel2Id = IsNull(lt.Level2_Id,0),
 	  	  	 ReasonLevel2 = IsNull(er2.Event_Reason_Name,''''),
 	  	  	 ReasonLevel3Id = IsNull(lt.Level3_Id,0),
 	  	  	 ReasonLevel3 = IsNull(er3.Event_Reason_Name,''''),
 	  	  	 ReasonLevel4Id = IsNull(lt.Level4_Id,0),
 	  	  	 ReasonLevel4 = IsNull(er4.Event_Reason_Name,'''')
 	  	  	 from Event_Reason_Tree_Data lt
 	  	  	 join Event_Reason_Tree t on lt.Tree_Name_Id = t.Tree_Name_Id
 	  	  	 join Prod_Events pe on pe.' + @TreeIdentification + ' = t.Tree_Name_Id
 	  	  	 left outer join Event_Reasons er1 on lt.Level1_Id = er1.Event_Reason_Id
 	  	  	 left outer join Event_Reasons er2 on lt.Level2_Id = er2.Event_Reason_Id
 	  	  	 left outer join Event_Reasons er3 on lt.Level3_Id = er3.Event_Reason_Id
 	  	  	 left outer join Event_Reasons er4 on lt.Level4_Id = er4.Event_Reason_Id '
 	  	 -- Select only the tree of the right event type from the desired unit
 	  	 SET @WhereClause = ' WHERE pe.Event_Type = ' + Convert(VarChar(10),@EventType) +
 	  	  	  	             '  AND pe.PU_Id = ' + Convert(VarChar(10), @UnitId) + ' '
 	 
 	  	 -- Order is very important because the tree structure is only apparent if the order is correct
 	  	 SET @OrderByClause = ' order by lt.Tree_Name_Id, lt.Level1_Id, lt.Level2_Id, lt.Level3_Id, lt.Level4_Id '
   END
   -- UDE
   ELSE IF (@EventType = 14) BEGIN
 	  	 -- @TreeDesc defines the type of tree
        -- @TreeIdentification tells which column to join to
        IF (@TreeType = 1) BEGIN -- Cause Tree
 	  	  	 SET @TreeDesc = ' Cause Tree'
 	  	  	 SET @TreeIdentification = 'Cause_Tree_Id'
 	  	 END
 	  	 ELSE BEGIN -- Action Tree
 	  	  	 SET @TreeDesc = ' Action Tree'
 	  	  	 SET @TreeIdentification = 'Action_Tree_Id'
 	  	 END
 	  	 SET @SelectClause = 
 	  	 'Select Description = es.Event_Subtype_Desc + ' + ''' ' + @TreeDesc + ''',
 	  	  	 ReasonTreeId = lt.Tree_Name_Id,
 	  	  	 ReasonTreeName = t.Tree_Name,
 	  	  	 EventReasonId = lt.Event_Reason_Id,
 	  	  	 ReasonLevel1Id = IsNull(lt.Level1_Id,0),
 	  	  	 ReasonLevel1 = IsNull(er1.Event_Reason_Name,''''),
 	  	  	 ReasonLevel2Id = IsNull(lt.Level2_Id,0),
 	  	  	 ReasonLevel2 = IsNull(er2.Event_Reason_Name,''''),
 	  	  	 ReasonLevel3Id = IsNull(lt.Level3_Id,0),
 	  	  	 ReasonLevel3 = IsNull(er3.Event_Reason_Name,''''),
 	  	  	 ReasonLevel4Id = IsNull(lt.Level4_Id,0),
 	  	  	 ReasonLevel4 = IsNull(er4.Event_Reason_Name,'''')
 	  	 from Event_Reason_Tree_Data lt
 	  	 join Event_Reason_Tree t on lt.Tree_Name_Id = t.Tree_Name_Id
 	  	 join Event_Subtypes es on es.' + @TreeIdentification + ' = t.Tree_Name_Id
 	  	 join Event_Configuration ec on es.Event_Subtype_Id = ec.Event_Subtype_Id 
 	  	 left outer join Event_Reasons er1 on lt.Level1_Id = er1.Event_Reason_Id
 	  	 left outer join Event_Reasons er2 on lt.Level2_Id = er2.Event_Reason_Id
 	  	 left outer join Event_Reasons er3 on lt.Level3_Id = er3.Event_Reason_Id
 	  	 left outer join Event_Reasons er4 on lt.Level4_Id = er4.Event_Reason_Id '
     -- Select only ude trees from the desired unit (There may be more than one.)
 	   SET @WhereClause = ' WHERE ec.ET_Id = ' + Convert(VarChar(10),@EventType) +
                ' AND ec.PU_Id = ' + Convert(VarChar(10), @UnitId) + ' '
      -- Order is very important because the tree structure is only apparent if the order is correct
      SET @OrderByClause = ' order by es.Event_Subtype_Desc, lt.Tree_Name_Id, lt.Level1_Id, lt.Level2_Id, lt.Level3_Id, lt.Level4_Id '
   END
   ELSE BEGIN -- No valid information, return empty dataset
 	  SET @TreeId = -1
     SET @UnitId = 0
   END
END
-- No Associated Unit. Return one tree (or all trees)
IF (@UnitId=0 OR @UnitId IS NULL) BEGIN
   SET @SelectClause = 
       'Select Description = ''Reason Tree'',
 	  	 ReasonTreeId = lt.Tree_Name_Id,
 	  	 ReasonTreeName = t.Tree_Name,
 	  	 EventReasonId = lt.Event_Reason_Id,
 	  	 ReasonLevel1Id = IsNull(lt.Level1_Id,0),
 	  	 ReasonLevel1 = IsNull(er1.Event_Reason_Name,''''),
 	  	 ReasonLevel2Id = IsNull(lt.Level2_Id,0),
 	  	 ReasonLevel2 = IsNull(er2.Event_Reason_Name,''''),
 	  	 ReasonLevel3Id = IsNull(lt.Level3_Id,0),
 	  	 ReasonLevel3 = IsNull(er3.Event_Reason_Name,''''),
 	  	 ReasonLevel4Id = IsNull(lt.Level4_Id,0),
 	  	 ReasonLevel4 = IsNull(er4.Event_Reason_Name,'''')
   from Event_Reason_Tree_Data lt
   join Event_Reason_Tree t on lt.Tree_Name_Id = t.Tree_Name_Id
   left outer join Event_Reasons er1 on lt.Level1_Id = er1.Event_Reason_Id
   left outer join Event_Reasons er2 on lt.Level2_Id = er2.Event_Reason_Id
   left outer join Event_Reasons er3 on lt.Level3_Id = er3.Event_Reason_Id
   left outer join Event_Reasons er4 on lt.Level4_Id = er4.Event_Reason_Id '
   -- If a tree is given, return only that tree; otherwise return all trees
   IF (@TreeId<>0 AND @TreeId IS NOT NULL)
      SET @WhereClause = ' WHERE lt.Tree_Name_Id = ' + Convert(VarChar(10),@TreeId)
   ELSE SET @WhereClause = ''
   -- Order is very important because the tree structure is only apparent if the order is correct
   SET @OrderByClause = ' order by lt.Tree_Name_Id, lt.Level1_Id, lt.Level2_Id, lt.Level3_Id, lt.Level4_Id '
END
-- Select sc=@SelectClause, wc = @WhereClause, oc = @OrderByClause
IF @SelectClause<>'' Execute (@SelectClause + @WhereClause + @OrderByClause)
