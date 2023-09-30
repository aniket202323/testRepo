Create Procedure dbo.spEM_DropVariableSlave
 @Var_Id int
 AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Test Cursor Error
  --   2 = Calcs Cursor Error
  --   50101 = Unknown Error
  --
  DECLARE  	 @DropSlaveReturnCode int, 
 	 @AlarmId int,
 	 @CalcId int,
 	 @RS_Id Int,
 	 @Sql 	 VarChar(7000)
 	 
 	 DECLARE 	 @Eq2Id 	  	  	 nVarChar(400),
 	  	  	  	  	 @Eq2Name 	  	 nVarChar(400),
 	  	  	  	  	 @ClassName 	 nVarChar(400),
 	  	  	  	  	 @ClassCount Int
-- Old Calculations
select @DropSlaveReturnCode = 0
-- Clean up new calcs
    Select @CalcId = Null
    Select @CalcId = Calculation_ID From Variables where var_Id = @Var_Id
    Delete From Calculation_Instance_Dependencies where Result_Var_Id =  @Var_Id or  Var_Id =  @Var_Id
    Delete From Calculation_Input_Data where  Result_Var_Id = @Var_Id or Member_Var_Id = @Var_Id
    Delete From Calculation_Dependency_Data  Where Var_Id = @Var_Id or Result_Var_Id = @Var_Id
