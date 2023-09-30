/* Called From Approve transaction now (not client)*/
CREATE PROCEDURE dbo.spEM_PutUnitCharacteristic
  @PU_Id   int,
  @Prod_Id int,
  @Prop_Id int,
  @Char_Id int,
  @User_Id int
 AS
  --
  -- Declare local variables.
  --
  DECLARE @Now         DateTime,
          @Old_Char_Id int,
          @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutUnitCharacteristic',
                Convert(nVarChar(10),@PU_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Prod_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Prop_Id) + ','  + 
 	  	 Convert(nVarChar(10),@Char_Id) + ','  + 
 	  	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Begin a transaction.
  --
  --
  -- Determine the current time and the old characteristic id.
  --
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT @Old_Char_Id = Char_Id FROM PU_Characteristics
    WHERE (Prod_Id = @Prod_Id) AND (PU_Id = @PU_Id) AND (Prop_Id = @Prop_Id)
  --
  -- Finish if the record already exists in the same state.
  --
  IF @Old_Char_Id = @Char_Id GOTO Finish
  --
  -- Expire any current variable specifications and delete any pending variable
  -- specification associated with this record that were derived from the active
  -- specifications.
  --
  Create Table #VS(VS_Id Int,Effective_Date DateTime)
  Insert into #VS (VS_Id,Effective_Date)
  SELECT v.VS_Id, v.Effective_Date
    FROM Var_Specs v
    JOIN Variables var ON (var.Var_Id = v.Var_Id) AND (var.Spec_Id IS NOT NULL)
    JOIN Prod_Units u ON (u.PU_Id = var.PU_Id) AND ((u.PU_Id = @PU_Id) OR (u.Master_Unit = @PU_Id))
    Join Specifications s on s.Prop_Id = @Prop_Id and s.Spec_Id = var.spec_Id
     WHERE   (v.Prod_Id = @Prod_Id) AND ((v.Expiration_Date IS NULL) OR  (v.Expiration_Date > @Now))
  BEGIN TRANSACTION
   DELETE FROM Var_Specs WHERE VS_Id IN (SELECT VS_Id FROM #VS WHERE Effective_Date >= @Now)
   DELETE FROM #VS WHERE Effective_Date >= @Now
   UPDATE Var_Specs SET Expiration_Date = @Now WHERE VS_Id IN (SELECT VS_Id FROM #VS)
   DROP TABLE #VS
  --
  -- If we are deleting a PU characteristic. Delete the record and finish.
  --
  IF @Char_Id IS NULL
    BEGIN
      DELETE FROM PU_Characteristics
        WHERE (Prod_Id = @Prod_Id) AND (PU_Id = @PU_Id) AND (Prop_Id = @Prop_Id)
      COMMIT TRANSACTION
      GOTO Finish
    END
  --
  -- Insert or update the PU characteristic record.
  --
  IF @Old_Char_Id IS NULL
    INSERT PU_Characteristics(PU_Id, Prod_Id, Prop_Id, Char_Id)
      VALUES(@PU_Id, @Prod_Id, @Prop_Id, @Char_Id)
  ELSE
    UPDATE PU_Characteristics
      SET Char_Id = @Char_Id
      WHERE (Prod_Id = @Prod_Id) AND (PU_Id = @PU_Id) AND (Prop_Id = @Prop_Id)
  --
  -- Copy appropriate active specification records to the variable specications table.
  --
  INSERT INTO Var_Specs(Var_Id,
                        Prod_Id,
                        Effective_Date,
                        Expiration_Date, 
                        L_Entry,
                        L_Reject,
                        L_Warning,
                        L_User,
                        Target,
                        U_User,
                        U_Warning,
                        U_Reject,
                        U_Entry,
                        L_Control,
                        T_Control,
                        U_Control,
 	  	  	  	  	  	 Test_Freq,
 	  	  	  	  	  	 Esignature_Level,
 	  	  	  	  	  	 Comment_Id,
                        AS_Id)
    SELECT v.Var_Id,
           @Prod_Id,
           Effective_Date = CASE WHEN a.Effective_Date < @Now THEN @Now ELSE a.Effective_Date END,
           a.Expiration_Date, 
           a.L_Entry,
           a.L_Reject,
           a.L_Warning,
           a.L_User,
           a.Target,
           a.U_User,
           a.U_Warning,
           a.U_Reject,
           a.U_Entry, 
 	        a.L_Control,
 	        a.T_Control,
 	        a.U_Control,
 	        a.Test_Freq,
 	  	    a.Esignature_Level,
 	        a.Comment_Id,
           a.AS_Id
      FROM Variables v
      JOIN Active_Specs a ON (a.Char_Id = @Char_Id) AND
                             (v.Spec_Id = a.Spec_Id) AND
                             ((a.Expiration_Date IS NULL) OR
                              ((a.Expiration_Date IS NOT NULL) AND
                               (a.Expiration_Date > @Now)))
      JOIN Prod_Units u ON (u.PU_Id = v.PU_Id) AND
                           ((u.PU_Id = @PU_Id) OR
                            (u.Master_Unit = @PU_Id))
  --
  -- Commit transaction and return success.
  --
     COMMIT TRANSACTION
Finish:
 UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
