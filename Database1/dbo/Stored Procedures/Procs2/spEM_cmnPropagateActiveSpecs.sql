/************************************************************************************************************************
This sp is called from spem_IEVariables ,spEM_ReplicateBYSamplingType and spem_ReplicateBycount - Need to stay in sync -
**************************************************************************************************************************/
CREATE PROCEDURE dbo.spEM_cmnPropagateActiveSpecs 
 	 @Var_Id Int,
 	 @Spec_Id Int,
 	 @Spec_Changed Bit,
 	 @Data_Type_Changed Bit
AS
 	 Declare @Now DateTime
 	 Select @Now = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT Var_Id = Var_Id, PU_Id = PU_Id
    INTO #Variables
    FROM Variables WHERE PVar_Id = @Var_Id OR Var_Id = @Var_Id
  --
  -- We have a specification and/or data type change. Delete any variable
  -- specifications or transaction variables associated with this variable
  -- or its children.
  --
  IF (@Data_Type_Changed = 1)
    -- 
    -- We have a data type change. Delete any variable specifications or
    -- transaction variables associated with this variable or its children.
    -- We may also have a spec change but, this will handle this condition.
    --
    BEGIN
      DELETE FROM Trans_Variables WHERE (Var_Id IN (SELECT Var_Id FROM #Variables))
      DELETE FROM Var_Specs WHERE (Var_Id IN (SELECT Var_Id FROM #Variables))
    END
  ELSE
    -- 
    -- We have a specification change without a data type change.
    --
    BEGIN
      --
      -- Delete any transaction variables referencing the variable from pending
      -- transactions.
      --
      DELETE FROM Trans_Variables
        WHERE (Var_Id IN (SELECT Var_Id FROM #Variables)) AND
              (Trans_Id IN
                (SELECT Trans_Id FROM Transactions WHERE Approved_On IS NULL))
      --
      -- Expire any current and delete any future variable specifications for the
      -- variable.
      --
      DELETE FROM Var_Specs
        WHERE (Var_Id IN (SELECT Var_Id FROM #Variables)) AND
              (Effective_Date >= @Now)
-- set as_Id to null so Expiration_Date does not change in the future
      UPDATE Var_Specs SET Expiration_Date = @Now,AS_Id = Null
        WHERE (Var_Id IN (SELECT Var_Id FROM #Variables)) AND
              (Effective_Date < @Now) AND
              ((Expiration_Date IS NULL) OR
               ((Expiration_Date IS NOT NULL) AND (Expiration_Date > @Now)))
    END
  --
  -- If we have no specification, finish.
  --
  IF (@Spec_Id IS NULL) GOTO Exitsp
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
      FROM #Variables v
      JOIN Prod_Units u ON (v.PU_Id = u.PU_Id)
      JOIN PU_Characteristics uc ON (uc.PU_Id = CASE WHEN u.Master_Unit IS NULL THEN u.PU_Id ELSE u.Master_Unit END)
      JOIN Active_Specs a ON (a.Spec_Id = @Spec_Id) AND (a.Char_Id = uc.Char_Id) AND
                             ((a.Expiration_Date IS NULL) OR ((a.Expiration_Date > @Now) AND (a.Expiration_Date IS NOT NULL)))
  --
  -- Drop our temporary table.
  --
Exitsp:
Drop Table #Variables
