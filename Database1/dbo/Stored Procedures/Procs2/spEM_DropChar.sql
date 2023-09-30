CREATE PROCEDURE dbo.spEM_DropChar
  @Char_Id int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Delcare local variables.
  --
DECLARE 	  	 @Insert_Id 	 INT,
 	  	  	 @VS_Id 	  	 INT,
 	  	  	 @Now 	  	 DateTime,
 	  	  	 @AS_Id 	  	 INT
DECLARE  @ASID TABLE (AS_Id Int)
DECLARE  @DCVS TABLE (VS_Id Int,Effective_Date DateTime)
 	  	  	 
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,
 	  	  	 @User_Id,
 	  	  	 'spEM_DropChar',
 	  	  	 convert(nVarChar(10),@Char_Id) + ','  + 
 	  	  	 Convert(nVarChar(10), @User_Id),
 	  	  	 dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @Insert_Id = Scope_Identity()
SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
INSERT @ASID (AS_Id)
 	 SELECT DISTINCT AS_Id FROM Active_Specs WHERE Char_Id = @Char_Id
  BEGIN TRANSACTION
  -- Delete Var_Specs with date > Now
  DELETE FROM 	 Var_Specs
  WHERE 	  	  	 ((Expiration_Date IS NULL) OR (Expiration_Date > @Now))
  AND 	  	  	  	 Effective_Date >= @Now
  AND 	  	  	  	 AS_Id IN (SELECT AS_Id FROM @ASID)
 -- Update current Var_Specs with date < Now
  UPDATE 	  	 Var_Specs
  SET 	  	  	 Expiration_Date = @Now,AS_Id = Null
  WHERE 	  	 ((Expiration_Date IS NULL) OR (Expiration_Date > @Now))
  AND 	  	  	 Effective_Date < @Now
  AND 	  	  	 AS_Id IN (SELECT AS_Id FROM @ASID)
--Make sure no as ids left
  Insert into @DCVS (VS_Id)
 	   SELECT 	 VS_Id
 	   FROM 	 Var_Specs
 	   WHERE 	 AS_Id IN (SELECT AS_Id FROM @ASID)
  DECLARE AS_Cursor CURSOR FOR SELECT VS_Id FROM @DCVS
  FOR READ ONLY
  OPEN AS_Cursor
  Fetch_Next_Active_Spec:
  FETCH NEXT FROM AS_Cursor INTO @VS_Id
  IF @@FETCH_STATUS = 0
    BEGIN
      UPDATE Var_Specs SET AS_Id = Null WHERE VS_Id = @VS_Id
      GOTO Fetch_Next_Active_Spec
    END
  ELSE IF @@FETCH_STATUS <> -1
    BEGIN
      RAISERROR('Fetch error for AS_Cursor (@@FETCH_STATUS = %d).', 11, -1,
       @@FETCH_STATUS)
      DEALLOCATE AS_Cursor
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  DEALLOCATE AS_Cursor
  --
  -- Drop all active specifications, production unit characteristics, and
  -- transaction properties involving the characteristic. Then, delete the
  -- actual characteristic.
  --
  DELETE FROM Active_Specs               WHERE Char_Id = @Char_Id
  DELETE FROM PU_Characteristics         WHERE Char_Id = @Char_Id
  DELETE FROM Trans_Properties           WHERE Char_Id = @Char_Id
  DELETE FROM Trans_Metric_Properties    WHERE Char_Id = @Char_Id 	 -- ECR #29444:12-19-2006
  DELETE FROM Trans_Characteristics WHERE Char_Id = @Char_Id
  DELETE FROM Product_Characteristic_Defaults WHERE Char_Id = @Char_Id
  Delete From Trans_Char_Links where To_Char_Id = @Char_Id
  Delete From Trans_Char_Links where From_Char_Id = @Char_Id
  DELETE FROM Characteristic_Group_Data  WHERE Char_Id = @Char_Id
  DELETE FROM Characteristics            WHERE Char_Id = @Char_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
