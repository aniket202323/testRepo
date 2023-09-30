CREATE PROCEDURE dbo.spEM_IEImportVariables
@Dept_Desc 	  	 nVarChar(100),
@PL_Desc  	  	 nvarchar(50),
@PU_Desc  	  	 nvarchar(50),
@PUG_Desc  	  	 nvarchar(50),
@Var_Desc  	  	 nvarchar(50),
@DS_Desc  	  	 nvarchar(50),
@Write_Group_DS_Desc 	 nvarchar(50),
@Eng_Units  	  	 nvarchar(15),
@ET_Desc  	  	 nvarchar(50),
@Data_Type_Desc  	 nvarchar(50),
@Sampling_Interval  	 nvarchar(50),
@Sampling_Offset   	 nvarchar(50),
@ST_Desc  	  	 nvarchar(50),
@SA_Desc  	  	 nvarchar(50),
@Var_Precision  	  	 nvarchar(50),
@Output_Tag  	  	 nvarchar(255),
@Input_Tag  	  	 nvarchar (255),
@Input_Tag2         	 nvarchar(255),
@DQ_Tag  	  	 nvarchar (255),
@URL_Tag  	  	 nvarchar (255),
@UWL_Tag  	  	 nvarchar (255),
@Target_Tag  	  	 nvarchar (255),
@LWL_Tag  	  	 nvarchar (255),
@LRL_Tag  	  	 nvarchar (255),
@Extended_Info  	  	 nvarchar(255),
@User_Defined1  	  	 nvarchar(255),
@User_Defined2  	  	 nvarchar(255),
@User_Defined3  	  	 nvarchar(255),
@Spec_Desc  	  	 nVarChar(100),
@Sampling_Window  	 nvarchar(50),
@Sampling_Window_Type  	 nVarChar(100),
@Tot_Factor  	  	 nvarchar(50),
@DQ_Type  	  	 nVarChar(100),
@DQ_Value  	  	 nVarChar(100),
@UEL_Tag  	  	 nvarchar(255),
@UUL_Tag 	  	 nvarchar(255),
@LUL_Tag  	  	 nvarchar(255),
@LEL_Tag  	  	 nvarchar(255),
@Repeating  	  	 nvarchar(50),
@DF_TestFreq 	  	 nvarchar(50), 	  	 
@TF_Reset  	  	 nvarchar(50),
@Extended_Test_Freq  	 nVarChar(100),
@External_Link  	  	 nvarchar(255),
@Group_Desc  	  	 nVarChar(100),
@ShouldArchive  	  	 nvarchar(50),
@MaxRPM 	  	  	 nvarchar(50),
@ResetValue 	  	 nvarchar(50),
@Conformance_Variable  	 nvarchar(50),
@Esignature_Level 	 nvarchar(50),
@EventSubtype     	 nvarchar(50),
@EventDimension     	 nvarchar(50),
@InputName         	 nvarchar(50),
@SPCCalculationType  	 nvarchar(50),
@SPCGroupVariableType  	 nvarchar(50),
@RefPL_Desc 	  	 nvarchar(50),
@RefPU_Desc 	  	 nvarchar(50),
@RefVar_Desc 	  	 nvarchar(50),
@ParVar_Desc 	  	 nvarchar(50),
@BackTime 	  	 nvarchar(50),
@SignEntry 	  	 nvarchar(50),
@VarAlias 	  	 nvarchar(50),
@ArrayStat 	  	 nvarchar(50),
@sRank 	  	  	 nvarchar(50),
@UnitReject 	  	 nvarchar(50),
@UnitSummarize 	  	 nvarchar(50),
@VarReject 	  	 nvarchar(50),
@sCPKSubGroup 	  	 nvarchar(50),
@StringSpecSetting 	 nvarchar(50),
@sReadLagtime 	  	 nVarChar(10),
@sPerformLookup 	 nVarChar(10),
@sIgnoreStatus 	  	 nVarChar(10),
@UserId 	  	  	 Int 	 
AS
Declare 	  @Var_Id 	  	 Int,
 	 @PU_Id  	  	  	  	 int, 
   	 @PUG_Id  	  	  	 int, 
   	 @PL_Id  	  	  	  	 int,
   	 @ET_Id  	  	  	  	 int,
   	 @PUG_Order_Next  	 int,
   	 @Prop_Desc 	  	  	 nvarchar(50),
   	 @Prop_Id 	  	  	 int,
   	 @Data_Type_Id 	  	 int,
   	 @Sampling_Type 	  	 tinyint,
 	 @Sampling_Win_Type_Id 	 int,
   	 @DS_Id 	  	  	  	 int,
   	 @WriteGroupDSId 	  	 int,
   	 @Event_Type 	  	  	 tinyint,
   	 @Unit_Reject 	  	 bit,
   	 @Unit_Summarize 	  	 bit,
   	 @Var_Reject 	  	  	 bit,
   	 @Rank 	  	  	  	 int,
   	 @Group_Id 	  	  	 int,
   	 @Spec_Id 	  	  	 int,
   	 @SA_Id 	  	  	  	 tinyint,
   	 @Repeat_Backtime 	 int,
   	 @Force_Sign_Entry 	 tinyint,
   	 @ArrayStatOnly      	 bit,
   	 @Comparison_Operator_Id 	 Int,
   	 @Comparison_Value 	 nVarChar(100),
   	 @PUG_Order 	  	  	 int,
 	 @Index 	  	  	  	 int,
 	 @Ext_Test_Freq_Id 	 int,
 	 @Return_Code 	  	 int,
 	 @iSampling_Interval 	 Int,
 	 @iSampling_Offset 	 Int,
 	 @iVar_Precision 	  	 Tinyint,
 	 @iSampling_Window 	 Int,
 	 @rTot_Factor 	  	 Real,
 	 @iTF_Reset 	  	  	 TinyInt,
 	 @iShouldArchive 	  	 Int,
 	 @iMaxRPM 	  	  	 Int,
 	 @iResetValue 	  	 Int,
 	 @iConformance_Variable  	 Bit,
 	 @iEsignature_Level 	  	 Int,
 	 @Dept_Id 	  	  	 Int,
 	 @EventSubtype_Id Int,
 	 @EventDimension_Id Int,
 	 @PEI_Id Int,
 	 @SPC_Calculation_Type_Id Int,
 	 @SPC_Group_Variable_Type_Id Int,
 	 @RefPL_Id 	  	  	 int,
 	 @RefPU_Id 	  	  	 int,
 	 @RefVar_Id 	  	   	 int,
 	 @ParVar_Id 	  	   	 int,
 	 @iRepeating 	  	 Bit,
 	 @CPKSubGroup 	  	 Int,
 	 @SpecDT 	  	  	 Int,
 	 @iStringSpecSetting 	 Int,
 	 @iPUGId 	  	  	  	 Int,
 	 @MasterPUId 	  	  	 INT,
 	 @NewCreate 	  	  	 Int,
 	 @Readlagtime 	  	 Int,
 	 @Lookup 	  	  	  	 Int,
 	 @IgnorStatus 	  	 Int
