CREATE procedure [dbo].[spSDK_AU_Variable]
@AppUserId int,
@Id int OUTPUT,
@ArrayStatOnly tinyint ,
@Calculation varchar(255) ,
@CalculationId int ,
@CommentId int OUTPUT,
@CommentText text ,
@ComparisonOperatorId int ,
@ComparisonValue varchar(100) ,
@CPKSubGroupSize int ,
@DataSource nvarchar(50) ,
@DataSourceId int ,
@DataType nvarchar(50) ,
@DataTypeId int ,
@Debug bit ,
@Department varchar(200) ,
@DepartmentId int ,
@DQTag varchar(100) ,
@EngineeringUnits nvarchar(15) ,
@ESignatureLevel varchar(200) ,
@ESignatureLevelId int ,
@EventDimension tinyint ,
@EventSubType nvarchar(50) ,
@EventSubTypeId int ,
@EventType nvarchar(50) ,
@EventTypeId tinyint ,
@ExtendedInfo varchar(255) ,
@ExtendedTestFreq int ,
@ExternalLink varchar(100) ,
@ForceSignEntry tinyint ,
@InputTag varchar(255) ,
@InputTag2 varchar(100) ,
@IsActive bit ,
@IsConformanceVariable bit ,
@LELTag varchar(255) ,
@LRLTag varchar(255) ,
@LULTag varchar(255) ,
@LWLTag varchar(255) ,
@MaxRPM float ,
@OutputDataSource varchar(100) ,
@OutputDataSourceId int ,
@OutputTag varchar(255) ,
@ParentVariable nvarchar(50) ,
@ParentVariableId int ,
@PathInput varchar(100) ,
@PathInputId int ,
@PerformEventLookup tinyint ,
@ProdCalcType tinyint ,
@ProductionLine nvarchar(50) ,
@ProductionLineId int ,
@ProductionUnit nvarchar(50) ,
@ProductionUnitId int ,
@ProductProperty nvarchar(50) ,
@ProductPropertyId int ,
@PropertySpecification nvarchar(50) ,
@PropertySpecificationId int ,
@VarableGroupOrder int ,
@Rank smallint ,
@ReadLagTime int ,
@ReloadFlag tinyint ,
@RepeatBacktime int ,
@Repeating tinyint ,
@ResetValue float ,
@RetentionLimit int ,
@SAId tinyint ,
@SamplingInterval smallint ,
@SamplingOffset smallint ,
@SamplingReferenceVar varchar(100) ,
@SamplingReferenceVarId int ,
@SamplingType varchar(100) ,
@SamplingTypeId tinyint ,
@SamplingWindow int ,
@SecurityGroup varchar(100) ,
@SecurityGroupId int ,
@ShouldArchive tinyint ,
@SPCCalculationType varchar(100) ,
@SPCCalculationTypeId int ,
@SPCGroupVariableType varchar(100) ,
@SPCGroupVariableTypeId int ,
@StringSpecificationSetting tinyint ,
@System tinyint ,
@Tag varchar(100) ,
@TargetTag varchar(255) ,
@TestName varchar(200) ,
@TFReset tinyint ,
@TotFactor real ,
@UELTag varchar(255) ,
@UnitReject bit ,
@UnitSummarize bit ,
@URLTag varchar(255) ,
@UserDefined1 varchar(100) ,
@UserDefined2 varchar(100) ,
@UserDefined3 varchar(100) ,
@UULTag varchar(255) ,
@UWLTag varchar(255) ,
@Variable nvarchar(50) ,
@VariableGroup nvarchar(50) ,
@VariableGroupId int ,
@VarPrecision tinyint ,
@VarReject bit ,
@WriteGroupDataSourceId int
AS
DECLARE
 	 @SADesc  	  	  	  	  	  	 VarChar(50),
 	 @WriteGroupDSDesc 	  	 VarChar(50),
 	 @CurrentComment 	  	  	 Int,
 	 @PropSpec 	  	  	  	  	  	 VarChar(150),
 	 @StrEventDimension  VarChar(50),
 	 @SamplingWindowType 	 VarChar(100),
 	 @DQType  	  	  	  	  	  	 VarChar(100),
 	 @StrExtendedTestFreq 	  	 VarChar(100),
 	 @RefPLDesc 	  	  	  	  	 VarChar(50),
 	 @RefPUDesc 	  	  	  	  	 VarChar(50),
 	 @StringSpecSetting 	 VarChar(50),
 	 @OldVarDesc 	  	  	  	  	 nVarChar(50),
 	 @IgnoreStatus 	  	  	 Varchar(10)
