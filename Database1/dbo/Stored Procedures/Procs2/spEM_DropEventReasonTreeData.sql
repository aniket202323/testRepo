CREATE PROCEDURE dbo.spEM_DropEventReasonTreeData
  @EventReasonData_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Delete the waste event reason data.
  --
  -- Collect all levels to be removed Save level # for delete in reverse order
 DECLARE @LevelCounter int,@ParentEventReasonDataId Int
 --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropEventReasonTreeData',
                 convert(nVarChar(10),@EventReasonData_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
SELECT @LevelCounter = Event_Reason_Level + 1,@ParentEventReasonDataId = Parent_Event_R_Tree_Data_Id FROM Event_Reason_Tree_Data where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
CREATE Table #tempERD (Event_Reason_Tree_Data_Id int,Event_Reason_Level int)  
insert INTO #tempERD SELECT Event_Reason_Tree_Data_Id,Event_Reason_Level FROM Event_Reason_Tree_Data where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
Next_Level:
 INSERT  #tempERD SELECT Event_Reason_Tree_Data_Id,Event_Reason_Level FROM Event_Reason_Tree_Data 
   WHERE Parent_Event_R_Tree_Data_Id in (select Event_Reason_Tree_Data_Id from #tempERD) and Event_Reason_Level = @LevelCounter 
SELECT @LevelCounter = @LevelCounter + 1
IF @LevelCounter < 5  goto Next_Level
 DECLARE ERD_Cursor CURSOR
    FOR SELECT Event_Reason_Tree_Data_Id FROM #tempERD order by Event_Reason_Level desc
    FOR READ ONLY
    OPEN ERD_Cursor
    Fetch_Next_ERDId:
    FETCH NEXT FROM ERD_Cursor INTO @EventReasonData_Id
    IF @@FETCH_STATUS = 0
    BEGIN
 	  	 UPDATE Alarm_Template_Var_Data set Event_Reason_Tree_Data_Id = null where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 UPDATE Alarm_Templates set Event_Reason_Tree_Data_Id = null where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 DELETE From Event_Reason_Category_Data where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 DELETE From Event_Reason_Category_Data where Propegated_From_ETDId = @EventReasonData_Id 
 	  	 UPDATE Event_Subtypes set Event_Reason_Tree_Data_Id = null where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 UPDATE Waste_Event_Fault set Event_Reason_Tree_Data_Id = null where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 UPDATE Timed_Event_Fault set Event_Reason_Tree_Data_Id = null where Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 DELETE FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @EventReasonData_Id 
 	  	 GOTO Fetch_Next_ERDId
    END
    ELSE IF @@FETCH_STATUS = -1
 	 BEGIN
 	  	 DEALLOCATE ERD_Cursor 
 	  	 drop table #tempERD
 	  	 IF Not Exists (SELECT 1 FROM Event_Reason_Tree_Data WHERE Parent_Event_R_Tree_Data_Id = @ParentEventReasonDataId)
 	  	 BEGIN
 	  	  	 Update Event_Reason_Tree_Data set  Bottom_Of_Tree = 1 where Event_Reason_Tree_Data_Id = @ParentEventReasonDataId
 	  	 END
 	  	 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0 WHERE Audit_Trail_Id = @Insert_Id
 	  	 RETURN (0)
 	 END
 	 ELSE
 	 BEGIN
 	  	 DEALLOCATE ERD_Cursor 
 	  	 drop table #tempERD
 	  	 RAISERROR('Fetch error for Var_Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	  	 @@FETCH_STATUS)
 	  	 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	  	 RETURN(1)
 	 END
