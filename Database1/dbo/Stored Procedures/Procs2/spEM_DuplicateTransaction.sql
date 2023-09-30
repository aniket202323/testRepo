CREATE PROCEDURE dbo.spEM_DuplicateTransaction
  @Original_Trans_Id int,
  @New_Trans_Desc    nvarchar(50),
  @User_Id   int,
  @New_Trans_Id      int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create duplicate transaction.
  --
  -- begin our transaction.
  --
   DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DuplicateTransaction',
                 convert(nVarChar(10), @Original_Trans_Id) + ','  + @New_Trans_Desc + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  BEGIN TRANSACTION
  --
  -- Create the duplicate transaction.
  --
  INSERT INTO Transactions(Trans_Desc) VALUES(@New_Trans_Desc)
  SELECT @New_Trans_Id = Scope_Identity()
  IF @New_Trans_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1
 	  WHERE Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  --
  -- Copy the property transaction items.
  --
  INSERT INTO Trans_Properties (
           Trans_Id,
           Spec_Id,
           Char_Id,
           U_Entry,
           U_Reject,
           U_Warning,
           U_User,
           Target,
           L_User,
           L_Warning,
           L_Reject,
           L_Entry,
 	  	    L_Control,
 	  	    T_Control,
 	  	    U_Control,
           Test_Freq,
 	  	    Esignature_Level)
    SELECT New_Trans_Id = @New_Trans_Id,
           Spec_Id,
           Char_Id,
           U_Entry,
           U_Reject,
           U_Warning,
           U_User,
           Target,
           L_User,
           L_Warning,
           L_Reject,
           L_Entry,
 	  	    L_Control,
 	  	    T_Control,
 	  	    U_Control,
           Test_Freq,
 	  	    Esignature_Level
      FROM Trans_Properties
      WHERE Trans_Id = @Original_Trans_Id
  --
  -- Copy the variable transaction items.
  --
  INSERT INTO Trans_Variables (
           Trans_Id,
           Var_Id,
           Prod_Id,
           U_Entry,
           U_Reject,
           U_Warning,
           U_User,
           Target,
           L_User,
           L_Warning,
           L_Reject,
           L_Entry,
 	  	    L_Control,
 	  	    T_Control,
 	  	    U_Control,
           Test_Freq,
 	  	    Esignature_Level)
    SELECT New_Trans_Id = @New_Trans_Id,
           Var_Id,
           Prod_Id,
           U_Entry,
           U_Reject,
           U_Warning,
           U_User,
           Target,
           L_User,
           L_Warning,
           L_Reject,
           L_Entry,
 	  	    L_Control,
 	  	    T_Control,
 	  	    U_Control,
           Test_Freq,
 	  	    Esignature_Level
      FROM Trans_Variables
      WHERE Trans_Id = @Original_Trans_Id
  --
  -- Commit our transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@New_Trans_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
