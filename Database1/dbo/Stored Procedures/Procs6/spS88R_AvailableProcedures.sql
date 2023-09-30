CREATE procedure [dbo].[spS88R_AvailableProcedures]
--Declare
@AnalysisId int
AS
--TODO: Could Filter The Batch Query By Name To Only Those Units With Batch Models Configured, In Same Department?
/******************************************************
-- For Testing
--*******************************************************
Select @AnalysisId = 2
--*******************************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
--**********************************************
Create Table #ProcedureData (
 ProcedureType nvarchar(100),
 ProcedureName nVarChar(100) NULL,
 UnitProcedure nVarChar(100) NULL, 
 Operation nVarChar(100) NULL, 
 Phase nVarChar(100) NULL, 
 ProcedureStartTime datetime NULL,
)
Declare @BatchId int
Declare @BatchName nVarChar(50)
-- Get Reference Batch Number
Select @BatchId = min(Batch_Event_Id)
  From Batch_Results_Selections
  Where Analysis_id = @AnalysisId and
        Selected > 0
Print 'Batch Id ' + CAST(@BatchId as nvarchar(10))
If @BatchId Is Null
  Begin
    RaisError ('SP: Reference Batch Cannot Be Found',16,1)
    Return
  End
Select @BatchName = event_num
  From Events 
  Where Event_id = @BatchId
Declare @@Unit int
Declare @@BatchId int
Declare @@Timestamp datetime
Declare @@StartTime datetime
Declare @UnitName nVarChar(100)
Declare @ProcedureUnit int
Declare @@UnitProcedureId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@OperationId int
Declare @@OperationName nVarChar(100)
-- Batch will likely span multiple units, we need to cursor through each unit 
-- and build up the appropriate information
Declare BatchCursor Insensitive Cursor 
  For Select PU_Id, Event_Id, Timestamp,Start_Time From Events Where Event_Num = @BatchName Order By Start_Time
  For Read Only
Open BatchCursor
Fetch Next From BatchCursor Into @@Unit, @@BatchId, @@Timestamp,@@StartTime
While @@Fetch_Status = 0
  Begin
    -- Cursor through procedure genealogy starting with Unit Procedure
    Declare UnitProcedureCursor Insensitive Cursor 
      for Select e.Event_Id, PU.PU_Desc
 	 From Events E
 	   Join Event_Components ec ON ec.Event_Id = E.Event_Id
 	   Join Prod_Units PU on PU.PU_Id = e.PU_Id
 	 Where ec.Source_Event_Id = @@BatchId
      For Read Only
    Open UnitProcedureCursor
    Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
    While @@Fetch_Status = 0
      Begin
 	 Print @@UnitProcedureName
        -- Insert Unit Procedure Record Into Procedure Summary        
        Insert Into #ProcedureData 
          Select ProcedureType = dbo.fnTranslate(@LangId, 34904, 'Unit Procedure'),
                 ProcedureName = @@UnitProcedureName,
                 UnitProcedure = @@UnitProcedureName,
                 Operation = Null,
                 Phase = Null,
                 ProcedureStartTime = e.start_time
            From Events e
            Where Event_Id = @@UnitProcedureId   
        -- Cursor Through Each Operation Contained In This Unit Procedure
        Declare OperationCursor Insensitive Cursor 
 	   For Select UDE_ID, Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc))
 	  	 From User_defined_Events UDE
 	  	 Where Event_Id = @@UnitProcedureId
          For Read Only
        Open OperationCursor
        Fetch Next From OperationCursor Into @@OperationId, @@OperationName
        While @@Fetch_Status = 0
          Begin
            -- Insert Operation Record Into Procedure Summary        
            Insert Into #ProcedureData 
              Select ProcedureType = dbo.fnTranslate(@LangId, 34905, 'Operation'),
                     ProcedureName = @@OperationName,
                     UnitProcedure = @@UnitProcedureName,
                     Operation = @@OperationName,
                     Phase = Null,
                     ProcedureStartTime = start_time
                From User_Defined_Events 
                Where UDE_Id = @@OperationId   
            -- Insert Phase Records Into Procedure Summary        
            Insert Into #ProcedureData 
              Select ProcedureType = dbo.fnTranslate(@LangId, 34906, 'Phase'),
                     ProcedureName = Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc)),
                     UnitProcedure = @@UnitProcedureName,
                     Operation = @@OperationName,
                     Phase = Substring(UDE_Desc, CharIndex(':',UDE_Desc)+1, Len(UDE_Desc) - CharIndex(':',UDE_Desc)),
                     ProcedureStartTime = start_time
                From User_Defined_Events
                Where Parent_UDE_Id = @@OperationId   
            Fetch Next From OperationCursor Into @@OperationId, @@OperationName
          End
        Close OperationCursor
        Deallocate OperationCursor  
        Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
      End
    Close UnitProcedureCursor
    Deallocate UnitProcedureCursor  
    Fetch Next From BatchCursor Into @@Unit, @@BatchId, @@Timestamp,@@StartTime
  End
Close BatchCursor
Deallocate BatchCursor  
Select UnitProcedure, Operation, Phase 
  from #ProcedureData
  WHERE UnitProcedure is NOT null and Operation is NOT null and Phase is NOT null
  Order By UnitProcedure, Operation, Phase, ProcedureStartTime
Drop Table #ProcedureData
