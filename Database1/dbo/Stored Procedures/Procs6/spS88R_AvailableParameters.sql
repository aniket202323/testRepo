CREATE procedure [dbo].[spS88R_AvailableParameters]
--Declare
@AnalysisId int
AS
/******************************************************
-- For Testing
--*******************************************************
spS88R_AvailableParameters 1
Select @AnalysisId = 2
select * from Batch_Results_Selections
insert into Batch_Results_Selections select 34969,35,1,34969,1,1
--*******************************************************/
Create Table #ParameterData (
 ProductionLine nVarChar(50) NULL,
 UnitProcedure nVarChar(100) NULL, 
 Operation nVarChar(100) NULL, 
 Phase nVarChar(100) NULL, 
 ParameterName nVarChar(100) NULL,
 ParameterDescription nVarChar(100) NULL,
 VariableId INT NULL
)
Create Table #EquipmentUnits
(
 	 UnitId int
)
Declare @BatchId int
Declare @BatchName nVarChar(50)
-- Get Reference Batch Number
Select @BatchId = min(Batch_Event_Id)
  From Batch_Results_Selections
  Where Analysis_id = @AnalysisId and
        Selected > 0
If @BatchId Is Null
  Begin
    RaisError ('SP: Reference Batch Cannot Be Found',16,1)
    Return
  End
Insert Into #EquipmentUnits
Select ProcedureUnits.PU_ID
FROM Prod_Units ProcedureUnits
 	 Join Events UnitProcedureEvents ON UnitProcedureEvents.Pu_Id = ProcedureUnits.PU_Id
 	 Join Event_Components EC ON EC.Event_Id = UnitProcedureEvents.Event_Id
 	 Join Events BatchEvent ON BatchEvent.Event_Id = EC.Source_Event_Id
WHERE BatchEvent.Event_Id = @BatchId
Declare @UnitCount int
Select @UnitCount = Count(*) From #EquipmentUnits
if (@UnitCount < 1) 
 	 Begin
 	  	 Raiserror ('SP: No Equipment Units Found!', 16,1)
 	  	 Return
 	 End