/* Initialization */
Select 	 @PL_Id  	  	  	 = Null,
 	 @Var_Id  	  	 = Null,
 	 @PU_Id  	  	  	 = Null,
 	 @Data_Type_Id  	 = Null,
 	 @Sampling_Type 	 = Null,
 	 @Sampling_Win_Type_Id 	 = Null,
 	 @DS_Id 	  	  	 = Null,
 	 @Event_Type 	  	 = Null,
 	 @Unit_Reject 	  	 = Null,
 	 @Unit_Summarize 	  	 = Null,
 	 @Var_Reject 	  	 = Null,
 	 @Rank  	  	  	 = Null,
 	 @Group_Id   	  	 = Null,
 	 @Spec_Id   	  	 = Null,
 	 @SA_Id   	  	 = Null,
 	 @iRepeating   	  	 = Null,
 	 @Repeat_Backtime   	 = Null,
 	 @Force_Sign_Entry   	 = Null,
 	 @ArrayStatOnly   	 = Null,
 	 @Comparison_Operator_Id 	 = Null,
 	 @Comparison_Value 	 = Null,
 	 @PUG_Order 	  	 = 1,
 	 @Ext_Test_Freq_Id 	 = Null,
 	 @EventSubtype_Id = Null,
 	 @EventDimension_Id = Null,
 	 @PEI_Id = Null,
 	 @SPC_Calculation_Type_Id = Null,
 	 @SPC_Group_Variable_Type_Id = Null,
 	 @RefPL_Id  	  	  	 = Null,
 	 @RefVar_Id  	  	 = Null,
 	 @RefPU_Id  	  	  	 = Null,
 	 @ParVar_Id  	  	  	 = Null
select @Dept_Desc  	  	 =  LTrim(RTrim(@Dept_Desc))
select @PL_Desc  	  	 =  LTrim(RTrim(@PL_Desc))
select @PU_Desc  	  	 =  LTrim(RTrim(@PU_Desc))
select @Var_Desc  	  	 =  LTrim(RTrim(@Var_Desc))
select @PUG_Desc  	  	 =  LTrim(RTrim(@PUG_Desc))
select @RefPL_Desc  	  	 =  LTrim(RTrim(@RefPL_Desc))
select @BackTime  	  	 =  LTrim(RTrim(@BackTime))
select @SignEntry  	  	 =  LTrim(RTrim(@SignEntry))
select @VarAlias  	  	 =  LTrim(RTrim(@VarAlias))
select @ArrayStat  	  	 =  LTrim(RTrim(@ArrayStat))
select @Repeating  	  	 =  LTrim(RTrim(@Repeating))
select @sRank  	  	  	 =  LTrim(RTrim(@sRank))
select @sCPKSubGroup  	 =  LTrim(RTrim(@sCPKSubGroup))
select @UnitReject  	  	 =  LTrim(RTrim(@UnitReject))
select @UnitSummarize  	 =  LTrim(RTrim(@UnitSummarize))
select @VarReject  	  	 =  LTrim(RTrim(@VarReject))
select @sPerformLookup  	  	 =  LTrim(RTrim(@sPerformLookup))
select @sIgnoreStatus  	  	 =  LTrim(RTrim(@sIgnoreStatus))
select @Group_Desc  	  	 =  LTrim(RTrim(@Group_Desc))
Select @StringSpecSetting = LTrim(RTrim(@StringSpecSetting))
select @sReadLagtime  	 =  LTrim(RTrim(@sReadLagtime))
select @MaxRPM   	  	 =  LTrim(RTrim(@MaxRPM))
select @ResetValue    	 =  LTrim(RTrim(@ResetValue))
If @Dept_Desc = '' Select @Dept_Desc = Null
If @PL_Desc = '' Select @PL_Desc = Null
If @PU_Desc = '' Select @PU_Desc = Null
If @Var_Desc = '' Select @Var_Desc = Null
If @PUG_Desc = '' Select @PUG_Desc = Null
If @RefPL_Desc = '' Select @RefPL_Desc = Null
If @BackTime = '' Select @BackTime = Null
If @SignEntry = '' Select @SignEntry = Null
If @VarAlias = '' Select @VarAlias = Null
If @ArrayStat = '' Select @ArrayStat = Null
If @sRank = '' Select @sRank = Null
If @sCPKSubGroup = '' Select @sCPKSubGroup = Null
If @UnitReject = '' Select @UnitReject = Null
If @UnitSummarize = '' Select @UnitSummarize = Null
If @VarReject = '' Select @VarReject = Null
If @sPerformLookup = '' Select @sPerformLookup = Null
If @sIgnoreStatus = '' Select @sIgnoreStatus = Null
If @Repeating = '' Select @Repeating = Null
If @Group_Desc = '' Select @Group_Desc = Null
If @StringSpecSetting = '' Select @StringSpecSetting = Null
If @sReadLagtime = '' Select @sReadLagtime = Null
If @MaxRPM  = '' 	 SET @MaxRPM = Null
If @ResetValue = ''  SET @ResetValue = Null
/* Verify Arguments */
If @Dept_Desc IS NULL
     BEGIN
       Select  'Department Not Found'
       Return(-100)
     END