-- Clean up COA
        update comments set shoulddelete = 1, comment = '',Comment_Text = '' where comment_id in (select Comment_Id From COA_Items where Var_ID = @Var_Id)
        Delete From COA_Items Where  Var_ID = @Var_Id
  -- END
  IF @DropSlaveReturnCode = 0
    BEGIN
      DELETE FROM GB_Dset_Data WHERE Var_Id = @Var_Id
      Select  Distinct RSum_Id into #TempRS  from gb_rsum_data where Var_Id = @Var_Id
        Execute ('DECLARE RS CURSOR Global ' +
        'FOR SELECT  RSum_Id From #TempRS  ' +
        'FOR READ ONLY ')
      OPEN RS
      Next_RS:
       Fetch Next From RS InTo @RS_Id
       If @@Fetch_Status = 0
 	 Begin
 	     Delete from GB_RSum_Data WHERE Var_Id = @Var_Id and Rsum_Id = @RS_Id
 	     GoTo Next_RS
 	 End
      Close RS
      Deallocate RS
      Drop Table #TempRS
      DELETE FROM Sheet_Variables WHERE Var_Id = @Var_Id
      DELETE FROM Trans_Variables WHERE Var_Id = @Var_Id
      DELETE FROM Var_Specs WHERE Var_Id = @Var_Id
      DELETE FROM Variable_Alias WHERE Src_Var_Id = @Var_Id
      DELETE FROM Variable_Alias WHERE Dst_Var_Id = @Var_Id
 	  UPDATE Tag_Equivalence set Var_Id = Null WHERE Var_Id = @Var_Id
 	  DELETE From Sheet_Plots Where var_Id1 = @Var_Id or var_Id2 = @Var_Id or var_Id3 = @Var_Id 	 or var_Id4 = @Var_Id or var_Id5 = @Var_Id
      Select Alarm_Id InTo #AC  From  Alarms Where ATD_Id in (select ATD_Id From   Alarm_Template_Var_Data WHERE Var_Id = @Var_Id)
      -- delete alarms
      Execute ('DECLARE AC CURSOR Global ' +
        'FOR SELECT  Alarm_Id From #AC  ' +
        'FOR READ ONLY ')
      OPEN AC
      Fetch_Next_Alarm:
      FETCH NEXT FROM AC INTO  @AlarmId
      IF @@FETCH_STATUS = 0
        BEGIN
 	 Delete From Alarm_History Where Alarm_Id = @AlarmId
 	 Delete From Alarms Where Alarm_Id = @AlarmId
 	 Goto Fetch_Next_Alarm
        End
       Close AC
       Deallocate AC
       Delete From   Alarm_Template_Var_Data  Where  Var_Id = @Var_Id
 	 delete dashboard_parameter_values from dashboard_parameter_values 
 	 inner join dashboard_template_parameters on dashboard_template_parameters.dashboard_template_parameter_id = dashboard_parameter_values.dashboard_template_parameter_id
 	 inner join dashboard_parameter_types  on dashboard_parameter_types.dashboard_parameter_type_id = dashboard_template_parameters.dashboard_parameter_type_id
 	 where dashboard_parameter_value = Convert(nVarChar(10),@Var_Id) and (dashboard_parameter_type_desc = '38229' or dashboard_parameter_type_desc = '38230') and dashboard_parameter_column = 2
 	 delete dashboard_parameter_default_values from dashboard_parameter_default_values 
 	 inner join dashboard_template_parameters on dashboard_template_parameters.dashboard_template_parameter_id = dashboard_parameter_default_values.dashboard_template_parameter_id
 	 Inner join dashboard_parameter_types  on dashboard_parameter_types.dashboard_parameter_type_id = dashboard_template_parameters.dashboard_parameter_type_id
 	 where dashboard_parameter_value = Convert(nVarChar(10),@Var_Id) and (dashboard_parameter_type_desc = '38229' or dashboard_parameter_type_desc = '38230') and dashboard_parameter_column = 2
  --
  --  Add for Customers which have var_lookup table
  --  DELETE FROM Var_Lookup WHERE Var_Id = @Var_Id
 	 --         
 	 
 	 SELECT @Eq2Id = CONVERT(nvarchar(400),Origin1EquipmentId),@Eq2Name = Origin1Name
 	   FROM Variables_Aspect_EquipmentProperty
 	   WHERE Var_Id = @Var_Id
 	 IF @Eq2Id IS Not Null
 	 BEGIN
 	  	 SELECT @ClassName = class
 	  	  	 FROM Property_Equipment_EquipmentClass
 	  	  	 WHERE EquipmentId = @Eq2Id
 	  	 SELECT @ClassCount = Count(*)
 	  	  	 FROM Property_Equipment_EquipmentClass a
 	  	  	 JOIN Variables_Aspect_EquipmentProperty b on b.Origin1EquipmentId = a.EquipmentId 
 	  	  	  	 WHERE class =  @ClassName
 	  	 IF @ClassName IS NOT NULL and @ClassCount = 1
 	  	  	 DELETE FROM Variables_Aspect_EquipmentProperty  
 	  	  	  	 WHERE Origin2EquipmentClassName = @ClassName
 	  	  	  	  	 and Origin2PropertyName = @Eq2Name
 	  	 DELETE FROM Variables_Aspect_EquipmentProperty  
 	  	  	 WHERE Origin2EquipmentClassName = @Eq2Id
 	  	  	  	 and Origin2PropertyName = @Eq2Name
 	  	 DELETE FROM Variables_Aspect_EquipmentProperty   WHERE Var_Id = @Var_Id
 	 END
 	 SET @Eq2Id = NULL
 	 SET @Eq2Name = NULL
  	 SELECT @Eq2Id = CONVERT(nvarchar(400),a.Origin1MaterialDefinitionId),@Eq2Name = Origin1Name
 	   FROM Variables_Aspect_MaterialDefinitionProperty a
 	   WHERE Var_Id = @Var_Id
 	 IF @Eq2Id IS Not Null
 	 BEGIN
 	  	 SELECT @ClassName = a.MaterialClassName 
 	  	  	 FROM MaterialClass_MaterialDefinition a
 	  	  	 WHERE a.MaterialDefinitionId  = @Eq2Id
 	  	 SELECT @ClassCount = Count(*)
 	  	  	 FROM MaterialClass_MaterialDefinition a
 	  	  	 JOIN Variables_Aspect_MaterialDefinitionProperty b on b.Origin1MaterialDefinitionId  = a.MaterialDefinitionId  
 	  	  	  	 WHERE MaterialClassName =  @ClassName
 	  	 IF @ClassName IS NOT NULL and @ClassCount = 1
 	  	  	 DELETE FROM Variables_Aspect_MaterialDefinitionProperty  
 	  	  	  	 WHERE Origin2MaterialClassName = @ClassName
 	  	  	  	  	 and Origin2PropertyName = @Eq2Name
 	   DELETE FROM Variables_Aspect_MaterialDefinitionProperty  
 	  	 WHERE Origin2MaterialClassName = @Eq2Id
 	  	  	 and Origin2PropertyName = @Eq2Name
 	  	 DELETE FROM Variables_Aspect_MaterialDefinitionProperty WHERE Var_Id = @Var_Id
  END
  Update Variables_Base set Var_Desc = SUBSTRING('<'+ CONVERT(nVarChar(10),@Var_Id) + '>' + Var_Desc,1,25),
 	  	 Data_Type_Id = 2,Var_Precision = 2,Sampling_Interval = NULL,Sampling_Offset = NULL,Sampling_Type = NULL,
 	  	 Eng_Units = NULL,DS_Id = 4,PU_Id = 0,PUG_Id = 0, PUG_Order = -2,PVar_Id = NULL,Event_Type = 0,Var_Reject = 0,
 	  	 Unit_Summarize = 1,Unit_Reject = 0,Rank = 0,Input_Tag = NULL,Output_Tag = NULL,DQ_Tag = NULL,UEL_Tag = NULL,
 	  	 URL_Tag = NULL,UWL_Tag = NULL,UUL_Tag = NULL,Target_Tag = NULL,LUL_Tag = NULL,LWL_Tag = NULL,LRL_Tag = NULL,
 	  	 LEL_Tag = NULL,Tot_Factor = NULL,Group_Id = NULL,Spec_Id = NULL,SA_Id = 2,Repeating = NULL,Repeat_Backtime = NULL,
 	  	 Sampling_Window = NULL,ShouldArchive = 1,Extended_Info = NULL,
 	  	 ProdCalc_Type = NULL,External_link = NULL,TF_Reset = 0,Tag = Null,Calculation_ID = Null,Comparison_Operator_Id = Null,
 	  	 Comparison_Value = Null,Output_DS_Id = Null,User_Defined1 = Null,User_Defined2 = Null,User_Defined3 = Null,
 	  	 ArrayStatOnly = Null,Force_Sign_Entry = Null,Extended_Test_Freq = Null,Test_Name = Null 
 	  	 WHERE Var_Id = @Var_Id
    END
RETURN(@DropSlaveReturnCode)
