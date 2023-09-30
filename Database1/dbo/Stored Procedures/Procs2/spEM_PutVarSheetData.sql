/************************************************************************************************************************
This sp is called from spem_IEVariables ,spEM_ReplicateBYSamplingType and spem_ReplicateBycount,spEMEC_ConfigureModel5014 - Need to stay in sync -
**************************************************************************************************************************/
CREATE PROCEDURE dbo.spEM_PutVarSheetData
  @Var_Id            int,
  @Data_Type_Id      int,
  @Var_Precision     Tinyint_Precision,
  @Sampling_Interval Smallint_Offset,
  @Sampling_Offset   Smallint_Offset,
  @Sampling_Type     tinyint,
  @Eng_Units         nvarchar(15),
  @DS_Id             int,
  @Event_Type        tinyint,
  @Unit_Reject       bit,
  @Unit_Summarize    bit,
  @Var_Reject        bit,
  @Rank              Smallint_Pct,
  @Input_Tag         nvarchar(255),
  @Output_Tag        nvarchar(255),
  @DQ_Tag            nvarchar(255),
  @UEL_Tag           nvarchar(255),
  @URL_Tag           nvarchar(255),
  @UWL_Tag           nvarchar(255),
  @UUL_Tag           nvarchar(255),
  @Target_Tag        nvarchar(255),
  @LUL_Tag           nvarchar(255),
  @LWL_Tag           nvarchar(255),
  @LRL_Tag           nvarchar(255),
  @LEL_Tag           nvarchar(255),
  @Tot_Factor        real,
  @Group_Id          int,
  @Spec_Id           int,
  @SA_Id             tinyint,
  @Repeating         bit,
  @Repeat_Backtime   int,
  @Sampling_Window   int,
  @ShouldArchive     bit,
  @Extended_Info     nvarchar(255),
  @User_Defined1     nvarchar(255),
  @User_Defined2     nvarchar(255),
  @User_Defined3     nvarchar(255),
  @TFReset           tinyint,
  @ForceSign         tinyint,
  @Test_Name         nvarchar(50),
  @ExtendedTestFreqId int,
  @ArrayStatOnly     bit,
  @CTID 	  	  	  	  	 Int,
  @CV 	  	  	  	  	 nvarchar(50),
  @MaxRPM 	  	  	  	 Float,
  @ResetValue 	  	  	 Float,
  @Is_Conformance_Variable 	 Bit,
  @Esignature_Level  Int,
  @EventSubtypeId    Int,
  @EventDimension    tinyint,
  @PEI_Id            int,
  @SPCCalculationTypeId int = Null,
  @SPCVariableTypeId int = Null,
  @Input_Tag2        nvarchar(255) = Null,
  @SamplingReference_VarId int = Null,
  @StringSpecSetting tinyint = Null,
  @WriteGroupDSId 	  	  Int = Null,
  @CPKSubGroupSize 	  	  Int = Null,
  @ReadLagTime 	  	  	  Int = Null,
  @ReloadFlag 	  	  	  Int = Null,
  @EventLookup 	  	  	  Int = Null,
  @Debug 	  	  	  	  Int = Null,
  @Ignore_Event_Status   Int = Null,
  @User_Id int
 AS
  DECLARE @Insert_Id integer 
  INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_PutVarSheetData',  
 	  	 Convert(nVarChar(10),@Var_Id)  + ','  +
 	     	 Convert(nVarChar(10),@User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
  SELECT @Insert_Id = Scope_Identity()
  --
  -- Declare local variables.
  --
  DECLARE @Old_Spec_Id       int,
          @Old_Data_Type_Id  int,
          @Old_Var_Precision tinyint,
          @Now               DateTime,
          @Spec_Changed      bit,
          @Data_Type_Changed bit,
          @Precision_Changed bit
  If @CTID = 0
 	 Select @CTID = Null,@CV = Null
  If @Debug is Null
 	 Select @Debug = 0
  IF @Ignore_Event_Status Is Null
 	 SELECT @Ignore_Event_Status = 0
  --
  -- Begin a transaction.
  --
  BEGIN TRANSACTION
  --
  -- Determine the current time.
  --
  SELECT @Now = dbo.fnServer_CmnGetDate(getUTCdate())
IF @Sampling_Type = 28
BEGIN
 	 SELECT @EventLookup = 0
END
If @DS_Id = 16 --Calculation CLEANUP
BEGIN
 	 SELECT @Input_Tag = NULL
END
ELSE
BEGIN
 	 Update Variables_Base set Calculation_ID = Null, SPC_Group_Variable_Type_Id = Null, SPC_Calculation_Type_Id = Null
 	  	 WHERE Var_Id = @Var_Id and (Calculation_ID Is Not Null OR SPC_Group_Variable_Type_Id  Is Not Null or SPC_Calculation_Type_Id  Is Not Null)
 	 DELETE FROM Calculation_Instance_Dependencies
 	  	 WHERE Result_Var_Id = @Var_Id
 	 DELETE FROM Calculation_Input_Data
 	  	 WHERE Result_Var_Id = @Var_Id
END
  --
  -- Get the current data source, specification, data type, precision, and
  -- production unit for the variable.
  --
  SELECT @Old_Spec_Id = Spec_Id,
         @Old_Data_Type_Id = Data_Type_Id,
         @Old_Var_Precision = Var_Precision
--,         @Old_DS_Id = DS_Id
    FROM Variables WHERE Var_Id = @Var_Id
  --
  -- Update the variable.
  --
  UPDATE Variables_Base
    SET Data_Type_Id      = @Data_Type_Id,
        Var_Precision     = @Var_Precision,
        Sampling_Interval = @Sampling_Interval,
        Sampling_Offset   = @Sampling_Offset,
        Sampling_Type     = @Sampling_Type,
        Eng_Units         = @Eng_Units,
        DS_Id             = @DS_Id,
        Event_Type        = @Event_Type,
        Var_Reject        = @Var_Reject,
        Unit_Summarize    = @Unit_Summarize,
        Unit_Reject       = @Unit_Reject,
 	  	 Is_Conformance_Variable = @Is_Conformance_Variable,
        Rank              = @Rank,
        Input_Tag         = dbo.fnEM_ConvertTagToVarId(@Input_Tag),
        Input_Tag2        = dbo.fnEM_ConvertTagToVarId(@Input_Tag2),
        Output_Tag        = dbo.fnEM_ConvertTagToVarId(@Output_Tag),
        DQ_Tag            = dbo.fnEM_ConvertTagToVarId(@DQ_Tag),
        UEL_Tag           = dbo.fnEM_ConvertTagToVarId(@UEL_Tag),
        URL_Tag           = dbo.fnEM_ConvertTagToVarId(@URL_Tag),
        UWL_Tag           = dbo.fnEM_ConvertTagToVarId(@UWL_Tag),
        UUL_Tag           = dbo.fnEM_ConvertTagToVarId(@UUL_Tag),
        Target_Tag        = dbo.fnEM_ConvertTagToVarId(@Target_Tag),
        LUL_Tag           = dbo.fnEM_ConvertTagToVarId(@LUL_Tag),
        LWL_Tag           = dbo.fnEM_ConvertTagToVarId(@LWL_Tag),
        LRL_Tag           = dbo.fnEM_ConvertTagToVarId(@LRL_Tag),
        LEL_Tag           = dbo.fnEM_ConvertTagToVarId(@LEL_Tag),
        Tot_Factor        = @Tot_Factor,
        Group_Id          = @Group_Id,
        Spec_Id           = @Spec_Id,
        SA_Id             = @SA_Id,
        Repeating         = @Repeating,
        Repeat_Backtime   = @Repeat_BackTime,
        Sampling_Window   = @Sampling_Window,
        ShouldArchive     = @ShouldArchive,
        Extended_Info     = @Extended_Info,
        User_Defined1     = @User_Defined1,
        User_Defined2     = @User_Defined2,
        User_Defined3     = @User_Defined3,
        TF_Reset          = @TFReset,
        Force_Sign_Entry  = @ForceSign,
        Test_Name         = @Test_Name,
        Extended_Test_Freq = @ExtendedTestFreqId,
        ArrayStatOnly = @ArrayStatOnly,
 	  	 Comparison_Operator_Id = @CTID,
 	  	 Comparison_Value =  @CV,
 	  	 Max_RPM 	 = @MaxRPM,
 	  	 Reset_Value = @ResetValue,
 	  	 Esignature_Level = @Esignature_Level,
 	  	 Event_Subtype_Id = @EventSubtypeId,
        Event_Dimension  = @EventDimension,
        PEI_Id           = @PEI_Id,
        SPC_Calculation_Type_Id = @SPCCalculationTypeId,
        SPC_Group_Variable_Type_Id = @SPCVariableTypeId,
        Sampling_Reference_Var_Id = @SamplingReference_VarId, 
        String_Specification_Setting = @StringSpecSetting,
 	  	 Write_Group_DS_Id = @WriteGroupDSId,
 	  	 CPK_SubGroup_Size = @CPKSubGroupSize,
 	  	 ReadLagTime = @ReadLagTime,
 	  	 Reload_Flag = @ReloadFlag,
 	  	 Perform_Event_Lookup = @EventLookup,
 	  	 Debug = @Debug,
 	  	 Ignore_Event_Status = @Ignore_Event_Status
    WHERE Var_Id = @Var_Id
  --
  -- If this is a calculation (Data Source = 5), make sure that it has a
  -- corresponding record in the Calcs table. If this is not a calculation
  -- make sure there are no corresponding record in the Calcs table.
  -- Perform a similar check for the stored procedure calcs (Data Source = 6).
  --
--  ****************  spEM_PutSpecVariableData has spec link logic also ***********************
  SELECT @Spec_Changed = CASE
    WHEN (@Spec_Id = @Old_Spec_Id) OR
         ((@Spec_Id IS NULL) AND (@Old_Spec_Id IS NULL)) THEN 0
    ELSE 1
  END
  --
  -- Determine if the data type has changed.
  --
  SELECT @Data_Type_Changed = CASE
    WHEN (@Data_Type_Id = @Old_Data_Type_Id) OR
         ((@Data_Type_Id IS NULL) AND (@Old_Data_Type_Id IS NULL)) THEN 0
    ELSE 1
    END
  --
  -- Determine if the precision has changed.
  --
  SELECT @Precision_Changed = CASE
    WHEN (@Var_Precision = @Old_Var_Precision) OR
         ((@Var_Precision IS NULL) AND (@Old_Var_Precision IS NULL)) THEN 0
    ELSE 1
  END
  --
  -- Finish if we have no precision, specification, or data type changes.
  --
  IF (@Precision_Changed = 0) AND
     (@Spec_Changed = 0) AND
     (@Data_Type_Changed = 0) GOTO Finish
  --
  -- Update the data type, precision, and specification for any child
  -- variables. In the process, construct a tempoprary table with the
  -- identity of the current variable and all its children.
  --
  SELECT Var_Id = Var_Id, PU_Id = PU_Id
    INTO #Var
    FROM Variables WHERE PVar_Id = @Var_Id OR Var_Id = @Var_Id
  UPDATE Variables_Base
    SET Data_Type_Id      = @Data_Type_Id,
        Var_Precision     = @Var_Precision,
        Spec_Id           = @Spec_Id
    WHERE Var_Id IN (SELECT Var_Id FROM #Var WHERE Var_Id <> @Var_Id and SPC_Group_Variable_Type_Id is NULL)
  --
  -- If we have no specification or data type changes, finish.
  --
  DROP TABLE #Var
  IF (@Spec_Changed = 0) AND (@Data_Type_Changed = 0) GOTO Finish
  Execute spEM_cmnPropagateActiveSpecs @Var_Id,@Spec_Id,@Spec_Changed,@Data_Type_Changed
Finish:
  COMMIT TRANSACTION
  UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
     WHERE Audit_Trail_Id = @Insert_Id
  RETURN(0)