If @PL_Desc IS NULL
     BEGIN
       Select  'Product Line Not Found'
       Return(-100)
     END
If @PU_Desc IS NULL 
    BEGIN
      Select  'Product Unit Not Found'
      Return(-100)
    END
If @Var_Desc IS NULL 
    BEGIN
       Select 'Variable Description Not Found'
      Return(-100)
    END
If @StringSpecSetting = 'Not Equal'
 	 Select @iStringSpecSetting = 1
Else If @StringSpecSetting = 'Phrase Order'
 	 Select @iStringSpecSetting = 2
Else
 	 Select @iStringSpecSetting = 0
If @PUG_Desc IS NULL 
 	 Select @PUG_Desc = 'Unknown'
SELECT @Write_Group_DS_Desc = LTrim(RTrim(@Write_Group_DS_Desc))
IF @Write_Group_DS_Desc = ''  	 SELECT @Write_Group_DS_Desc = Null
If LTrim(RTrim(@RefPU_Desc)) = '' or @RefPU_Desc = ''
 	 Select @RefPU_Desc = Null
If LTrim(RTrim(@RefVar_Desc)) = '' or @RefVar_Desc = ''
 	 Select @RefVar_Desc = Null
If LTrim(RTrim(@ParVar_Desc)) = '' or @ParVar_Desc = ''
 	 Select @ParVar_Desc = Null
If LTrim(RTrim(@DS_Desc)) = '' or @DS_Desc = '' or @DS_Desc IS NULL 
 	 Select @DS_Desc = 'Autolog'
--If LTrim(RTrim(@ODS_Desc)) = '' or @ODS_Desc = '' or @ODS_Desc IS NULL 
-- 	 Select @ODS_Desc = Null
If LTrim(RTrim(@ET_Desc)) = '' or @ET_Desc = '' or @ET_Desc IS NULL 
 	 Select @ET_Desc = 'Turnup/Batch'
If LTrim(RTrim(@SA_Desc)) = '' or @SA_Desc = '' or @SA_Desc IS NULL 
 	 Select @SA_Desc = 'Grade Change'
If LTrim(RTrim(@Data_Type_Desc)) = '' or @Data_Type_Desc = '' or @Data_Type_Desc IS NULL 
 	 Select @Data_Type_Desc = 'Float'
If LTrim(RTrim(@ST_Desc)) = '' or @ST_Desc = ''
 	 Select @ST_Desc = Null
If LTrim(RTrim(@Output_Tag)) = '' or @Output_Tag = ''
 	 Select @Output_Tag = NULL 
If LTrim(RTrim(@Input_Tag)) = '' or @Input_Tag = ''
 	 Select @Input_Tag = NULL 
If LTrim(RTrim(@Input_Tag2)) = '' or @Input_Tag2 = ''
 	 Select @Input_Tag2 = NULL 
If LTrim(RTrim(@DQ_Tag)) = '' or @DQ_Tag = ''
 	 Select @DQ_Tag = NULL 
If LTrim(RTrim(@UEL_Tag)) = '' or @UEL_Tag = ''
 	 Select @UEL_Tag = NULL 
If LTrim(RTrim(@URL_Tag)) = '' or @URL_Tag = ''
 	 Select @URL_Tag = NULL 
If LTrim(RTrim(@UWL_Tag)) = '' or @UWL_Tag = ''
 	 Select @UWL_Tag = NULL 
If LTrim(RTrim(@UUL_Tag)) = '' or @UUL_Tag = ''
 	 Select @UUL_Tag = NULL 
If LTrim(RTrim(@Target_Tag)) = '' or @Target_Tag = ''
 	 Select @Target_Tag = NULL 
If LTrim(RTrim(@LUL_Tag)) = '' or @LUL_Tag = ''
 	 Select @LUL_Tag = NULL 
If LTrim(RTrim(@LWL_Tag)) = '' or @LWL_Tag = ''
 	 Select @LWL_Tag = NULL 
If LTrim(RTrim(@LRL_Tag)) = '' or @LRL_Tag = ''
 	 Select @LRL_Tag = NULL 
If LTrim(RTrim(@LEL_Tag)) = '' or @LEL_Tag = ''
 	 Select @LEL_Tag = NULL 
If LTrim(RTrim(@External_Link)) = '' or @External_Link = ''
 	 Select @External_Link = NULL 
If LTrim(RTrim(@Extended_Info)) = '' or @Extended_Info = ''
 	 Select @Extended_Info = NULL 
If isnumeric(@ShouldArchive) = 0  and @ShouldArchive is not null
  Begin
 	 Select 'Failed - should archive is not correct '
 	 Return(-100)
  End 
If isnumeric(@Sampling_Interval) = 0  and @Sampling_Interval is not null
  Begin
 	 Select 'Failed - Sampling Interval is not correct' 
 	 Return(-100)
  End 
If isnumeric(@Sampling_Offset) = 0  and @Sampling_Offset is not null
  Begin
 	 Select 'Failed - Sampling Offset is not correct '
 	 Return(-100)
  End 
If isnumeric(@Var_Precision) = 0  and @Var_Precision is not null
  Begin
 	 Select 'Failed - Variable Precision is not correct'
 	 Return(-100)
  End 
