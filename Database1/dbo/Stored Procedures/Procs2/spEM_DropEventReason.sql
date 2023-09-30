Create Procedure dbo.spEM_DropEventReason
  @EventReason_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Frist Delete the event reason tree data.
  --
  -- Collect all levels to be removed Save level # for delete in reverse order
 DECLARE @LevelCounter        int,
         @EventReasonData_Id  int,
         @ReturnCode          int,
         @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropEventReason',
                 convert(nVarChar(10),@EventReason_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
SELECT Event_Reason_Tree_Data_Id,Event_Reason_Level into #tempER from Event_Reason_Tree_Data
   WHERE Event_Reason_Id = @EventReason_Id
 DECLARE ER_Cursor CURSOR
    FOR SELECT Event_Reason_Tree_Data_Id FROM #tempER order by Event_Reason_Level desc
    FOR READ ONLY
    OPEN ER_Cursor
    Fetch_Next_ERDId:
    FETCH NEXT FROM ER_Cursor INTO @EventReasonData_Id
    IF @@FETCH_STATUS = 0
    BEGIN
      EXECUTE @ReturnCode =  spEM_DropEventReasonTreeData @EventReasonData_Id,@User_Id
      IF @ReturnCode = 0 GOTO Fetch_Next_ERDId
    END
    ELSE IF @@FETCH_STATUS = -1
  	    SELECT @ReturnCode = 0           
         ELSE
 	   BEGIN
  	     RAISERROR('Fetch error for Var_Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	      @@FETCH_STATUS)
  	     SELECT @ReturnCode = 1           
          END
DEALLOCATE ER_Cursor 
drop table #tempER
IF @ReturnCode = 0
-- need to delete detail
   DELETE FROM Event_Reasons WHERE Event_Reason_Id = @EventReason_Id
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = @ReturnCode
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(@ReturnCode)