DECLARE @Pre60Server bit
EXEC dbo.spSupport_VerifyDB_PDBVersion  '00013.00000.00000.00000' , @Pre60Server OUTPUT
DECLARE @Pre63Server bit
EXEC dbo.spSupport_VerifyDB_PDBVersion  '00013.00000.00960.00000' , @Pre63Server OUTPUT
SET @IgnoreStatus = ''
EXEC dbo.spSDK_AU_LookupIds 	 
 	  	  	  	 @Department 	 OUTPUT,
 	  	  	  	 @DepartmentId OUTPUT, 	 
 	  	  	  	 @ProductionLine OUTPUT, 	 
 	  	  	  	 @ProductionLineId OUTPUT,
 	  	  	  	 @ProductionUnit OUTPUT,
 	  	  	  	 @ProductionUnitId OUTPUT,
 	  	  	  	 @VariableGroup OUTPUT,
 	  	  	  	 @VariableGroupId OUTPUT,
 	  	  	  	 @Variable OUTPUT, 	 
 	  	  	  	 @Id 
 	 
DECLARE  @ReturnMessages TABLE(msg VarChar(100))
SET @SAId = Coalesce(@SAId,2)
SELECT @SADesc = SA_Desc from Spec_Activations WHERE SA_Id = @SAId
SELECT @WriteGroupDSDesc = DS_Desc FROM Data_Source WHERE DS_Id =  @WriteGroupDataSourceId
SELECT @StrEventDimension = ed.ED_Desc FROM Event_Dimensions ed WHERE ed.ED_Id = @EventDimension
SELECT @SamplingWindowType = swt.Sampling_Window_Type_Name FROM Sampling_Window_Types swt WHERE swt.Sampling_Window_Type_Data = @SamplingWindow
SELECT @DQType = co.Comparison_Operator_Value FROM Comparison_Operators co WHERE co.Comparison_Operator_Id = @ComparisonOperatorId
SELECT @StrExtendedTestFreq = etf.Ext_Test_Freq_Desc FROM Extended_Test_Freqs etf WHERE etf.Ext_Test_Freq_Id = @ExtendedTestFreq 
IF @SamplingReferenceVarId IS NOT NULL
BEGIN
 	 SELECT 	 @RefPLDesc = pl.PL_Desc,
 	  	  	  	  	 @RefPUDesc = pu.PU_Desc
 	  	 from Variables_Base as v
 	  	 JOIN Prod_Units_Base pu On pu.PU_Id = v.PU_Id
 	  	 JOIN Prod_Lines_Base pl On Pl.PL_Id = pu.PL_Id
 	  	 WHERE Var_Id = @SamplingReferenceVarId
END
IF @StringSpecificationSetting IS NOT Null
BEGIN
 	  	 SELECT edf.Field_Desc FROM ED_FieldType_ValidValues edf WHERE edf.Field_Id = @StringSpecificationSetting and edf.ED_Field_Type_Id = 73
END
SET @PropSpec = @ProductProperty + '/' + @PropertySpecification
IF @Id IS NOT NULL
BEGIN
 	 IF NOT EXISTS(Select 1 from Variables_Base as Variables WHERE Var_Id = @Id)
 	 BEGIN
 	  	 SELECT 'Variable Not Found For Update'
 	  	 RETURN(-100)
 	 END
 	 SELECT 
 	  	  	 @CurrentComment 	  	  	  	 = v.Comment_Id,
 	  	  	 @OldVarDesc 	  	  	  	  	  	 = v.Var_Desc
 	 from Variables_Base as v
 	 WHERE v.Var_Id = @Id
 	 IF @OldVarDesc <> @Variable 
 	 BEGIN
 	  	  	 SELECT 'Variable Rename Not Supported [' + @OldVarDesc + '] TO [' + @Variable + ']'
 	  	  	 RETURN(-100)
 	 END