If isnumeric(@Conformance_Variable) = 0  and @Conformance_Variable is not null
  Begin
 	 Select 'Failed - Conformance is not correct'
 	 Return(-100)
  End 
If isnumeric(@Sampling_Window) = 0  and @Sampling_Window is not null
  Begin
 	 Select 'Failed - Sampling Window is not correct'
 	 Return(-100)
  End 
If isnumeric(@Tot_Factor) = 0  and @Tot_Factor is not null
  Begin
 	 Select 'Failed - Totalization Factor is not correct'
 	 Return(-100)
  End 
If isnumeric(@MaxRPM) = 0  and @MaxRPM is not null
  Begin
 	 Select 'Failed - Maximum Rate Per Minute is not correct'
 	 Return(-100)
  End 
If isnumeric(@ResetValue) = 0 and @ResetValue is not null
  Begin
 	 Select 'Failed - Reset Value is not correct'
 	 Return(-100)
  End 
If isnumeric(@Esignature_Level) = 0 and @Esignature_Level is not null
  Begin
 	 Select 'Failed - Esignature Level is not correct'
 	 Return(-100)
  End 
If isnumeric(@DF_TestFreq) = 0 and @DF_TestFreq is not null
  Begin
 	 Select 'Failed - Default Test Freq is not correct'
 	 Return(-100)
  End 
If isnumeric(@BackTime) = 0  and @BackTime is not null
  Begin
 	 Select 'Failed - Repeat Backtime is not correct '
 	 Return(-100)
  End 
If isnumeric(@SignEntry) = 0  and @SignEntry is not null
  Begin
 	 Select 'Failed - Signed Entry is not correct '
 	 Return(-100)
  End 
If isnumeric(@ArrayStat) = 0  and @ArrayStat is not null
  Begin
 	 Select 'Failed - Array Stat Only is not correct '
 	 Return(-100)
  End 
If isnumeric(@sRank) = 0  and @sRank is not null
  Begin
 	 Select 'Failed - Rank is not correct '
 	 Return(-100)
  End 
If isnumeric(@sCPKSubGroup) = 0  and @sCPKSubGroup is not null
  Begin
 	 Select 'Failed - CPkSubGroup is not correct '
 	 Return(-100)
  End 
If isnumeric(@sReadLagTime) = 0  and @sReadLagTime is not null
  Begin
 	 Select 'Failed - Read Lag Time is not correct '
 	 Return(-100)
  End 
If isnumeric(@UnitReject) = 0  and @UnitReject is not null
  Begin
 	 Select 'Failed - Unit Reject is not correct '
 	 Return(-100)
  End 
If isnumeric(@UnitSummarize) = 0  and @UnitSummarize is not null
  Begin
 	 Select 'Failed - Unit Summarize is not correct '
 	 Return(-100)
  End 
If isnumeric(@VarReject) = 0  and @VarReject is not null
  Begin
 	 Select 'Failed - Variable Reject is not correct '
 	 Return(-100)
  End 
If isnumeric(@Repeating) = 0  and @Repeating is not null
  Begin
 	 Select 'Failed - Variable Repeating is not correct '
 	 Return(-100)
  End 
If isnumeric(@sPerformLookup) = 0  and @sPerformLookup is not null
  Begin
 	 Select 'Failed - Perform Lookup is not correct '
 	 Return(-100)
  End If isnumeric(@sIgnoreStatus) = 0  and @sIgnoreStatus is not null
  Begin
 	 Select 'Failed - Ignore Event Status is not correct '
 	 Return(-100)
  End 
If @Repeating is Null
 	 Select @iRepeating = 0
Else
 	 Select @iRepeating = Convert(bit,@Repeating)
If @ShouldArchive is Null
 	 Select @iShouldArchive = 0
Else
 	 Select @iShouldArchive = Convert(TinyInt,@ShouldArchive)
If @Sampling_Offset is Null
 	 Select @iSampling_Offset = 0
Else
 	 Select @iSampling_Offset = Convert(Integer,@Sampling_Offset)
If @Var_Precision is Null
 	 Select @iVar_Precision = 2
ELSE
 	 Select @iVar_Precision = Convert(TinyInt,@Var_Precision)
If @Conformance_Variable is null
 	 select @iConformance_Variable = 0
Else
 	 select @iConformance_Variable = Convert(bit,@Conformance_Variable)
If @SignEntry is null
 	 select @Force_Sign_Entry = 0
Else
 	 select @ArrayStatOnly = Convert(bit,@SignEntry)
If @ArrayStat is null
 	 select @ArrayStatOnly = 0
Else
 	 select @Force_Sign_Entry = Convert(bit,@ArrayStat)
If @sRank is null
 	 select @rank = null
Else
 	 select @rank = Convert(tinyInt,@sRank)
If @sCPKSubGroup is null
 	 select @CPKSubGroup = null
Else
 	 select @CPKSubGroup = Convert(tinyInt,@sCPKSubGroup)
If @sReadLagTime is null
 	 select @ReadLagTime = null
Else
 	 select @ReadLagTime = Convert(Int,@sReadLagTime)
If @UnitReject is null
 	 select @Unit_Reject = 0
Else
 	 select @Unit_Reject = Convert(bit,@UnitReject)
If @UnitSummarize is null
 	 select @Unit_Summarize = 0
Else
 	 select @Unit_Summarize = Convert(bit,@UnitSummarize)
If @VarReject is null
 	 select @Var_Reject = 0
Else
 	 select @Var_Reject = Convert(bit,@VarReject)
If @sPerformLookup is null
 	 select @Lookup = 0
Else
 	 select @Lookup = Convert(Int,@sPerformLookup)
If @sIgnoreStatus is null
 	 select @IgnorStatus = 0
Else
 	 select @IgnorStatus = Convert(Int,@sIgnoreStatus)
