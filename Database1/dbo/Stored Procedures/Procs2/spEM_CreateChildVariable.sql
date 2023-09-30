Create Procedure dbo.spEM_CreateChildVariable
  @Var_Desc nvarchar(50),
  @PVar_Id  int,
  @VarOrder int,
  @DS_Id int,
  @DataType_Id int,
  @Event_Type_Id int,
  @Precision Tinyint_Precision,
  @SPCVariableType_Id int,
  @SpecId int,
  @TestFreq int,
  @User_Id int,
  @EventSubType 	  	 Int,
  @PeiId 	 Int,
  @Var_Id   int OUTPUT
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Parent variable not found.
  --   2 = Error: Can't create variable.
  --
  -- Declare local variables.
  --
  DECLARE
 	 @Sql 	  	  	    VarChar(5000),
    @PU_Id             int,
    @Data_Type_Id      int,
    @Sampling_Interval Smallint_Offset,
    @Var_Precision     Tinyint_Precision,
    @Eng_Units         nvarchar(15),
    @Sampling_Offset   Smallint_Offset,
    @Sampling_Type     tinyint,
    @PUG_Id            int,
    @PUG_Order         int,
    @Group_Id          int,
    @Tot_Factor        real,
    @SA_Id             tinyint,
    @Unit_Reject       bit,
    @Unit_Summarize    bit,
    @Sampling_Window   int,
    @Should_Archive    tinyint,
    @CurrentDate       DateTime_ComX,
    @Insert_Id             integer
 	 
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Get information to copy from parent variable.
  --
 Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateChildVariable',
                 @Var_Desc + ',' + convert(nVarChar(10),@PVar_Id) + ','  + Convert(nVarChar(10), @VarOrder) + ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
 SELECT @CurrentDate = dbo.fnServer_CmnGetDate(getUTCdate())
  SELECT @PU_Id             = PU_Id,
         @Data_Type_Id      = @DataType_Id,
         @Sampling_Interval = Sampling_Interval,
         @Var_Precision     = @Precision,
         @DS_Id             = @DS_Id,
         @Eng_Units         = Eng_Units,
         @Sampling_Offset   = Sampling_Offset,
         @Sampling_Type     = Sampling_Type,
         @PUG_Id            = PUG_Id,
         @PUG_Order         = PUG_Order,
         @Group_Id          = Group_Id,
         @Tot_Factor        = Tot_Factor,
         @SA_Id             = SA_Id,
         @Unit_Reject       = Unit_Reject,
         @Unit_Summarize    = Unit_Summarize,
         @Sampling_Window   = Sampling_Window,
         @Should_Archive    = ShouldArchive
    FROM Variables
    WHERE Var_Id = @PVar_Id
  IF @PU_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
     Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 where Audit_Trail_Id = @Insert_Id
     RETURN(1)
    END
  If @TestFreq <> 0
    Select @Sampling_Interval = @TestFreq
  --
  -- Create a new child variable.
  --  
 	 EXECUTE spEM_CreateVariable   @Var_Desc,@PU_Id,@PUG_Id,@PUG_Order, @User_Id,@Var_Id OutPut
 	 IF @Var_Id Is Not Null
 	 BEGIN
 	  	 EXECUTE spEM_PutVarSheetData @Var_Id,@Data_Type_Id,@Var_Precision,@Sampling_Interval, @Sampling_Offset,@Sampling_Type,@Eng_Units,@DS_Id,@Event_Type_Id,@Unit_Reject,
 	  	  	 @Unit_Summarize,0,0,Null,Null,Null,Null,Null,Null,Null,
 	  	  	 Null,Null,Null,Null,Null,@Tot_Factor,@Group_Id,@SpecId,@SA_Id,Null,
 	  	  	 Null,@Sampling_Window,@Should_Archive,Null,Null,Null,Null,0,0,Null,
 	  	  	 1,0,Null,Null,Null,Null,1,Null,@EventSubType,Null,
 	  	  	 @PEIId,Null ,@SPCVariableType_Id ,Null,Null,Null,Null,Null,Null,Null,
 	  	  	 1,0,0,@User_Id 
 	  	 UPDATE Variables_Base SET PVar_Id = @PVar_Id 	 WHERE Var_Id = @Var_Id
 	  	 
 	 END
 	 
 	 
  -- For SPC child variables, sync the Event_type of the parent variable with the children
  If Not @SPCVariableType_Id is Null
    Begin
      Update Variables_Base set Event_Type = @Event_Type_Id,PEI_ID = @PEIId,Event_Subtype_id =@EventSubType Where Var_Id = @PVar_Id
    End
  --
  -- Return the id of the newly created child variable.
  --
  IF @Var_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2 where Audit_Trail_Id = @Insert_Id
      RETURN(2)
    END
  -- Copy the var specs for NON-SPC child variables
If @SPCVariableType_Id is Null
  Begin
 	   --
 	   -- insert Current records int var specs.
 	   --
 	   INSERT INTO Var_Specs(Var_Id,
 	  	  	  	 Prod_Id,
 	  	  	  	 Effective_Date,
 	  	  	  	 Expiration_Date,
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
 	  	  	  	 Esignature_Level,
 	  	  	  	 Test_Freq,
 	  	  	  	 AS_Id,
 	  	  	  	 Comment_Id)
 	              SELECT    @Var_Id,
 	  	  	  	 Prod_Id,
 	  	  	  	 @CurrentDate,
 	  	  	  	 Expiration_Date,
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
 	  	  	  	 Esignature_Level,
 	  	  	  	 Test_Freq,
 	  	  	  	 AS_Id,
 	  	  	  	 Comment_Id
 	        FROM Var_Specs WHERE (Var_Id = @PVar_ID) 
 	                         AND (Effective_Date <= @CurrentDate)
 	                         AND ((Expiration_Date > @CurrentDate) OR (Expiration_Date IS NULL))
 	   --
 	   -- insert future records into varspecs.
 	   --
 	   INSERT INTO Var_Specs(Var_Id,
 	  	  	  	 Prod_Id,
 	  	  	  	 Effective_Date,
 	  	  	  	 Expiration_Date,
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
 	  	  	  	 Esignature_Level,
 	  	  	  	 Test_Freq,
 	  	  	  	 AS_Id,
 	  	  	  	 Comment_Id)
 	              SELECT    @Var_Id,
 	  	  	  	 Prod_Id,
 	  	  	  	 Effective_Date,
 	  	  	  	 Expiration_Date,
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
 	  	  	  	 Esignature_Level,
 	  	  	  	 Test_Freq,
 	  	  	  	 AS_Id,
 	  	  	  	 Comment_Id
 	        FROM Var_Specs WHERE Var_Id = @PVar_ID AND Effective_Date > @CurrentDate
  End
  --
  -- Commit the transaction and return success.
  --
  COMMIT TRANSACTION
 Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@Var_Id) where Audit_Trail_Id = @Insert_Id
 RETURN(0)