END
ELSE
BEGIN
 	 IF EXISTS(Select 1 from Variables_Base as Variables WHERE Var_Desc = @Variable and PU_Id = @ProductionUnitId)
 	 BEGIN
 	  	 SELECT 'Variable already exists - Add Failed'
 	  	 RETURN(-100)
 	 END
END
If (@Pre60Server = 1)
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportVariables
 	  	  	  	  	  	 @Department,@ProductionLine,@ProductionUnit,@VariableGroup,@Variable,
 	  	  	  	  	  	 @DataSource,@WriteGroupDSDesc,@EngineeringUnits,@EventType,@DataType,
 	  	  	  	  	  	 @SamplingInterval,@SamplingOffset,@SamplingType,@SADesc,@VarPrecision,
 	  	  	  	  	  	 @OutputTag,@InputTag,@InputTag2,@DQTag,@URLTag,
 	  	  	  	  	  	 @UWLTag,@TargetTag,@LWLTag,@LRLTag,@ExtendedInfo,
 	  	  	  	  	  	 @UserDefined1,@UserDefined2,@UserDefined3,@PropSpec,@SamplingWindow,
 	  	  	  	  	  	 @SamplingWindowType,@TotFactor,@DQType,@ComparisonValue,@UELTag,
 	  	  	  	  	  	 @UULTag,@LULTag,@LELTag,@Repeating,@SamplingInterval,
 	  	  	  	  	  	 @TFReset,@StrExtendedTestFreq,@ExternalLink,@SecurityGroup,@ShouldArchive,
 	  	  	  	  	  	 @MaxRPM,@ResetValue,@IsConformanceVariable,@ESignatureLevel,@EventSubType,
 	  	  	  	  	  	 @StrEventDimension,@PathInput,@SPCCalculationType,@SPCGroupVariableType,@RefPLDesc,
 	  	  	  	  	  	 @RefPUDesc,@SamplingReferenceVar,@ParentVariable,@RepeatBacktime,@ForceSignEntry,
 	  	  	  	  	  	 @TestName,@ArrayStatOnly,@Rank,@UnitReject,@UnitSummarize,
 	  	  	  	  	  	 @VarReject,@CPKSubGroupSize,@StringSpecSetting,@ReadLagTime,@AppUserId
END
ELSE If (@Pre63Server = 1)
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportVariables
 	  	  	  	  	  	 @Department,@ProductionLine,@ProductionUnit,@VariableGroup,@Variable,
 	  	  	  	  	  	 @DataSource,@WriteGroupDSDesc,@EngineeringUnits,@EventType,@DataType,
 	  	  	  	  	  	 @SamplingInterval,@SamplingOffset,@SamplingType,@SADesc,@VarPrecision,
 	  	  	  	  	  	 @OutputTag,@InputTag,@InputTag2,@DQTag,@URLTag,
 	  	  	  	  	  	 @UWLTag,@TargetTag,@LWLTag,@LRLTag,@ExtendedInfo,
 	  	  	  	  	  	 @UserDefined1,@UserDefined2,@UserDefined3,@PropSpec,@SamplingWindow,
 	  	  	  	  	  	 @SamplingWindowType,@TotFactor,@DQType,@ComparisonValue,@UELTag,
 	  	  	  	  	  	 @UULTag,@LULTag,@LELTag,@Repeating,@SamplingInterval,
 	  	  	  	  	  	 @TFReset,@StrExtendedTestFreq,@ExternalLink,@SecurityGroup,@ShouldArchive,
 	  	  	  	  	  	 @MaxRPM,@ResetValue,@IsConformanceVariable,@ESignatureLevel,@EventSubType,
 	  	  	  	  	  	 @StrEventDimension,@PathInput,@SPCCalculationType,@SPCGroupVariableType,@RefPLDesc,
 	  	  	  	  	  	 @RefPUDesc,@SamplingReferenceVar,@ParentVariable,@RepeatBacktime,@ForceSignEntry,
 	  	  	  	  	  	 @TestName,@ArrayStatOnly,@Rank,@UnitReject,@UnitSummarize,
 	  	  	  	  	  	 @VarReject,@CPKSubGroupSize,@StringSpecSetting,@ReadLagTime,@PerformEventLookup,@AppUserId
