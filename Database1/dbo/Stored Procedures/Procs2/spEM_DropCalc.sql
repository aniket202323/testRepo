CREATE PROCEDURE dbo.spEM_DropCalc
  @Var_Id int,
  @DropDef Int,
  @User_Id int
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
   DECLARE @Insert_Id integer,
    	    @CalcId     integer
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_DropCalc',
                convert(nVarChar(10),@Var_Id) + ',' +
 	  	 convert(nVarChar(10),@DropDef) + ',' + 
 	  	 Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
 --
  -- Change the variable's data source from Calc Engine to AutoLog.
  --
  If @DropDef = 0 
   Begin
    UPDATE Variables_Base SET DS_Id = 2,Calculation_ID = Null, SPC_Group_Variable_Type_Id = Null,
        SPC_Calculation_Type_Id = Null
       WHERE Var_Id = @Var_Id
    Delete From Calculation_Instance_Dependencies where Result_Var_Id =  @Var_Id
    Delete From Calculation_Input_Data where  Result_Var_Id = @Var_Id
   End
  Else
   Begin
    Select @CalcId = Calculation_ID From Variables WHERE Var_Id = @Var_Id
    Execute spEMCC_ByCalcIDUpdate 29, @CalcId, @User_Id
   End
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