Select @iSampling_Window = Convert(Int,@Sampling_Window)
Select @rTot_Factor = Convert(Real,@Tot_Factor)
Select @iTF_Reset = Convert(TinyInt,@TF_Reset)
Select @iMaxRPM = Convert(Int,@MaxRPM)
Select @iResetValue = Convert(Int,@ResetValue)
Select @iEsignature_Level = Convert(Int,@Esignature_Level)
Select @Repeat_Backtime = Convert(Int,@BackTime)
-- Create if PL  not found.
Select @PL_Id = Null
Select @PL_Id = PL_Id from Prod_Lines
 	 Where PL_Desc = @PL_Desc
If @PL_Id is Null
BEGIN
 	 -- Create if Department not found.
 	 Select @Dept_Id = Null
 	 Select @Dept_Id = Dept_Id from Departments
 	  	 Where Dept_Desc = @Dept_Desc
 	 If @Dept_Id is Null
 	 BEGIN
 	  	 Execute spEM_CreateDepartment @Dept_Desc,@UserId,@Dept_Id Output
 	  	 If @Dept_Id IS NULL
 	       BEGIN
 	  	     Select 'Failed - Error Creating Department'
 	         Return(-100)
 	       END
 	  END
 	 Execute spEM_CreateProdLine @PL_Desc,@Dept_Id,@UserId,@PL_Id Output
END
If @PL_Id IS NULL
    BEGIN
 	   Select 'Failed - Error Creating Line'
      Return(-100)
    END
If @RefPL_Desc is not null and @RefPU_Desc is not null and @RefVar_Desc Is not null
  Begin
 	 Select @RefPL_Id = PL_Id from Prod_Lines
 	  	 Where PL_Desc = @RefPL_Desc
 	 If @RefPL_Id is Null
 	   Begin
 	  	 Select 'Failed - Sampling reference Line not found'
      Return(-100)
 	   End
 	 Select @RefPU_Id = PU_Id from Prod_Units
 	  	 Where PU_Desc = @RefPU_Desc and PL_Id = @RefPL_Id
 	 If @RefPU_Id is Null
 	   Begin
 	  	 Select 'Failed - Sampling reference Unit not found'
      Return(-100)
 	   End
 	 Select @RefVar_Id = Var_Id from Variables
 	  	 Where Var_Desc = @RefVar_Desc and PU_Id = @RefPU_Id
 	 If @RefVar_Id is Null
 	   Begin
 	  	 Select 'Failed - Sampling Variable not found'
      Return(-100)
 	   End
  End
-- Create if PU not found.
Select @PU_Id = Null
Select @PU_Id = PU_Id from Prod_Units 
 	 Where PU_Desc = @PU_Desc 
 	   and PL_Id = @PL_Id
If @PU_Id IS NULL 
  Begin
 	 Execute spEM_CreateProdUnit @PU_Desc,@PL_Id,@UserId,@PU_Id Output
  End
If @PU_Id IS NULL
    BEGIN
 	   Select 'Failed - Error Creating Unit'
      Return(-100)
    END
If  @ParVar_Desc Is not null
  Begin
 	 Select @ParVar_Id = Var_Id from Variables
 	  	 Where Var_Desc = @ParVar_Desc and PU_Id = @PU_Id
 	 If @ParVar_Id is Null
 	   Begin
 	  	 Select 'Failed - Parent Variable not found'
      Return(-100)
 	   End
  End
Select @PUG_Id = NULL 
Select @PUG_Id = PUG_Id 
 	 from PU_Groups 
 	 where PUG_Desc = @PUG_Desc and PU_Id = @PU_Id
If @PUG_Id IS NULL
  Begin
      Select @PUG_Order_Next = NULL
      Select @PUG_Order_Next = MAX(PUG_Order) 
 	 from PU_Groups 
 	 where PU_Id = @PU_Id
      If @PUG_Order_Next Is Null
        Begin
          Select @PUG_Order_Next = 0
        End
 	   Select @PUG_Order_Next = @PUG_Order_Next + 1
 	   Execute spEM_CreatePUG @PUG_Desc,@PU_Id,@PUG_Order_Next,@UserId,@PUG_Id Output
  End
If @PUG_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
 	   Select 'Failed - Error Production Group'
      Return(-100)
    END
-- Determine all the other Ids
Select @Data_Type_Id = NULL, @ET_Id = NULL, @SA_Id = NULL, @DS_Id = NULL ,@Sampling_Type = Null
Select @Data_Type_Id = Data_Type_Id from Data_Type where Data_Type_Desc = @Data_Type_Desc
If @Data_Type_Id IS NULL
  Select @Data_Type_Id = 2
IF @Data_Type_Id != 2 AND @Data_Type_Id != 7
 	 SELECT @iVar_Precision = Null 
Select @ET_Id = ET_Id from Event_Types where ET_Desc = @ET_Desc
Select @SA_Id = SA_Id from Spec_Activations where SA_Desc = @SA_Desc
Select @EventSubtype_Id = Event_Subtype_Id from Event_Subtypes where Event_Subtype_Desc = @EventSubtype
IF @EventSubtype_Id Is NULL AND @EventSubtype Is Not NULL
BEGIN
 	 Select  'Failed - Event Subtype Not Found'
 	 Return(-100)
