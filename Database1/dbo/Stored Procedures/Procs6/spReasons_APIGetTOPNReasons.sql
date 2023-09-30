CREATE PROCEDURE [dbo].[spReasons_APIGetTOPNReasons]
@PUId int,
@ShowTopNBars int = 5,
@TreeType int = 1,
@EventType Int = 2
AS 
/***********************************************************/
/******** Copyright 2004 GE Fanuc International Inc.********/
/****************** All Rights Reserved ********************/
/***********************************************************/


BEGIN
    IF @PUId IS NULL
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'PUId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = '',
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
    IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @PUId)
        BEGIN
            SELECT Code = 'InvalidData',
                   Error = 'Unit not found',
                   ErrorType = 'ParameterResourceNotFound',
                   PropertyName1 = 'PUId',
                   PropertyName2 = '',
                   PropertyName3 = '',
                   PropertyName4 = '',
                   PropertyValue1 = @PUId,
                   PropertyValue2 = '',
                   PropertyValue3 = '',
                   PropertyValue4 = ''
            RETURN
        END
 	 Declare @MasterUnit int
 	 SET @TreeType = coalesce(@TreeType,1) 
 	 SELECT @MasterUnit = Coalesce(Master_Unit,@PUId) From Prod_Units_Base WHERE PU_Id = @PUId
 	 IF @TreeType = 1 
 	 BEGIN
 	  	 DECLARE @temptable table (tedet_id int,ertd_id int,erc_id int)
 	  	 DECLARE @temptable1 table (ertd_id int)
 	  	  	 
			 IF @EventType =2
			    BEGIN
			    INSERT INTO @temptable(tedet_id,ertd_id)
			    
					 SELECT TOP 1000 ted.tedet_id,ted.Event_Reason_Tree_Data_Id FROM dbo.Timed_Event_Details ted
					 WHERE PU_id = @MasterUnit And (Source_PU_Id = @PUId Or @PUId = @MasterUnit) and ted.Event_Reason_Tree_Data_Id is not null
					 ORDER BY ted.Start_Time  DESC
				END 
			IF @EventType =3
			    BEGIN 
			    INSERT INTO @temptable(tedet_id,ertd_id)
					 SELECT TOP 1000 ted.WED_Id,ted.Event_Reason_Tree_Data_Id FROM dbo.Waste_Event_Details ted
					 WHERE PU_id = @MasterUnit And (Source_PU_Id = @PUId Or @PUId = @MasterUnit) and ted.Event_Reason_Tree_Data_Id is not null
					 ORDER BY ted.TIMESTAMP  DESC
				END 	
 	  	  	 INSERT INTO @temptable1(ertd_id)
 	  	  	 SELECT TOP (@ShowTopNBars) ertd_id FROM @temptable where ertd_id is not null 
 	  	  	 GROUP BY ertd_id ORDER BY count(*) DESC

             SELECT l1.Event_Reason_Id as  'level1id',
                    l1.Event_Reason_Name as 'level1name',
                    l1.Comment_Required as  'level1commentRequired',
                    l2.Event_Reason_Id as 'level2id',
                    l2.Event_Reason_Name as  'level2name',
                    l2.Comment_Required as  'level2commentRequired',
                    l3.Event_Reason_Id as 'level3id',
                    l3.Event_Reason_Name as 'level3name',
                    l3.Comment_Required as  'level3commentRequired',
                    l4.Event_Reason_Id as 'level4id',
                    l4.Event_Reason_Name as 'level4name',
                    l4.Comment_Required as  'level4commentRequired'
             FROM dbo.Event_Reason_Tree_Data  ertd
                      JOIN dbo.Event_Reasons l1 on ertd.Level1_Id  = l1.Event_Reason_Id
                      LEFT JOIN dbo.Event_Reasons l2 on ertd.Level2_Id =  l2.Event_Reason_Id
                      LEFT JOIN  dbo.Event_Reasons l3 on ertd.Level3_Id = l3.Event_Reason_Id
                      LEFT JOIN dbo.Event_Reasons l4 on ertd.Level4_Id = l4.Event_Reason_Id
             WHERE ertd.Event_Reason_Tree_Data_Id in (SELECT ertd_id  FROM @temptable1)


 	 END
 	 ELSE IF @TreeType = 2
 	 BEGIN
 	  	 DECLARE @actiontable table (actionreasonstring nvarchar(max))
 	  	 DECLARE @TOPNActionTable table(id int IDENTITY(1,1),total int,actionreasonstring nvarchar(max))
 	  	 DECLARE @actiondestring table(id int,val NVARCHAR(MAX))
 	  	 DECLARE @Outputtable table (id int identity(1,1),level1id int,level2id int,level3id int,level4id int)
 	  	 
 	  	  IF @EventType =2
			    BEGIN
		 INSERT INTO @actiontable (actionreasonstring)
 	  	
		SELECT TOP 1000 concat( ISNULL(Action_Level1, '-1'), ',', ISNULL(Action_Level2, '-1'), ',', ISNULL(Action_Level3, '-1'), ',', ISNULL(Action_Level4, '-1')) FROM dbo.timed_event_details 
 	  	 WHERE PU_id = @MasterUnit And (Source_PU_Id = @PUId Or @PUId = @MasterUnit) AND Action_Level1 IS NOT NULL ORDER BY Start_Time  DESC
 	  	 END
		 
		  IF @EventType =3
			    BEGIN
		 INSERT INTO @actiontable (actionreasonstring)
 	  	
		SELECT TOP 1000 concat( ISNULL(Action_Level1, '-1'), ',', ISNULL(Action_Level2, '-1'), ',', ISNULL(Action_Level3, '-1'), ',', ISNULL(Action_Level4, '-1')) FROM dbo.waste_event_details 
 	  	 WHERE PU_id = @MasterUnit And (Source_PU_Id = @PUId Or @PUId = @MasterUnit) AND Action_Level1 IS NOT NULL ORDER BY TIMESTAMP  DESC
 	  	 END
		 
 	  	 
 	  	 INSERT INTO @TOPNActionTable(total,actionreasonstring)
 	  	 SELECT TOP (@ShowTopNBars) count(actionreasonstring) as count,actionreasonstring  FROM @actiontable GROUP BY actionreasonstring ORDER BY count DESC
 	  	  	 
 	  	 DECLARE @currentTOProw int,@currentactionstring nvarchar(max)
 	  	 DECLARE @actiondestringid int,@localId int, @MaxRow int
 	  	 SELECT @MaxRow = Count(*) from @TOPNActionTable
 	  	 SET @currentTOProw = 1
 	  	 WHILE @currentTOProw <= @MaxRow
 	  	  	 BEGIN
 	  	  	  	 SELECT @currentactionstring = actionreasonstring FROM @TOPNActionTable WHERE id  = @currentTOProw
 	  	  	  	 INSERT INTO @actiondestring(id,val)
 	  	  	  	 SELECT * FROM fnMESCore_Split(@currentactionstring,',')
 	  	  	  	 SET @actiondestringid =1
 	  	  	  	 WHILE @actiondestringid <=4
 	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	 IF @actiondestringid=1 
 	  	  	  	  	  	  	  	 BEGIN 
 	  	  	  	  	  	  	  	  	 INSERT INTO @Outputtable(level1id)
 	  	  	  	  	  	  	  	  	 SELECT val FROM @actiondestring  WHERE id=@actiondestringid
 	  	  	  	  	  	  	  	  	 SELECT @localid=Max(id) FROM @Outputtable
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	 ELSE IF @actiondestringid=2
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 UPDATE @Outputtable set level2id = (SELECT val FROM @actiondestring  WHERE id=@actiondestringid and val!='-1') WHERE id=@localId
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 ELSE IF @actiondestringid=3
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 UPDATE @Outputtable set level3id = (SELECT val FROM @actiondestring  WHERE id=@actiondestringid and val!='-1') WHERE id=@localId
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	 ELSE IF @actiondestringid=4
 	  	  	  	  	  	  	  	 BEGIN
 	  	  	  	  	  	  	  	  	 UPDATE @Outputtable set level4id = (SELECT val FROM @actiondestring  WHERE id=@actiondestringid and val!='-1') WHERE id=@localId
 	  	  	  	  	  	  	  	 END
 	  	  	  	  	  	  	  	 SET @actiondestringid  = @actiondestringid +1
 	  	  	  	  	 END
 	  	  	  	  	 DELETE FROM @actiondestring
 	  	  	  	  	 SET @currentTOProw = @currentTOProw+1
 	  	  	 END

             SELECT l1.Event_Reason_Id as  'level1id',
                    l1.Event_Reason_Name as 'level1name',
                    l1.Comment_Required as  'level1commentRequired',
                    l2.Event_Reason_Id as 'level2id',
                    l2.Event_Reason_Name as  'level2name',
                    l2.Comment_Required as  'level2commentRequired',
                    l3.Event_Reason_Id as 'level3id',
                    l3.Event_Reason_Name as 'level3name',
                    l3.Comment_Required as  'level3commentRequired',
                    l4.Event_Reason_Id as 'level4id',
                    l4.Event_Reason_Name as 'level4name',
                    l4.Comment_Required as  'level4commentRequired'
             FROM @Outputtable  ertd
                      JOIN dbo.Event_Reasons l1 on ertd.level1id  = l1.Event_Reason_Id
                      LEFT JOIN dbo.Event_Reasons l2 on ertd.Level2Id =  l2.Event_Reason_Id
                      LEFT JOIN  dbo.Event_Reasons l3 on ertd.Level3Id = l3.Event_Reason_Id
                      LEFT JOIN dbo.Event_Reasons l4 on ertd.Level4Id = l4.Event_Reason_Id
 	 END
END
