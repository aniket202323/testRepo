--   spEMEC_ConfigureModel5014 3180,1
CREATE Procedure dbo.spEMEC_ConfigureModel5014-- 3176,1
@EC_Id int,
@Activate bit
 AS
Declare @Insert_Id int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,1,'spEMEC_ConfigureModel5014',Convert(nVarChar(10),@EC_Id) + ','  + 
 	 Convert(nVarChar(10),@Activate), dbo.fnServer_CmnGetDate(getUTCdate()))
---------------------------------------------------------------
-- Local Variables and Constants
---------------------------------------------------------------
Declare @ED_Model_Id int
Declare @PU_Id int
Declare @NewCalcName nvarchar(50)
Declare @WasteVarId int, @FaultVarId int
Declare @NewCalcId int
Declare @NewCalcVariableId int
Declare @PUG_ID int
Declare @Calc_Input_A int
Declare @Calc_Input_B int
Declare @Calc_Input_C int
Declare @Calc_Input_D int
Declare @Calc_Input_E int
Declare @Calc_Input_F int
Declare @Calc_Input_G int
Declare @WType 	  	 nvarchar(50)
Declare @WMeasure 	 nvarchar(50)
Declare @iType 	  	 Int
Declare @iMeasure 	 Int
Declare @VarDesc nvarchar(50)
---------------------------------------------------------------
-- Is Model 5400 being configured For This Unit?
---------------------------------------------------------------
Select @ED_Model_Id = ED_Model_Id, @PU_Id = PU_Id from event_configuration where EC_Id = @EC_Id
If (@ED_Model_Id <> 5400)
    goto Proc_Exit
select @PUG_ID=PUG_Id from PU_Groups where pu_id = @PU_Id and PUG_Desc = 'Model 5014 Calculation'
If @PUG_ID Is NULL
     exec spEM_CreatePUG 'Model 5014 Calculation', @PU_Id, 2, 1, @PUG_ID output
Select @NewCalcId = NULL
select @NewCalcId = Calculation_Id
 	  From calculations 
 	 Where Calculation_Name = 'Model 5014 Autolog Waste Calc'
If @NewCalcId Is Null
BEGIN
 	 exec spEMCC_SaveCalc  'Model 5014 Autolog Waste Calc', 'Model 5014 Autolog Waste Calc', 2, '', 'Sample5014Calc', '1.0', 0, 1, 0, 0, 1, 1,@NewCalcId Output
 	 Update Calculations set System_Calculation = 1 where Calculation_Id = @NewCalcId
 	 exec spEMCC_SaveInput  @NewCalcId, 'a', 'PUId', 1, 2, 6,  NULL, 0,0, 1,@Calc_Input_A Output
 	 exec spEMCC_SaveInput  @NewCalcId, 'b', 'Time', 2, 2, 27, NULL, 0,0, 1,@Calc_Input_B Output
 	 exec spEMCC_SaveInput  @NewCalcId, 'c', 'Amount', 3, 3, 7,  NULL, 0, 0,1,@Calc_Input_C Output
 	 exec spEMCC_SaveInput  @NewCalcId, 'd', 'Fault', 4, 3, 7,  NULL, 1,0, 1,@Calc_Input_D Output
 	 exec spEMCC_SaveInput  @NewCalcId, 'e', 'Type', 5, 1, 7,  NULL, 1, 0,1,@Calc_Input_E Output
 	 exec spEMCC_SaveInput  @NewCalcId, 'f', 'Measure', 6, 1, 7,  NULL, 1,0, 1,@Calc_Input_F Output
 	 exec spEMCC_SaveInput  @NewCalcId, 'g', 'ECId', 7, 1, 7,  @EC_Id, 1,0, 1,@Calc_Input_G Output
END
ELSE
BEGIN
 	 Select @Calc_Input_A = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'a'
 	 Select @Calc_Input_B = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'b'
 	 Select @Calc_Input_C = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'c'
 	 Select @Calc_Input_D = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'd'
 	 Select @Calc_Input_E = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'e'
 	 Select @Calc_Input_F = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'f'
 	 Select @Calc_Input_G = Calc_Input_Id  From Calculation_Inputs Where Calculation_Id = @NewCalcId and Alias = 'g'
