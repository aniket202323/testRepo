CREATE PROCEDURE dbo.spEM_PutSpecVariableData
  @Var_Id            int,
  @Spec_Id           int,
  @User_Id int
 AS
-- *********  Spem_PutVarSheetData has Spec Link Logic also ***********
  DECLARE @Insert_Id integer,
   	  	   @Now DateTime
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutSpecVariableData',  
 	  	 Convert(nVarChar(10),@Var_Id)  + ','  +
 	  	 Convert(nVarChar(10),@Spec_Id)  + ','  +
 	     	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT @Now = Dateadd(millisecond,-Datepart(millisecond,@Now),@Now)
  SELECT Var_Id = Var_Id, PU_Id = PU_Id
    INTO #Var
    FROM Variables WHERE PVar_Id = @Var_Id OR Var_Id = @Var_Id
  BEGIN TRANSACTION
  UPDATE Variables_Base
    SET Spec_Id = @Spec_Id
    WHERE Var_Id IN (SELECT Var_Id FROM #Var)
  DELETE FROM Trans_Variables
    WHERE (Var_Id IN (SELECT Var_Id FROM #Var)) AND
              (Trans_Id IN (SELECT Trans_Id FROM Transactions WHERE Approved_On IS NULL))
      --
      -- Expire any current and delete any future variable specifications for the
      -- variable.
      --
   DELETE FROM Var_Specs
        WHERE (Var_Id IN (SELECT Var_Id FROM #Var)) AND
              (Effective_Date >= @Now)
   UPDATE Var_Specs SET Expiration_Date = @Now,AS_Id = Null
        WHERE (Var_Id IN (SELECT Var_Id FROM #Var)) AND
              (Effective_Date < @Now) AND
              ((Expiration_Date IS NULL) OR
               ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
  --
  -- If we have no specification, finish.
  --
  IF (@Spec_Id IS NULL) GOTO DropAndFinish
  --
  -- Update our variable specs with active specs.
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
           uc.Prod_Id,
           Effective_Date = CASE
                            WHEN a.Effective_Date < @Now THEN @Now
                              ELSE a.Effective_Date
                            END,
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
      FROM #Var v
      JOIN Prod_Units u ON (v.PU_Id = u.PU_Id)
      JOIN PU_Characteristics uc ON (uc.PU_Id = CASE WHEN u.Master_Unit IS NULL THEN u.PU_Id ELSE u.Master_Unit END)
      JOIN Active_Specs a ON (a.Spec_Id = @Spec_Id) AND (a.Char_Id = uc.Char_Id) AND
                             ((a.Expiration_Date IS NULL) OR ((a.Expiration_Date > @Now) AND (a.Expiration_Date IS NOT NULL)))
  --
  -- Drop our temporary table.
  --
DropAndFinish:
  DROP TABLE #Var
  --
  -- Commit the transaction and return success.
  --
Finish:
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