END
Select @EventDimension_Id = ED_Id from Event_Dimensions where ED_Desc = @EventDimension
Select @PEI_Id = PEI_Id from PrdExec_Inputs where Input_Name = @InputName and PU_Id = @PU_Id
Select @SPC_Calculation_Type_Id = SPC_Calculation_Type_Id from SPC_Calculation_Types where SPC_Calculation_Type_Desc = @SPCCalculationType
Select @SPC_Group_Variable_Type_Id = SPC_Group_Variable_Type_Id from SPC_Group_Variable_Types where SPC_Group_Variable_Type_Desc = @SPCGroupVariableType
SELECT @MasterPUId = isnull(Master_Unit,PU_Id) From Prod_Units where PU_Id = @PU_Id
IF @EventSubtype_Id Is NOT NULL
BEGIN
 	 IF @PEI_Id IS NULL
 	 BEGIN
 	  	 IF @EventSubtype_Id NOT IN (select Distinct Event_Subtype_Id from event_Configuration where pu_Id = @MasterPUId and ET_Id = @ET_Id)
 	  	 BEGIN
 	  	  	   Select  'Failed - Invalid Event Subtype for this unit / event type'
 	  	  	   Return(-100)
 	  	 END
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @EventSubtype_Id NOT IN (select Distinct Event_Subtype_Id from PrdExec_Inputs where PEI_Id = @PEI_Id)
 	  	 BEGIN
 	  	  	   Select  'Failed - Invalid Event Subtype for this unit / event type'
 	  	  	   Return(-100)
 	  	 END
 	 END
END
If @Group_Desc Is Not Null
BEGIN
 	 Select @Group_Id = Group_Id from Security_groups where Group_Desc = @Group_Desc
 	 If @Group_Id is Null  -- have an invalid description 
        BEGIN
          Select  'Failed - invalid Security Group'
          Return(-100)
        END
END
/*
Select @Output_DS_Id = DS_Id from Data_Source where DS_Desc = @ODS_Desc
*/
If @ST_Desc is Not null 
   Begin
      Select @Sampling_Type = ST_Id  From Sampling_Type Where ST_Desc = @ST_Desc
      If @Sampling_Type is Null  Or @Sampling_Type = 48 -- have an invalid description 
        BEGIN
          Select  'Failed - invalid sampling type'
          Return(-100)
        END
   End
If  @MaxRPM is null and @Sampling_Type = 16
  Begin
 	 Select 'Failed - Maximum Rate Per Minute is not correct (null)'
 	 Return(-100)
  End 
If  @ResetValue is null and @Sampling_Type = 16
  Begin
 	 Select 'Failed - Reset Value is not correct (null)'
 	 Return(-100)
  End 
-- If any Ids are not found, error out. 
If @Data_Type_Id IS NULL 
    BEGIN
      Select  'Failed - invalid data type'
      Return(-100)
    END
If @ET_Id IS NULL 
    BEGIN
      Select 'Failed - invalid event type'
      Return(-100)
    END
If @SA_Id IS NULL 
    BEGIN
      Select 'Failed - invalid specification activation'
      Return(-100)
    END
/*******************************************************************************************************************************************
*  	  	  	  	  	 Check For Existing Variable 	  	  	  	  	  	 *
********************************************************************************************************************************************/
Select @Var_Id = Null 
Select @Var_Id = Var_Id 
From Variables 
Where Var_Desc = @Var_Desc and PU_Id = @PU_Id
/*******************************************************************************************************************************************
*  	  	  	  	  	  	 Get Data Source Id 	  	  	  	  	  	 *
********************************************************************************************************************************************/
Select @DS_Id = DS_Id 
From Data_Source 
Where DS_Desc = @DS_Desc
If @DS_Id IS NULL 
     Begin
     Select 'Failed - data source not found'
     Return(-100)
     End
Select @DS_Id = Null 
Select @DS_Id = DS_Id From Data_Source Where DS_Desc = @DS_Desc and  Active = 1 
If @DS_Id IS NULL 
     Begin
     Select 'Failed - data source is not active'
     Return(-100)
     End
If   ((@DS_Id = 1) or (@DS_Id = 4) or (@DS_Id = 7)) OR ((@ET_Id = 1) or (@ET_Id = 2) or(@ET_Id = 3) or(@ET_Id = 4) or(@ET_Id = 22))
  If @Sampling_Interval is Null
 	 Select @iSampling_Interval = 0
  Else
 	 Select @iSampling_Interval = Convert(Integer,@Sampling_Interval)
Else 
  If @DF_TestFreq is Null
 	 Select @iSampling_Interval = 0
  Else
 	 Select @iSampling_Interval = Convert(Integer,@DF_TestFreq)
/* If the variable doesn't exist and is a calculated varaible then change the data source type to Undefined */
If @Var_Id Is Null And @DS_Id = 16
     Select @DS_Id = 4
Select @WriteGroupDSId = Null
If @Write_Group_DS_Desc is not Null
 	 Select @WriteGroupDSId = DS_Id From Data_Source Where DS_Desc = @Write_Group_DS_Desc
/************************************************************************************/
/* Get the Spec_Id 	  	  	  	  	  	  	             */
/************************************************************************************/
If @Spec_Desc Is Not Null And @Spec_Desc <> ''
     Begin
     Select @Index = CharIndex('/', @Spec_Desc)
     If @Index > 0
       Begin
          Select @Prop_Desc = Left(@Spec_Desc, CharIndex('/', @Spec_Desc)-1)
          Select @Spec_Desc = Right(@Spec_Desc, Len(@Spec_Desc)- CharIndex('/', @Spec_Desc))
          Select @Prop_Id = Prop_Id
          From Product_Properties
          Where Prop_Desc = RTrim(LTrim(@Prop_Desc))
          Select @Spec_Id = Spec_Id,@SpecDT = Data_Type_Id
          From Specifications
          Where Prop_Id = @Prop_Id And Spec_Desc = RTrim(LTrim(@Spec_Desc))
          If @Spec_Id Is Null
            Begin
           	 Select 'Failed - invalid specification variable'
               Return(-100) 
            End
          If @SpecDT <> @Data_Type_Id
            Begin
           	 Select 'Failed - invalid specification variable Data Type not correct'
               Return(-100) 
            End
       End
     Else
      Begin
        Select 'Failed - invalid property/specification variable'
        Return(-100) 
      End
     End
