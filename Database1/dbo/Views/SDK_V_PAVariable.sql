CREATE view SDK_V_PAVariable
as
select
Variables.Var_Id as Id,
Variables.Var_Desc as Variable,
Prod_Lines_Base.PL_Desc as ProductionLine,
Prod_Units_Base.PU_Desc as ProductionUnit,
Variables.Test_Name as TestName,
Variables.Eng_Units as EngineeringUnits,
Data_Source.DS_Desc as DataSource,
Calculations.Calculation_Name as Calculation,
Variables.Comment_Id as CommentId,
Variables.Extended_Info as ExtendedInfo,
Event_Types.ET_Desc as EventType,
Event_Subtypes.Event_Subtype_Desc as EventSubType,
Data_Type.Data_Type_Desc as DataType,
Variables.Input_Tag as InputTag,
Variables.Output_Tag as OutputTag,
Variables.LEL_Tag as LELTag,
Variables.LRL_Tag as LRLTag,
Variables.LUL_Tag as LULTag,
Variables.LWL_Tag as LWLTag,
Variables.UEL_Tag as UELTag,
Variables.URL_Tag as URLTag,
Variables.UUL_Tag as UULTag,
Variables.UWL_Tag as UWLTag,
Variables.Target_Tag as TargetTag,
Variables.Write_Group_DS_Id as WriteGroupDataSourceId,
Variables.Calculation_Id as CalculationId,
Variables.DS_Id as DataSourceId,
Variables.Data_Type_Id as DataTypeId,
Variables.Event_Subtype_Id as EventSubTypeId,
Variables.Event_Type as EventTypeId,
Variables.PU_Id as ProductionUnitId,
Departments_Base.Dept_Desc as Department,
Variables.PVar_Id as ParentVariableId,
parent.Var_Desc as ParentVariable,
Prod_Lines_Base.Dept_Id as DepartmentId,
Prod_Units_Base.PL_Id as ProductionLineId,
Comments.Comment_Text as CommentText,
PU_Groups.PUG_Desc as VariableGroup,
Variables.PUG_Id as VariableGroupId,
Specifications.Spec_Desc as PropertySpecification,
Variables.Spec_Id as PropertySpecificationId,
ED_FieldType_ValidValues.Field_Desc as ESignatureLevel,
Variables.Esignature_Level as ESignatureLevelId,
Specifications.Prop_Id as ProductPropertyId,
Product_Properties.Prop_Desc as ProductProperty,
variables.ArrayStatOnly as ArrayStatOnly,
variables.Comparison_Operator_Id as ComparisonOperatorId,
variables.Comparison_Value as ComparisonValue,
variables.CPK_SubGroup_Size as CPKSubGroupSize,
variables.Debug as Debug,
variables.DQ_Tag as DQTag,
variables.Event_Dimension as EventDimension,
variables.Extended_Test_Freq as ExtendedTestFreq,
variables.External_Link as ExternalLink,
variables.Force_Sign_Entry as ForceSignEntry,
variables.Input_Tag2 as InputTag2,
variables.Is_Active as IsActive,
variables.Is_Conformance_Variable as IsConformanceVariable,
variables.Max_RPM as MaxRPM,
variables.Perform_Event_Lookup as PerformEventLookup,
variables.ProdCalc_Type as ProdCalcType,
variables.User_Defined2 as UserDefined2,
variables.User_Defined3 as UserDefined3,
variables.Var_Precision as VarPrecision,
variables.Var_Reject as VarReject,
variables.Output_DS_Id as OutputDataSourceId,
OutputDS_Src.DS_Desc as OutputDataSource,
variables.PEI_Id as PathInputId,
PEI_Src.Input_Name as PathInput,
variables.Sampling_Reference_Var_Id as SamplingReferenceVarId,
Variables.Var_Desc as SamplingReferenceVar,
variables.Sampling_Type as SamplingTypeId,
SamplingType_Src.ST_Desc as SamplingType,
variables.Group_Id as SecurityGroupId,
SecurityGroup_Src.Group_Desc as SecurityGroup,
variables.SPC_Calculation_Type_Id as SPCCalculationTypeId,
SPCCalculationType_Src.SPC_Calculation_Type_Desc as SPCCalculationType,
variables.SPC_Group_Variable_Type_Id as SPCGroupVariableTypeId,
SPCGroupVariableType_Src.SPC_Group_Variable_Type_Desc as SPCGroupVariableType,
variables.PUG_Order as VarableGroupOrder,
variables.Rank as Rank,
variables.ReadLagTime as ReadLagTime,
variables.Reload_Flag as ReloadFlag,
variables.Repeat_Backtime as RepeatBacktime,
variables.Repeating as Repeating,
variables.Reset_Value as ResetValue,
variables.Retention_Limit as RetentionLimit,
variables.SA_Id as SAId,
variables.Sampling_Interval as SamplingInterval,
variables.Sampling_Offset as SamplingOffset,
variables.Sampling_Window as SamplingWindow,
variables.ShouldArchive as ShouldArchive,
variables.String_Specification_Setting as StringSpecificationSetting,
variables.System as System,
variables.Tag as Tag,
variables.TF_Reset as TFReset,
variables.Tot_Factor as TotFactor,
variables.Unit_Reject as UnitReject,
variables.Unit_Summarize as UnitSummarize,
variables.User_Defined1 as UserDefined1
FROM Departments_Base
 INNER JOIN Prod_Lines_Base ON Prod_Lines_Base.Dept_Id = Departments_Base.Dept_Id
 INNER JOIN Prod_Units_Base ON Prod_Units_Base.PL_Id = Prod_Lines_Base.PL_Id AND Prod_Units_Base.pu_id <> 0
 INNER join Variables_Base as Variables on variables.PU_Id = Prod_Units_Base.PU_Id
 INNER JOIN Data_Source ON data_source.DS_Id = variables.DS_Id
 INNER JOIN Event_Types ON event_types.ET_Id = variables.Event_Type
 INNER JOIN Data_Type ON data_type.Data_Type_Id = variables.Data_Type_Id
 LEFT JOIN Event_SubTypes ON event_subtypes.Event_Subtype_Id = variables.Event_SubType_Id
 LEFT JOIN Calculations ON calculations.Calculation_Id = variables.Calculation_Id
 LEFT JOIN PU_Groups ON variables.PUG_Id = PU_Groups.PUG_Id
 LEFT join Variables_Base parent on variables.Pvar_Id = parent.Var_Id
 Left Join Specifications on Specifications.Spec_Id = Variables.Spec_Id
 left join ED_FieldType_ValidValues on ED_FieldType_ValidValues.ED_Field_Type_Id = 55 and ED_FieldType_ValidValues.Field_Id = Variables.Esignature_Level
 Left Join Product_Properties on Product_Properties.Prop_Id = Specifications.Prop_Id
 Left Join Security_Groups SecurityGroup_Src on SecurityGroup_Src.Group_Id = variables.Group_Id 
 Left Join Data_Source OutputDS_Src on OutputDS_Src.DS_Id = variables.Output_DS_Id 
 Left Join PrdExec_Inputs PEI_Src on PEI_Src.PEI_Id = variables.PEI_Id 
 Left Join Sampling_Type SamplingType_Src on SamplingType_Src.ST_Id = variables.Sampling_Type 
 Left Join SPC_Calculation_Types SPCCalculationType_Src on SPCCalculationType_Src.SPC_Calculation_Type_Id = variables.SPC_Calculation_Type_Id 
 Left Join SPC_Group_Variable_Types SPCGroupVariableType_Src on SPCGroupVariableType_Src.SPC_Group_Variable_Type_Id = variables.SPC_Group_Variable_Type_Id 
LEFT JOIN Comments Comments on Comments.Comment_Id=variables.Comment_Id