Declare @@ProductionLineId INT
Declare @@ProductionLineName nvarchar(255)
Select @@ProductionLineId = PL_Id
From Prod_Units
Where PU_Id = ( Select TOP 1 UnitId
 	  	  	  	 From #EquipmentUnits)
SELECT 	 @@ProductionLineName = PL.PL_Desc
FROM 	 Prod_Units PU
JOIN 	 Prod_Lines PL ON PL.PL_Id = PU.PL_Id
WHERE 	 PU.Extended_Info = 'BATCH:' AND PL.PL_Id = @@ProductionLineId
IF (@@ProductionLineName IS NULL) 
BEGIN
 	 RAISERROR ('SP: No Production Line Found!', 16,1)
 	 RETURN
END
Declare @@UnitProcedureEventId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@UnitId int
Declare @@OperationEventId int
Declare @@OperationName nVarChar(100)
Declare @@PhaseEventId int
Declare @@PhaseName nVarChar(100)
DECLARE ProcedureCursor Insensitive Cursor
 	 For Select PE.Event_Id, PU.PU_Desc, PU.PU_Id
 	 From Events PE
 	  	 Join Prod_Units PU ON PU.PU_Id = PE.PU_Id
 	  	 Join Event_Components EC ON EC.Event_Id = PE.Event_Id
 	 Where EC.Source_Event_Id = @BatchId
Open ProcedureCursor
Fetch Next From ProcedureCursor Into @@UnitProcedureEventId, @@UnitProcedureName, @@UnitId
While @@Fetch_Status = 0
 	 Begin
 	  	  	 -- First Insert All Unit Procedures
 	  	 DECLARE OperationCursor Insensitive Cursor
 	  	  	 For Select UDE_ID, Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc))
 	  	  	 From User_Defined_Events 
 	  	  	 Where Event_Id = @@UnitProcedureEventId
 	  	 Open OperationCursor
 	  	 Fetch Next From OperationCursor Into @@OperationEventId, @@OperationName
 	  	 While @@Fetch_Status = 0
 	  	  	 Begin
 	  	  	  	 -- Insert Operations
 	  	  	  	 DECLARE PhaseCursor Insensitive Cursor
 	  	  	  	  	 For Select UDE_ID, Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc))
 	  	  	  	  	 From User_Defined_Events 
 	  	  	  	  	 Where Parent_UDE_Id = @@OperationEventId
 	  	  	  	 Open PhaseCursor
 	  	  	  	 Fetch Next From PhaseCursor Into @@PhaseEventId, @@PhaseName
 	  	  	  	 While @@Fetch_Status = 0
 	  	  	  	  	 Begin
 	  	  	  	  	  	 -- Insert Phases and Variables
 	  	 
 	  	  	  	  	  	 Insert Into #ParameterData
 	  	  	  	  	  	  	 Select 	  	  ProductionLine = @@ProductionLineName,
 	  	  	  	  	  	  	  	  	  	  UnitProcedure = @@UnitProcedureName,
 	  	  	  	  	  	  	  	  	  	  Operation = @@OperationName,
 	  	  	  	  	  	  	  	  	  	  Phase = @@PhaseName,
 	  	  	  	  	  	  	  	  	  	  ParameterName = V.Test_Name,
 	  	  	  	  	  	  	  	  	  	  ParameterDescription = V.Var_Desc,
 	  	  	  	  	  	  	  	  	  	  VariableId = V.Var_Id
 	  	  	  	  	  	  	 From Variables V
 	  	  	  	  	  	  	  	 Join PU_Groups PUG ON PUG.PUG_ID = V.PUG_ID
 	  	  	  	  	  	  	 Where @@PhaseName like '%' + SUBString(PUG.External_Link, 3 , Len(PUG.External_Link) - 2) + '%' And V.PU_Id = @@UnitId
 	  	  	  	  	  	  	 And (V.Data_Type_Id = 1 or V.Data_Type_Id = 2) -- Consider only numeric (integer or float) variables ECR# 35290 
 	  	  	  	  	  	 
 	  	  	  	  	  	 Fetch Next From PhaseCursor Into @@PhaseEventId, @@PhaseName
 	  	  	  	  	 End 	  	  	  	 
 	  	  	  	  	 
 	  	  	  	  	 Close PhaseCursor
 	  	  	  	  	 Deallocate PhaseCursor
 	  	  	  	 Fetch Next From OperationCursor Into @@OperationEventId, @@OperationName
 	  	  	 End
 	  	  	 Close OperationCursor
 	  	  	 Deallocate OperationCursor 
 	  	 Fetch Next From ProcedureCursor Into @@UnitProcedureEventId, @@UnitProcedureName, @@UnitId
 	 End
Close ProcedureCursor
Deallocate ProcedureCursor 
Update #ParameterData 
  Set UnitProcedure = NULL
 Where ProductionLine Is Null
Update #ParameterData 
  Set Operation = NULL
 Where UnitProcedure Is Null
Update #ParameterData 
  Set Phase = NULL
  Where Operation Is Null
Insert Into #ParameterData
SELECT 	 ProductionLine = @@ProductionLineName,
 	  	 UnitProcedure = PU.PU_Desc, 
 	  	 Operation = NULL,
 	  	 Phase = NULL,
 	  	 ParameterName = V.Test_Name,
 	  	 ParameterDescription = V.Var_Desc,
 	  	 VariableId = V.Var_Id
FROM 	 Prod_Units PU
JOIN 	 Variables V ON PU.PU_Id = V.PU_Id
Where 	  	 PU.PL_Id = @@ProductionLineId
 	  	 AND PU.Extended_Info = 'BATCH:'
 	  	 AND V.Event_Type = 1 
 	  	 AND V.Input_Tag LIKE 'BATCH:%'
Select ProductionLine, UnitProcedure, Operation, Phase,  ParameterDescription as ParameterName , VariableId 
  from #ParameterData
  --WHERE ProductionLine is not Null AND UnitProcedure is not Null AND Operation IS NOT null AND Phase is NOT NULL and ParameterName is NOT null
  Order By ProductionLine, UnitProcedure, Operation, Phase
Drop Table #ParameterData