/************************************************************************************/
/* Get the Sampling Window 	  	  	  	  	  	             */
/************************************************************************************/
Select @Sampling_Win_Type_Id = Sampling_Window_Type_Data
From Sampling_Window_Types
Where Sampling_Window_Type_Name = RTrim(LTrim(@Sampling_Window_Type))
If @Sampling_Win_Type_Id Is Not Null
    Select @iSampling_Window = @Sampling_Win_Type_Id
/************************************************************************************/
/* Get the Data Quality 	  	  	  	  	  	             */
/************************************************************************************/
Select @Comparison_Operator_Id = Comparison_Operator_Id
From Comparison_Operators
Where Comparison_Operator_Value = RTrim(LTrim(@DQ_Type))
If @DQ_Type Is Not Null And RTrim(LTrim(@DQ_Type)) <> '' And @Comparison_Operator_Id Is Null
Begin
    Select 'Failed - invalid Data Quality type'
    Return(-100)
End
Select @Comparison_Value = @DQ_Value
/************************************************************************************/
/* Get the Extended Test Freq 	  	  	  	  	  	             */
/************************************************************************************/
Select @Ext_Test_Freq_Id = Ext_Test_Freq_Id
From Extended_Test_Freqs
Where Ext_Test_Freq_Desc = RTrim(LTrim(@Extended_Test_Freq))
If @Extended_Test_Freq Is Not Null And RTrim(LTrim(@Extended_Test_Freq)) <> '' And @Ext_Test_Freq_Id Is Null
Begin
    Select 'Failed - invalid extended Test Frequency type'
    Return(-100)
End
SELECT @NewCreate = 0
If @Var_Id Is Null
  Begin
 	 SELECT @NewCreate = 1
    -- Create the variable
 	 Select @PUG_Order = Max(PUG_Order) + 1 from variables where PUG_Id = @PUG_Id
 	 If @PUG_Order is Null Select @PUG_Order = 1
 	 If @ParVar_Id is null
 	  	 Execute spEM_CreateVariable 	 @Var_Desc,@PU_Id,@PUG_Id,@PUG_Order,@UserId,@Var_Id OUTPUT
 	 else
 	   Begin
 	  	 Select @Data_Type_Id = Data_Type_Id,@DS_Id = Coalesce(@DS_Id,DS_Id),@Event_Type = Event_Type,@iVar_Precision = Var_Precision,
 	  	  	  	  @Spec_Id = Spec_Id,@iSampling_Interval = Sampling_Interval,@SPC_Group_Variable_Type_Id = coalesce(@SPC_Group_Variable_Type_Id,SPC_Group_Variable_Type_Id)
 	  	 From Variables where var_Id = @ParVar_Id
 	  	 Execute spEM_CreateChildVariable  @Var_Desc,@ParVar_Id,@PUG_Order,@DS_Id,@Data_Type_Id,@Event_Type,
   	  	  	  	 @iVar_Precision,@SPC_Group_Variable_Type_Id ,@Spec_Id ,@iSampling_Interval ,@UserId ,@EventSubtype_Id,@PEI_Id,@Var_Id    OUTPUT
 	   End
  End