END
---------------------------------------------------------------
-- Get the variables being used for this model
---------------------------------------------------------------
Select @WasteVarId = convert(int, Convert(nVarChar(10),ecv.value)) 
 	 From event_configuration_data ecd
 	 Join event_configuration_values ecv on ecv.ecv_Id = ecd.ecv_Id
 	 where ecd.ec_Id  = @EC_Id and ED_Field_Id = 2814
Select @FaultVarId = convert(int, Convert(nVarChar(10),ecv.value)) 
 	 From event_configuration_data ecd
 	 Join event_configuration_values ecv on ecv.ecv_Id = ecd.ecv_Id
 	 where ecd.ec_Id  = @EC_Id and ED_Field_Id = 2815
Select @iType = convert(int,Convert(nVarChar(10),ecv.value)) 
 	 From event_configuration_data ecd
 	 Join event_configuration_values ecv on ecv.ecv_Id = ecd.ecv_Id
 	 where ecd.ec_Id  = @EC_Id and ED_Field_Id = 2829
Select @iMeasure = convert(int,Convert(nVarChar(10),ecv.value)) 
 	 From event_configuration_data ecd
 	 Join event_configuration_values ecv on ecv.ecv_Id = ecd.ecv_Id
 	 where ecd.ec_Id  = @EC_Id and ED_Field_Id = 2830
Select @WType = WET_Name
 	 From Waste_Event_Type
 	 Where WET_Id = @iType
Select @WMeasure = WEMT_Name
 	 From Waste_Event_Meas
 	 Where WEMT_Id = @iMeasure
Select @VarDesc = '[' + Convert(nVarChar(10),@EC_Id) + ']Model5014Calc'
Select @NewCalcVariableId = NULL
Select @NewCalcVariableId = Var_Id From Variables Where Var_Desc = @VarDesc and PU_ID = @PU_Id
--------------------------------------------------------------
-- Delete the Variable if user is attempting to Deactivate
--------------------------------------------------------------
If @Activate <> 1
Begin
     If @NewCalcVariableId Is Not Null     
          exec spEM_DropVariable @NewCalcVariableId, 1
     GoTo Proc_Exit --No More Configuration
End
---------------------------------------------------------------
-- Create New Variable For This Unit
---------------------------------------------------------------
If @NewCalcVariableId Is Null
BEGIN
 	 exec spEM_CreateVariable @VarDesc, @PU_Id, @PUG_ID, -1, 1, @NewCalcVariableId output
 	 exec spEM_PutVarSheetData @NewCalcVariableId, 2, 2, 0, 0, NULL, NULL, 16, 0, 0,
 	  	  	 1, 0, 0, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 
 	  	  	 NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 1, 0,
 	  	  	 NULL, 0, 1, NULL, NULL, NULL, NULL, 0, 0, NULL,
 	  	  	 1, 0, NULL, NULL, NULL, NULL, 1, NULL, NULL, NULL, 
 	  	  	 NULL, NULL, NULL, NULL, NULL, NULL,NUll,NUll,Null,Null,
 	  	  	 1,0,0,1
END
exec spEMCC_BuildDataSetUpdate 35, @NewCalcId, @Calc_Input_C, @NewCalcVariableId, @WasteVarId, '', '', 1
exec spEMCC_BuildDataSetUpdate 35, @NewCalcId, @Calc_Input_D, @NewCalcVariableId, @FaultVarId, '', '', 1
exec spEMCC_BuildDataSetUpdate 35, @NewCalcId, @Calc_Input_E, @NewCalcVariableId, Null, @WType, '', 1
exec spEMCC_BuildDataSetUpdate 35, @NewCalcId, @Calc_Input_F, @NewCalcVariableId, Null, @WMeasure, '', 1
exec spEMCC_BuildDataSetUpdate 35, @NewCalcId, @Calc_Input_G, @NewCalcVariableId, Null, @EC_Id, '', 1
---------------------------------------------------------------
-- Associate Calculation and New Variable
---------------------------------------------------------------
exec spEMCC_BuildDataSetUpdate 94, @NewCalcId, @NewCalcVariableId, 0, 0, '', '', 1
proc_Exit:
