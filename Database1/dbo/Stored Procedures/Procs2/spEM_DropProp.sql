CREATE PROCEDURE dbo.spEM_DropProp
  @Prop_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Begin a transaction.
  --
  DECLARE @Char_Id int,
          @Spec_Id int,
          @ReturnCode int
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropProp',
                 convert(nVarChar(10),@Prop_Id)  + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Determine the characteristics and specifications that apply to this
  -- property.
  --
  SELECT Char_Id INTO #C FROM Characteristics WHERE Prop_Id = @Prop_Id
  --
  -- Drop Characteristics
  --
  DECLARE Char_Cursor CURSOR FOR SELECT Char_Id FROM #C
  FOR READ ONLY
  OPEN Char_Cursor
  Fetch_Next_Char:
  FETCH NEXT FROM Char_Cursor INTO @Char_Id
  IF @@FETCH_STATUS = 0
    BEGIN
      EXECUTE @ReturnCode = spEM_DropChar @Char_Id,@User_Id
      IF @ReturnCode = 0  GOTO Fetch_Next_Char
      ELSE
        BEGIN
          DEALLOCATE Char_Cursor
          DROP TABLE #C
           UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2
 	  WHERE Audit_Trail_Id = @Insert_Id
         Return(2)
        END
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error for Char_Cursor (@@FETCH_STATUS = %d).', 11, -1,
       @@FETCH_STATUS)
      DEALLOCATE Char_Cursor
      DROP TABLE #C
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2
 	  WHERE Audit_Trail_Id = @Insert_Id
      RETURN(2)
    END
  DEALLOCATE Char_Cursor
  DROP TABLE #C
  --
  -- Drop Specifications
  --
  SELECT Spec_Id INTO #S FROM Specifications WHERE Prop_Id = @Prop_Id
  DECLARE Spec_Cursor CURSOR FOR SELECT Spec_Id FROM #S
  FOR READ ONLY
  OPEN Spec_Cursor
  Fetch_Next_Spec:
  FETCH NEXT FROM Spec_Cursor INTO @Spec_Id
  IF @@FETCH_STATUS = 0
    BEGIN
      EXECUTE @ReturnCode = spEM_DropSpec @Spec_Id,@User_Id
      IF @ReturnCode = 0  GOTO Fetch_Next_Spec
      ELSE
        BEGIN
          DEALLOCATE Spec_Cursor
          DROP TABLE #S
          UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 3
 	  WHERE Audit_Trail_Id = @Insert_Id
          Return(3)
        END
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error for Spec_Cursor (@@FETCH_STATUS = %d).', 11, -1,
       @@FETCH_STATUS)
      DEALLOCATE Spec_Cursor
      DROP TABLE #S
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 3
 	  WHERE Audit_Trail_Id = @Insert_Id
      RETURN(3)
    END
  DEALLOCATE Spec_Cursor
  DROP TABLE #S
  --
  -- Drop Characteristic Groups
  --
   DELETE FROM Characteristic_Groups WHERE Prop_Id = @Prop_Id
  --
  -- Delete Property
  --
   DELETE FROM Trans_Characteristics WHERE Prop_Id = @Prop_Id
   DELETE FROM Product_Properties WHERE Prop_Id = @Prop_Id
   COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
