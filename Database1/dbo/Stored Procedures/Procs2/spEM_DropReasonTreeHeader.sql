CREATE PROCEDURE dbo.spEM_DropReasonTreeHeader
  @EventReasonLevel_Id int,
  @User_Id int
 AS
  --
  -- Return Codes:
  --
  --       0 = Success
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropReasonTreeHeader',
                 convert(nVarChar(10),@EventReasonLevel_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
BEGIN TRANSACTION
  --
  -- Delete all Reasons Data For this level and Greater
  --
DECLARE @ReturnCode     int,
        @EventReasonData_Id        int, 
        @SaveReturnCode int, 
        @Reason_Level   int,
        @TreeName_Id          int
SELECT @SaveReturnCode = 0
  --
  -- 
  --
    SELECT @Reason_Level = Reason_Level, @TreeName_Id = Tree_Name_Id 
      FROM Event_Reason_Level_Headers
      WHERE Event_Reason_Level_Header_Id = @EventReasonLevel_Id
    DECLARE Reason_Cursor CURSOR
    FOR SELECT Event_Reason_Tree_Data_Id FROM Event_Reason_Tree_Data
          WHERE Tree_Name_Id = @TreeName_Id and Event_Reason_Level = @Reason_Level 
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
 	   SELECT @ReturnCode = 50104
         END
  DEALLOCATE Reason_Cursor 
 -- If successful, delete the Tree Name to be dropped and commit the transaction.
  -- Otherwise, roll the transaction back.
  --
  IF @ReturnCode = 0
    BEGIN
      -- Delete the Tree and Headers
      DELETE FROM Event_Reason_Level_Headers
          WHERE Tree_Name_Id = @TreeName_Id AND Reason_Level >= @Reason_Level 
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
