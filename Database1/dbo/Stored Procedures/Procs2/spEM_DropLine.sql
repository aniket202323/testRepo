CREATE PROCEDURE dbo.spEM_DropLine
  @PL_Id int,
  @User_Id int
 AS
  --
  -- Return Codes:
  --
  --       0 = Success
  --   50101 = Variable Error
  --   50102 = Group Error
  --   50103 = Unit Error
  --   50104 = Line Error
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropLine',
                 convert(nVarChar(10),@PL_Id) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Delete all units under
  -- the production line to be deleted.
  --
DECLARE @LinReturnCode int, @LinUnt_Id int, @SaveLinCode int
SELECT @SaveLinCode = 0
  --
  -- 
  --
    DECLARE Lin_Cursor CURSOR
    FOR SELECT PU_Id FROM Prod_Units WHERE PL_Id = @PL_Id
    FOR READ ONLY
    OPEN Lin_Cursor
    Fetch_Next_LinUnt:
    FETCH NEXT FROM Lin_Cursor INTO @LinUnt_Id
    IF @@FETCH_STATUS = 0
    BEGIN
 	 EXECUTE @LinReturnCode = spEM_DropUnit @LinUnt_Id,@User_Id
 	 IF @LinReturnCode = 0 GOTO Fetch_Next_LinUnt
        ELSE
          BEGIN
           SELECT @SaveLinCode = @LinReturnCode
           GOTO Fetch_Next_LinUnt
          END
    END
    ELSE IF @@FETCH_STATUS = -1
 	    SELECT @LinReturnCode = 0
         ELSE
 	  BEGIN
 	   RAISERROR('Fetch error for Lin_Cursor (@@FETCH_STATUS = %d).', 11, -1,
 	     @@FETCH_STATUS)
 	   SELECT @LinReturnCode = 50104
         END
  DEALLOCATE Lin_Cursor
 -- If successful, delete the production Line to be dropped and commit the transaction.
  -- Otherwise, roll the transaction back.
  --
  IF @LinReturnCode = 0
    BEGIN
      -- Delete the production line 
 	   Update Sheets set pl_Id = null,Is_Active = 0 where PL_Id = @PL_Id
 	   Declare @PathId Int
 	   Declare Path_Cursor Cursor For Select Path_Id from Prdexec_Paths Where PL_Id = @PL_Id
 	   Open Path_Cursor
 	 PathLoop:
 	   Fetch next from Path_Cursor InTo @PathId
 	   If @@Fetch_Status = 0
 	  	 Begin
 	  	   Execute spEMEPC_PutExecPaths Null,'Deleting Line','Deleting Line',0,1,1,1,@User_Id,@PathId
 	  	   goto PathLoop
 	  	 End
 	   Close Path_Cursor
 	   Deallocate Path_Cursor
      DELETE FROM PAEquipment_Aspect_SOAEquipment   WHERE PL_Id = @PL_Id
      DELETE FROM Prod_Lines_Base   WHERE PL_Id = @PL_Id
    END
   IF @SaveLinCode = 0 SELECT @SaveLinCode = @LinReturnCode
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = @SaveLinCode
     WHERE Audit_Trail_Id = @Insert_Id
RETURN(@SaveLinCode)
