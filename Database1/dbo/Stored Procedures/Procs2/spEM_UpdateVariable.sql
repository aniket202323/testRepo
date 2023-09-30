CREATE PROCEDURE dbo.spEM_UpdateVariable
  @Var_Id                  int,
  @Sampling_Interval       int,
  @Sampling_Window         int,
  @Spec_Id                 int,
  @System                  int,
  @User_Id int
AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't create variable.
  --
  -- Begin a transaction.
  --
  DECLARE @Insert_Id Int,@Sql nvarchar(1000),@OldSpecId Int,@Spec_Changed Int
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_UpdateVariable',
                 Convert(nVarChar(10),@Var_Id) + ','  + Convert(nVarChar(10), @Sampling_Interval) + ','  + Convert(nVarChar(10), @Sampling_Window) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
Select @OldSpecId = Spec_Id From Variables WHERE Var_Id = @Var_Id
BEGIN TRANSACTION
  --
  -- Update variable.
  --
  --
  UPDATE Variables_Base Set Sampling_Interval = @Sampling_Interval, Sampling_Window = @Sampling_Window,
                        System = @System, Spec_Id = @Spec_Id WHERE Var_Id = @Var_Id
  SELECT @Spec_Changed = CASE
    WHEN (@Spec_Id = @OldSpecId) OR
         ((@Spec_Id IS NULL) AND (@OldSpecId IS NULL)) THEN 0
    ELSE 1
  END
  If @Spec_Changed = 0 GoTo Finish
  SELECT Var_Id = Var_Id, PU_Id = PU_Id
    INTO #Var
    FROM Variables WHERE PVar_Id = @Var_Id OR Var_Id = @Var_Id
  UPDATE Variables_Base
    SET  Spec_Id           = @Spec_Id
    WHERE Var_Id IN (SELECT Var_Id FROM #Var WHERE Var_Id <> @Var_Id and SPC_Group_Variable_Type_Id is NULL)
  DROP TABLE #Var
  Execute spEM_cmnPropagateActiveSpecs @Var_Id,@Spec_Id,1,0
  --
  -- Commit the transaction and return success.
  --
Finish:
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Var_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
