CREATE PROCEDURE dbo.spEM_DropReasonTree
  @TreeName_Id int,
  @User_Id int
 AS
  --
  -- Return Codes:
  --
  --       0 = Success
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropReasonTree',convert(nVarChar(10),@TreeName_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
BEGIN TRANSACTION
  --
  -- Delete all Reasons (First level)
  --
DECLARE @ReturnCode int, @EventReasonData_Id int, @SaveReturnCode int
SELECT @SaveReturnCode = 0
  --
  -- 
  --
    DECLARE Reason_Cursor CURSOR
    FOR SELECT Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE Tree_Name_Id = @TreeName_Id and Event_Reason_Level = 1
    FOR READ ONLY
    OPEN Reason_Cursor 
    Fetch_Next_Branch:
    FETCH NEXT FROM Reason_Cursor INTO @EventReasonData_Id 
    IF @@FETCH_STATUS = 0
    BEGIN
 	 EXECUTE @ReturnCode = spEM_DropEventReasonTreeData @EventReasonData_Id ,@User_Id 
 	 IF @ReturnCode = 0 GOTO Fetch_Next_Branch
        ELSE
          BEGIN
           SELECT @SaveReturnCode = @ReturnCode 
           GOTO Fetch_Next_Branch
          END
    END
    ELSE IF @@FETCH_STATUS = -1
 	    SELECT @ReturnCode = 0
         ELSE
 	  BEGIN
 	   RAISERROR('Fetch error for Lin_Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	     @@FETCH_STATUS)
 	   SELECT @ReturnCode = 1
         END
  DEALLOCATE Reason_Cursor 
 -- If successful, delete the Tree Name to be dropped and commit the transaction.
  -- Otherwise, roll the transaction back.
  --
  IF @ReturnCode = 0
    BEGIN
      --Remove Id's from Alarm template
     Update Alarm_Templates set Cause_Tree_Id = Null,Event_Reason_Tree_Data_Id = Null
 	  	 Where Cause_Tree_Id = @TreeName_Id
     Update Alarm_Templates set Action_Tree_Id = Null
 	  	  Where Action_Tree_Id = @TreeName_Id
     Update Alarm_Template_Var_Data  set Override_Default_Cause1 = Null,Override_Default_Cause2 = Null,Override_Default_Cause3 = Null,Override_Default_Cause4 = Null,Event_Reason_Tree_Data_Id = Null
 	  	 Where  Override_Cause_Tree_Id = @TreeName_Id
     Update Alarm_Template_Var_Data  set Override_Cause_Tree_Id = Null
 	  	 Where Override_Cause_Tree_Id = @TreeName_Id
     Update Alarm_Template_Var_Data  set Override_Default_Action1 = Null,Override_Default_Action2 = Null,Override_Default_Action3 = Null,Override_Default_Action4 = Null 
 	  	 Where  Override_Action_Tree_Id = @TreeName_Id
     Update Alarm_Template_Var_Data  set Override_Action_Tree_Id = Null
 	  	  Where Override_Action_Tree_Id = @TreeName_Id
     -- Update Event Configuration
     Update Event_Subtypes Set Default_Cause1 = Null, Default_Cause2 = Null, Default_Cause3 = Null, Default_Cause4 = Null,Event_Reason_Tree_Data_Id = Null Where Action_Tree_Id = @TreeName_Id or  Cause_Tree_Id = @TreeName_Id
     Update Event_Subtypes set Cause_Tree_Id = Null Where Cause_Tree_Id = @TreeName_Id
     Update Event_Subtypes set Action_Tree_Id = Null Where Action_Tree_Id = @TreeName_Id
     -- Remove Ids from Prod_events
     Delete From Prod_Events Where Name_Id = @TreeName_Id
     -- 
      -- Delete the Tree and Headers
      DELETE FROM Event_Reason_Level_Headers  WHERE Tree_Name_Id = @TreeName_Id 
      DELETE FROM Event_Reason_Tree  WHERE Tree_Name_Id = @TreeName_Id 
      IF @@ERROR <> 0 SELECT @ReturnCode = 1
      --
      -- Commit our transaction and return success.
      --
      COMMIT TRANSACTION
    END
  ELSE ROLLBACK TRANSACTION
  IF @SaveReturnCode = 0 SELECT @SaveReturnCode = @ReturnCode 
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = @SaveReturnCode
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(@SaveReturnCode )