END
ELSE 
BEGIN
 	 INSERT INTO @ReturnMessages(msg)
 	  	 EXECUTE spEM_IEImportVariables
 	  	  	  	  	  	 @Department,@ProductionLine,@ProductionUnit,@VariableGroup,@Variable,
 	  	  	  	  	  	 @DataSource,@WriteGroupDSDesc,@EngineeringUnits,@EventType,@DataType,
 	  	  	  	  	  	 @SamplingInterval,@SamplingOffset,@SamplingType,@SADesc,@VarPrecision,
 	  	  	  	  	  	 @OutputTag,@InputTag,@InputTag2,@DQTag,@URLTag,
 	  	  	  	  	  	 @UWLTag,@TargetTag,@LWLTag,@LRLTag,@ExtendedInfo,
 	  	  	  	  	  	 @UserDefined1,@UserDefined2,@UserDefined3,@PropSpec,@SamplingWindow,
 	  	  	  	  	  	 @SamplingWindowType,@TotFactor,@DQType,@ComparisonValue,@UELTag,
 	  	  	  	  	  	 @UULTag,@LULTag,@LELTag,@Repeating,@SamplingInterval,
 	  	  	  	  	  	 @TFReset,@StrExtendedTestFreq,@ExternalLink,@SecurityGroup,@ShouldArchive,
 	  	  	  	  	  	 @MaxRPM,@ResetValue,@IsConformanceVariable,@ESignatureLevel,@EventSubType,
 	  	  	  	  	  	 @StrEventDimension,@PathInput,@SPCCalculationType,@SPCGroupVariableType,@RefPLDesc,
 	  	  	  	  	  	 @RefPUDesc,@SamplingReferenceVar,@ParentVariable,@RepeatBacktime,@ForceSignEntry,
 	  	  	  	  	  	 @TestName,@ArrayStatOnly,@Rank,@UnitReject,@UnitSummarize,
 	  	  	  	  	  	 @VarReject,@CPKSubGroupSize,@StringSpecSetting,@ReadLagTime,@PerformEventLookup,@IgnoreStatus,@AppUserId
END
 	 IF EXISTS(SELECT 1 FROM @ReturnMessages)
 	 BEGIN
 	  	 SELECT msg FROM @ReturnMessages
 	  	 RETURN(-100)
 	 END
 	 ELSE
 	 BEGIN
 	  	 IF @Id IS NULL
 	  	 BEGIN
 	  	  	 SELECT @Id = Var_Id  from Variables_Base as Variables WHERE Var_Desc = @Variable and PU_Id = @ProductionUnitId 
 	  	 END
 	  	 SET @CommentId = COALESCE(@CurrentComment,@CommentId)
 	  	 IF @CommentId IS NOT NULL AND @CommentText IS NULL -- DELETE
 	  	 BEGIN
 	  	  	 EXECUTE spEM_DeleteComment @Id,'ag',@AppUserId
 	  	  	 SET @CommentId = NULL
 	  	 END
 	  	 IF @CommentId IS NULL AND @CommentText IS NOT NULL --ADD
 	  	 BEGIN
 	  	  	 EXECUTE spEM_CreateComment  @Id,'ag',@AppUserId,1,@CommentId Output
 	  	 END
 	  	 IF @CommentId IS NOT NULL -- UPDATE TEXT
 	  	 BEGIN
 	  	  	 UPDATE Comments SET Comment = @CommentText, Comment_Text = @CommentText WHERE Comment_Id = @CommentId
 	  	 END
 	 END
 	 RETURN(1)
