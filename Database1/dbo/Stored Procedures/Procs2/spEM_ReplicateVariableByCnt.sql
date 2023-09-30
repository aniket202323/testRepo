CREATE PROCEDURE dbo.spEM_ReplicateVariableByCnt
  @Var_Id            int,
  @Rep_Desc          nvarchar(50),
  @User_Id int,
  @Gp_Id             int = NULL,
  @Rep_Id            int           OUTPUT
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_ReplicateVariableByCnt',
                Convert(nVarChar(10),@Var_Id) + ','  + 
                @Rep_Desc + ','  + 
                Convert(nVarChar(10),@User_Id) + ','  + 
                Convert(nVarChar(10),@Gp_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Error: Can't find original variable.
  --   2 = Error: Can't create new variable.
  --
  -- Note: Input_Tag, Output_Tag, Target_Tag, and limit tags are not copied
  --       to replicates.
  --
  -- Declare local variables.
  --
  DECLARE
 	 @PU_Id 	  	  	 Int,
 	 @Data_Type_Id 	  	 Int,
 	 @Sampling_Interval 	 Smallint_Offset,
 	 @Var_Precision 	  	 Tinyint_Precision,
 	 @PVar_Id 	  	  	 Int,
 	 @DS_Id 	  	  	 Int,
 	 @Event_Type 	  	 Tinyint,
 	 @Var_Reject 	  	 Bit,
 	 @Unit_Reject 	  	 Bit,
 	 @Eng_Units          	 nvarchar(15),
 	 @DQ_Tag             	 nvarchar(255),
 	 @Sampling_Offset    	 Smallint_Offset,
 	 @Sampling_Type      	 tinyint,
 	 @PUG_Id             	 int,
 	 @PUG_Order          	 int,
 	 @Rank               	 Smallint_Pct,
 	 @Group_Id           	 int,
 	 @Tot_Factor 	      	 real,
 	 @SA_Id              	 tinyint,
 	 @Unit_Summarize     	 bit,
 	 @Sampling_Window    	 int,
 	 @ProdCalc_Type      	 int,
 	 @Repeating          	 bit,
 	 @ShouldArchive      	 bit,
 	 @Repeat_Backtime    	 int,
 	 @Force_Sign_Entry   	 tinyint,
 	 @TF_Reset           	 tinyint,
 	 @Test_Name          	 nvarchar(25),
 	 @Calculation_ID     	 int,
 	 @Ext_Test_Freq      	 int,
 	 @ArrayStatOnly      	 tinyint,
 	 @Comp_Oper_Id       	 Int,
 	 @Comp_Value         	 nvarchar(50),
 	 @Output_DS_Id       	 int,
 	 @MaxRPM 	  	  	 Int,
 	 @ResetValue 	  	 Int,
 	 @Extended_Info 	  	 nvarchar(255),
 	 @User_Defined1 	  	 nvarchar(255),
 	 @User_Defined2 	  	 nvarchar(255),
 	 @User_Defined3 	  	 nvarchar(255),
 	 @Is_Conformance_Variable 	 Bit,
 	 @Esignature_Level   	 Int,
 	 @EventSubtypeId     	 Int,
 	 @EventDimension     	 tinyint,
 	 @PEI_Id             	 int,
 	 @WriteGroupDSId 	 Int,
 	 @CPKSubGroup 	  	 Int,
 	 @ReadLagTime 	  	 Int,
 	 @Lookup 	  	  	  	 Int,
 	 @IgnoreEventStatus 	 Int
  --
  -- Get information to copy from parent variable.
  --
  SELECT @PU_Id             = PU_Id,
         @Data_Type_Id      = Data_Type_Id,
         @Sampling_Interval = Sampling_Interval,
         @Var_Precision     = Var_Precision,
         @PVar_Id           = PVar_Id,
         @DS_Id             = DS_Id,
         @Event_Type        = Event_Type,
         @Var_Reject        = Var_Reject,
         @Unit_Reject       = Unit_Reject,
         @Eng_Units         = Eng_Units,
         @DQ_Tag            = DQ_Tag,
         @Sampling_Offset   = Sampling_Offset,
         @Sampling_Type     = Sampling_Type,
         @PUG_Id            = PUG_Id,
         @PUG_Order         = PUG_Order,
         @Rank              = Rank,
         @Group_Id          = Group_Id,
         @Tot_Factor        = Tot_Factor,
         @SA_Id             = SA_Id,
 	  @Unit_Summarize    = Unit_Summarize,
 	  @Sampling_Window   = Sampling_Window,
 	  @ProdCalc_Type     = ProdCalc_Type,
 	  @Repeating         = Repeating,
 	  @ShouldArchive     = ShouldArchive,
 	  @Repeat_Backtime   = Repeat_Backtime,
 	  @Force_Sign_Entry  = Force_Sign_Entry,
 	  @TF_Reset          = TF_Reset,
 	  @Calculation_ID    = Calculation_ID,
 	  @Ext_Test_Freq     = Extended_Test_Freq,
 	  @ArrayStatOnly     = ArrayStatOnly,
 	  @Comp_Oper_Id      = Comparison_Operator_Id,
 	  @Comp_Value        = Comparison_Value,
 	  @Output_DS_Id      = Output_DS_Id,
 	  @MaxRPM 	      	 = Max_RPM,
 	  @ResetValue 	     = Reset_Value,
   	  @Extended_Info 	  	 = Extended_Info,
 	  @User_Defined1 	  	 = User_Defined1,
 	  @User_Defined2 	  	 = User_Defined2,
 	  @User_Defined3 	  	 = User_Defined3,
 	  @Is_Conformance_Variable = Is_Conformance_Variable,
   	  @Esignature_Level  = Esignature_Level,
   	  @EventSubtypeId    = Event_Subtype_Id,
   	  @EventDimension    = Event_Dimension,
   	  @PEI_Id            =  PEI_Id,
 	  @WriteGroupDSId 	 = Write_Group_DS_Id,
 	  @CPKSubGroup 	  	 = CPK_SubGroup_Size,
 	  @ReadLagTime 	  	 = ReadLagTime,
     @Lookup 	  	  	 = Perform_Event_Lookup,
     @IgnoreEventStatus = Ignore_Event_Status
    FROM Variables
    WHERE Var_Id = @Var_Id
  IF @PU_Id IS NULL
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1 WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(1)
 	 END
  --
  -- Create a new child variable.
  --
  IF @Gp_Id IS NOT NULL
 	 BEGIN
 	    SELECT @PUG_Id = @Gp_Id
 	    SELECT @PU_Id = PU_Id 
 	  	 FROM Pu_Groups
 	  	 WHERE PUG_Id =  @Gp_Id
 	 END
  -- Call variable create first
  Execute spEM_CreateVariable  @Rep_Desc,@PU_Id,@PUG_Id,@PUG_Order,@User_Id,@Rep_Id OUTPUT
  IF @Rep_Id IS NULL
 	 BEGIN
 	       UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 2 WHERE Audit_Trail_Id = @Insert_Id
 	       RETURN(2)
 	 END
  Execute spEM_PutVarSheetData @Rep_Id,@Data_Type_Id,@Var_Precision,@Sampling_Interval,@Sampling_Offset,@Sampling_Type,@Eng_Units,
 	  	  	  	 @DS_Id,@Event_Type,@Unit_Reject,@Unit_Summarize,@Var_Reject,@Rank,Null,Null,@DQ_Tag,Null,Null,Null,Null,Null,Null,Null,Null,Null,
 	  	  	  	 @Tot_Factor,@Group_Id,Null,@SA_Id,@Repeating,@Repeat_Backtime,@Sampling_Window,@ShouldArchive,@Extended_Info,
 	  	  	  	 @User_Defined1,@User_Defined2,@User_Defined3,@TF_Reset,@Force_Sign_Entry,@Test_Name,@Ext_Test_Freq,@ArrayStatOnly,@Comp_Oper_Id,
 	  	  	  	 @Comp_Value,@MaxRPM,@ResetValue,@Is_Conformance_Variable,@Esignature_Level,@EventSubtypeId,@EventDimension,@PEI_Id,Null,Null,Null,Null,
 	  	  	  	 Null,@WriteGroupDSId,@CPKSubGroup,@ReadLagTime,Null,@Lookup,0,@IgnoreEventStatus,@User_Id
  Update Variables_Base set PVar_Id = @PVar_Id,Calculation_Id = @Calculation_ID,Output_DS_Id = @Output_DS_Id where var_Id = @Rep_Id
   -- Return success,
  --
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0,Output_Parameters = convert(nVarChar(10),@Rep_Id)
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
