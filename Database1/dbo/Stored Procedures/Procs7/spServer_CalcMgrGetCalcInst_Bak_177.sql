CREATE PROCEDURE dbo.[spServer_CalcMgrGetCalcInst_Bak_177]
AS
Declare
  @ProdDayMinutes int ,
  @ShiftInterval int ,
  @ShiftOffset int ,
  @ActualProdDayMinutes int ,
  @ActualShiftInterval int ,
  @ActualShiftOffset int ,
  @TZ nVarChar(255),
  @@TheId int,
  @@MasterUnit int,
  @Value nvarchar(50)
Declare @ClcVars TABLE (
 	 TheId int Identity(1,1),
 	 calculation_id int NULL, 
 	 Result_Var_Id int NULL, 
 	 calc_input_id int NULL, 
 	 member_var_id int NULL, 
 	 Test_Name nvarchar(50) NULL,
 	 ShouldArchive int NULL, 
 	 Default_Value nvarchar(255) NULL,
 	 input_name nvarchar(255) NULL,
 	 PU_Id int NULL, 
 	 MasterUnit int NULL, 
 	 Var_Precision int NULL, 
 	 Sampling_Interval int NULL, 
 	 Sampling_Offset int NULL, 
 	 Sampling_Window int NULL, 
 	 Event_Type int NULL, 
 	 Data_Type_Id int NULL, 
 	 ResultVarDesc nvarchar(255) NULL,
 	 ProdDayMinutes int NULL, 
 	 ShiftInterval int NULL, 
 	 ShiftOffset int NULL,
 	 calc_input_order int NULL,
 	 event_sub_type int NULL,
 	 GenealogyEvent_PUId int NULL,
  	 DebugMode int NULL,
  	 Var_Event_Type int NULL,
 	 TimeZone nVarChar(100) NULL,
 	 Ignore_Event_Status int NULL) 
Insert Into @ClcVars (
 	 calculation_id,
 	 Result_Var_Id,
 	 calc_input_id,
 	 member_var_id,
 	 Test_Name,
 	 ShouldArchive,
 	 Default_Value,
 	 input_name,
 	 PU_Id,
 	 MasterUnit,
 	 Var_Precision,
 	 Sampling_Interval,
 	 Sampling_Offset,
 	 Sampling_Window,
 	 Event_Type,
 	 Data_Type_Id,
 	 ResultVarDesc,
 	 ProdDayMinutes,
 	 ShiftInterval,
 	 ShiftOffset,
 	 calc_input_order,
 	 event_sub_type ,
 	 GenealogyEvent_PUId,
  DebugMode,
  Var_Event_Type,
 	 TimeZone,
 	 Ignore_Event_Status
)
(Select c.calculation_id, 
 	 Result_Var_Id=v.var_id, 
 	 i.calc_input_id, 
 	 d.member_var_id, 
 	 d.Alias_Name,
 	 v.ShouldArchive, 
 	 Default_Value=COALESCE(d.default_value,i.default_value), 
 	 input_name=COALESCE(d.input_name,i.input_name),
 	 PU_Id = v.PU_Id,
 	 MasterUnit = COALESCE(m.Master_Unit, v.PU_Id),
 	 Var_Precision = COALESCE(v.Var_Precision,0),
 	 Sampling_Interval = COALESCE(v.Sampling_Interval,0),
 	 Sampling_Offset = COALESCE(v.Sampling_Offset,0),
 	 Sampling_Window = COALESCE(v.Sampling_Window,0),
 	 Event_Type = v.Event_Type,
 	 Data_Type_Id = v.Data_Type_Id,
 	 ResultVarDesc = v.var_desc,
 	 ProdDayMinutes = NULL,
 	 ShiftInterval = NULL,
 	 ShiftOffset = NULL,
 	 i.calc_input_order,
 	 v.event_subtype_id,
 	 d.PU_Id,
  v.Debug,
  NULL,
 	 '',
 	 COALESCE(v.Ignore_Event_Status,0)
 	 
From Calculations c
join Variables_Base v on v.calculation_id = c.calculation_id
join Prod_Units_Base m on m.PU_Id = v.PU_Id
left outer join calculation_inputs i on v.calculation_id = i.calculation_id
left outer join calculation_input_data d on d.calc_input_id = i.calc_input_id and v.var_id = d.result_var_id
where v.ds_id = 16 and v.calculation_id is not null and v.is_active = 1)
update @ClcVars set Var_Event_Type = v.Event_Type 
from variables_base v, @ClcVars c
where c.member_var_id is not null and v.var_id = c.member_var_id
-- Update the ShiftInteral, ShiftOffset and ProdDayMinutes fields
Declare Clc_Cursor INSENSITIVE CURSOR For (Select distinct MasterUnit From @ClcVars) For Read Only
Open Clc_Cursor  
Fetch_Loop:
  Fetch Next From Clc_Cursor Into @@MasterUnit 	  	 
  If (@@Fetch_Status = 0)
    Begin
 	  	  	 select @TZ = dbo.fnServer_GetTimeZone(@@MasterUnit)
      Select @ActualShiftInterval  = NULL
      Select @ActualShiftOffset    = NULL
      Select @ActualProdDayMinutes = NULL
      	 Execute spServer_CmnGetLocalInfoByUnit @@MasterUnit,@ActualShiftInterval OUTPUT,@ActualShiftOffset OUTPUT,@ActualProdDayMinutes OUTPUT
      Update @ClcVars Set 
            ShiftInterval  = @ActualShiftInterval,
            ShiftOffset    = @ActualShiftOffset,
            ProdDayMinutes = @ActualProdDayMinutes,
 	  	  	  	  	  	 TimeZone 	  	  	  = @TZ
 	  	        Where MasterUnit = @@MasterUnit 	 
      Goto Fetch_Loop
    End
Close Clc_Cursor
Deallocate Clc_Cursor
-------------------------------------------------------------------------------
-- For Input Genealogy variables, it should return the PEI Id on the 
-- Event_Sub_type
--
-- AJ: 25-Nov-04
-------------------------------------------------------------------------------
UPDATE 	 T
 	 SET 	 T.Event_Sub_Type = v.Pei_Id
 	 FROM 	 @ClcVars T
 	 JOIN 	 Variables_Base V
 	 ON  	 T.Result_Var_Id 	 = V.Var_Id
 	 WHERE 	 T.Event_Type = 17
Select
  	 calculation_id,
 	 Result_Var_Id,
 	 calc_input_id,
 	 member_var_id,
 	 ShouldArchive,
 	 Default_Value,
 	 input_name,
  PU_Id,
  MasterUnit,
  Var_Precision,
  Sampling_Interval,
  Sampling_Offset,
  Sampling_Window,
  Event_Type,
  Data_Type_Id,
 	 ResultVarDesc,
 	 ProdDayMinutes,
 	 ShiftInterval,
 	 ShiftOffset,
 	 event_sub_type,
 	 Test_Name,
 	 GenealogyEvent_PUId,
  DebugMode,
  	 Var_Event_Type,
 	 TimeZone,
 	 Ignore_Event_Status
 	 
  From @ClcVars
  Order by calculation_id, result_var_id,calc_input_order