If @Var_Id Is Not Null
  Begin
    -- If not imported value then set to table default value
    Select 	 @Data_Type_Id  	 = IsNull(@Data_Type_Id, Data_Type_Id),
 	  	 @iVar_Precision 	 = CASE WHEN @NewCreate = 0 THEN IsNull(@iVar_Precision, Var_Precision) ELSE @iVar_Precision END,
 	  	 @iSampling_Interval 	 = IsNull(@iSampling_Interval, Sampling_Interval),
 	  	 @iSampling_Offset 	 = IsNull(@iSampling_Offset, Sampling_Offset),
 	  	 @Sampling_Type 	  	 = IsNull(@Sampling_Type, Sampling_Type),
 	  	 @Eng_Units 	  	  	 = IsNull(@Eng_Units, Eng_Units),
 	  	 @DS_Id 	  	  	  	 = IsNull(@DS_Id, DS_Id),
 	  	 @Event_Type 	  	  	 = IsNull(@ET_Id, Event_Type),
 	  	 @Unit_Reject 	  	 = IsNull(@Unit_Reject, Unit_Reject),
 	  	 @Unit_Summarize 	  	 = IsNull(@Unit_Summarize, Unit_Summarize),
 	  	 @Var_Reject 	  	  	 = IsNull(@Var_Reject, Var_Reject),
 	  	 @Rank  	  	  	  	 = IsNull(@Rank, Rank),
 	  	 @CPKSubGroup 	  	 = Isnull(@CPKSubGroup,CPK_SubGroup_Size),
 	  	 @ReadLagTime 	  	 = Isnull(@ReadLagTime,ReadLagTime),
 	  	 @Input_Tag  	  	  	 = IsNull(@Input_Tag, Input_Tag),
 	  	 @Input_Tag2  	  	 = IsNull(@Input_Tag2, Input_Tag2),
 	  	 @Output_Tag  	  	 = IsNull(@Output_Tag, Output_Tag),
 	  	 @DQ_Tag  	  	  	 = IsNull(@DQ_Tag, DQ_Tag),
 	  	 @UEL_Tag  	  	  	 = IsNull(@UEL_Tag, UEL_Tag),
 	  	 @URL_Tag  	  	  	 = IsNull(@URL_Tag, URL_Tag),
 	  	 @UWL_Tag   	  	  	 = IsNull(@UWL_Tag, UWL_Tag),
 	  	 @UUL_Tag   	  	  	 = IsNull(@UUL_Tag, UUL_Tag),
 	  	 @Target_Tag   	  	 = IsNull(@Target_Tag, Target_Tag),
 	  	 @LUL_Tag   	  	  	 = IsNull(@LUL_Tag, LUL_Tag),
 	  	 @LWL_Tag   	  	  	 = IsNull(@LWL_Tag, LWL_Tag),
 	  	 @LRL_Tag   	  	  	 = IsNull(@LRL_Tag, LRL_Tag),
 	  	 @LEL_Tag   	  	  	 = IsNull(@LEL_Tag, LEL_Tag),
 	  	 @rTot_Factor   	  	 = IsNull(@rTot_Factor, Tot_Factor),
 	  	 @Group_Id   	  	  	 = IsNull(@Group_Id, Group_Id),
 	  	 @SA_Id   	  	  	 = IsNull(@SA_Id, SA_Id),
 	  	 @iRepeating   	  	 = IsNull(@iRepeating, Repeating),
 	  	 @Repeat_Backtime   	 = IsNull(@Repeat_Backtime, Repeat_Backtime),
 	  	 @iSampling_Window   	 = IsNull(@iSampling_Window, Sampling_Window),
 	  	 @iShouldArchive   	 = IsNull(@iShouldArchive, ShouldArchive),
 	  	 @Extended_Info   	 = IsNull(@Extended_Info, Extended_Info),
 	  	 @User_Defined1 	  	 = IsNull(@User_Defined1, User_Defined1),
 	  	 @User_Defined2 	  	 = IsNull(@User_Defined2, User_Defined2),
 	  	 @User_Defined3 	  	 = IsNull(@User_Defined3, User_Defined3),
 	  	 @iTF_Reset   	  	 = IsNull(@iTF_Reset, TF_Reset),
 	  	 @Force_Sign_Entry   	 = IsNull(@Force_Sign_Entry, Force_Sign_Entry),
 	  	 @VarAlias   	  	  	 = IsNull(@VarAlias, Test_Name),
 	  	 @Ext_Test_Freq_Id   	 = IsNull(@Ext_Test_Freq_Id, Extended_Test_Freq),
 	  	 @ArrayStatOnly   	 = IsNull(@ArrayStatOnly, ArrayStatOnly),
 	  	 @Comparison_Operator_Id 	 = IsNull(@Comparison_Operator_Id, Comparison_Operator_Id),
 	  	 @Comparison_Value 	 = IsNull(@Comparison_Value, Comparison_Value),
 	  	 @iMaxRPM 	  	  	 = IsNull(@iMaxRPM, Max_RPM),
 	  	 @iResetValue 	  	 = IsNull(@iResetValue, Reset_Value),
 	  	 @iConformance_Variable 	  	 = IsNull(@iConformance_Variable, Is_Conformance_Variable),
 	  	 @iEsignature_Level 	 = IsNull(@iEsignature_Level, Esignature_Level),
 	  	 @RefVar_Id 	  	  	 = IsNull(@RefVar_Id, Sampling_Reference_Var_Id),
 	  	 @WriteGroupDSId 	  	 = IsNull(@WriteGroupDSId,Write_Group_DS_Id),
 	  	 @iStringSpecSetting = Isnull(@iStringSpecSetting,String_Specification_Setting),
 	  	 @iPUGId 	  	  	  	 = PUG_Id,
 	  	 @Lookup 	  	  	  	 = IsNull(@Lookup,Perform_Event_Lookup),
 	  	 @IgnorStatus 	  	 = IsNull(@IgnorStatus,Ignore_Event_Status)
    From Variables
    Where Var_Id = @Var_Id
 	 If @Lookup Is Null
 	  	 Select @Lookup = 1
 	 If @IgnorStatus Is Null
 	  	 Select @IgnorStatus = 0
 	 If @iStringSpecSetting = 0 Select @iStringSpecSetting = Null
 	 Select @Force_Sign_Entry = Isnull(@Force_Sign_Entry,0)
 	 Select @iRepeating = isnull(@iRepeating,0)
    -- Update imported data (need to do last varid)
 	 Execute spEM_PutVarSheetData  @Var_Id, @Data_Type_Id,@iVar_Precision,@iSampling_Interval,@iSampling_Offset,
   	  	  	 @Sampling_Type,@Eng_Units,@DS_Id,@Event_Type,@Unit_Reject,@Unit_Summarize,@Var_Reject,
   	  	  	 @Rank,@Input_Tag,@Output_Tag,@DQ_Tag,@UEL_Tag,@URL_Tag,@UWL_Tag,@UUL_Tag,@Target_Tag,@LUL_Tag,
   	  	  	 @LWL_Tag,@LRL_Tag,@LEL_Tag,@rTot_Factor,@Group_Id,@Spec_Id,@SA_Id,@iRepeating,@Repeat_Backtime,
 	  	  	 @iSampling_Window,@iShouldArchive,@Extended_Info,@User_Defined1,
 	  	  	 @User_Defined2,@User_Defined3,@iTF_Reset,@Force_Sign_Entry,@VarAlias,@Ext_Test_Freq_Id,@ArrayStatOnly,
 	  	  	 @Comparison_Operator_Id,@Comparison_Value,@iMaxRPM,@iResetValue,@iConformance_Variable,@iEsignature_Level,
       	  	 @EventSubtype_Id,@EventDimension_Id,@PEI_Id,@SPC_Calculation_Type_Id,@SPC_Group_Variable_Type_Id,@Input_Tag2,@RefVar_Id,
 	  	  	 @iStringSpecSetting,@WriteGroupDSId,@CPKSubGroup,@ReadLagTime,Null,@Lookup,0,@IgnorStatus,@UserId
 	 IF @iPUGId <> @PUG_Id
 	 BEGIN
 	  	 EXECUTE spEM_ChangeVariableGroup  @Var_Id,@PUG_Id,@UserId
 	 END
  End
Else
  Begin
    Select 'failed - Unable to create variable'
    Return(-100)
End
/************************************************************************************/
/* Update external link 	  	  	  	  	  	             */
/************************************************************************************/
Execute spEM_PutExtLink @Var_Id, 'ag', @External_Link, Null,Null, @UserId
Return(0)
