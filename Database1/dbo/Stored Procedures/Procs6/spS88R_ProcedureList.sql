--exec spS88R_ProcedureList 1,''
CREATE procedure [dbo].[spS88R_ProcedureList]
@Events nVarChar(255),
@InTimeZone nVarChar(200)=NULL
AS
/******************************************************
-- For Testing
--*******************************************************
Select @Events = '31125,31229,31285'
--*******************************************************/
--**********************************************
-- Translations Setup & Common Prompt Lookup
--**********************************************
-- Retreive the Language Id of the current user
Declare @LangId INT
EXEC spWA_GetCurrentUserInfo @LangId = @LangId OUTPUT
Declare @sUnitProcedure nVarChar(100)
Set @sUnitProcedure = dbo.fnTranslate(@LangId, 34904, 'Unit Procedure')
--**********************************************
Create Table #ProcedureList (
  Name nVarChar(255),
  Type nVarChar(50),
  TypeId int,
  Parent nVarChar(255) NULL,
  StartTime datetime,
  EndTime datetime,
  Status nVarChar(50),
  Color int,
  BaseName nVarChar(255)
)
Create Table #MasterList (
  Name nVarChar(255),
  Type nVarChar(50),
  TypeId int,
  Parent nVarChar(255) NULL,
  StartTime datetime,
 	 BaseName nVarChar(255)
)
Declare @SQL nVarChar(3000)
Create Table #Events (
  EventId int,
  EventNumber nVarChar(100),
  EventStatus int,
  Unit int,
  StartTime datetime,
  EndTime datetime
)
declare @TempEvents nVarChar(255)
set @TempEvents = @Events
-- Create a table to maintain the order of appearance of the event_ids as in input @Events
Create Table #TempEvents (
  orderId int IDENTITY(1,1),
  Event_Id int)
declare @pos int
declare @piece nVarChar(500)
-- Need to tack a delimiter onto the end of the input string if one doesn't exist
if right(rtrim(@TempEvents),1) <> ','
 set @TempEvents = @TempEvents  + ','
set @pos =  patindex('%,%' , @TempEvents)
while @pos <> 0 
 begin
 	 set @piece = left(@TempEvents, @pos - 1)
 -- You have a piece of data, so insert it, print it, do whatever you want to with it.
 	 Select @SQL = 'Insert into #TempEvents values (' + @piece + ')'
 	  	 Exec (@SQL)
 	 set @TempEvents = stuff(@TempEvents, 1, @pos, '')
 	 set @pos =  patindex('%,%' , @TempEvents)
 end
Select @SQL = 'Select eve.Event_Id, Event_Num, Event_Status, PU_Id, coalesce(Start_Time, Timestamp), Timestamp 
From Events eve, #TempEvents temp
Where eve.Event_Id = temp.Event_Id 
and eve.Event_Id in (' + @Events + ') Order by temp.orderId '
--Select @SQL = 'Select Event_Id, Event_Num, Event_Status, PU_Id, coalesce(Start_Time, Timestamp), Timestamp From Events Where Event_Id in (' + @Events + ')'
Insert into #Events
  Exec (@SQL)
Drop Table #TempEvents
Declare @@EventId int
Declare @@Unit int
Declare @@EventNumber nVarChar(100)
Declare @@StartTime datetime
Declare @@EndTime datetime
Declare @@EventStatus int
Declare @ProcedureUnit int
Declare @@UnitProcedureId int
Declare @@UnitProcedureName nVarChar(100)
Declare @@OperationId int
Declare @@OperationName nVarChar(100)
Declare Batch_Cursor Insensitive Cursor 
  For Select EventId, EventNumber, Unit, StartTime, EndTime, EventStatus From #Events
  For Read Only
Open Batch_Cursor
Fetch Next From Batch_Cursor Into @@EventId, @@EventNumber, @@Unit, @@StartTime, @@EndTime, @@EventStatus
While @@Fetch_Status = 0
  Begin
    Truncate Table #ProcedureList
    -- Insert The Overall Batch Procedure Record
    Insert Into #ProcedureList (Name,Type,TypeId, Parent,StartTime,EndTime,Status,Color,BaseName)
      Select @@EventNumber, 'Batch', 0, null, @@StartTime, @@EndTime, ProdStatus_Desc, 
             Case 
               When Status_Valid_For_Input > 0 Then 0
               Else 2 
             End, ''
        From Production_Status
        Where ProdStatus_Id = @@EventStatus
    -- Cursor through procedure genealogy starting with Unit Procedure
    Declare UnitProcedureCursor Insensitive Cursor 
      For Select e.Event_Id, PU.PU_Desc
            From Event_Components ec 
            Join Events e on e.event_id = ec.event_id 
 	  	  	  	  	  	 Join Prod_units PU on PU.PU_Id = e.PU_Id
            Where ec.Source_Event_Id = @@EventId  
      For Read Only
    Open UnitProcedureCursor
    Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
    While @@Fetch_Status = 0
      Begin
        -- Insert Unit Procedure Record Into Procedure Summary        
        Insert Into #ProcedureList 
          Select Name = @@UnitProcedureName,
                 Type = @sUnitProcedure,
   	  	  	  	  	  	  	  TypeId = 1,
                 Parent = @@EventNumber,
                 StartTime = e.start_time,
                 EndTime = e.timestamp,
                 Status = psd.ProdStatus_Desc,
 	  	              Color = Case 
 	  	                When psd.Status_Valid_For_Input > 0 Then 0
 	  	                Else 2 
 	  	              End,
 	  	  	  	  BaseName = Replace(@@UnitProcedureName, @@EventNumber + ':', '')
            From Events e
            Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
            Where Event_Id = @@UnitProcedureId   
 	  	  	  	 Declare OperationCursor Insensitive Cursor 
          For Select UDE_Id, UDE_Desc
                From User_Defined_Events
                Where Event_Id = @@UnitProcedureId  
          For Read Only
        Open OperationCursor
        Fetch Next From OperationCursor Into @@OperationId, @@OperationName
        While @@Fetch_Status = 0
          Begin
            -- Insert Operation Record Into Procedure Summary        
 	  	         Insert Into #ProcedureList 
 	  	           Select Name = @@OperationName,
 	  	                  Type = dbo.fnTranslate(@LangId, 34905, 'Operation'),
   	  	  	  	  	  	  	   	  	  TypeId = 2,
 	  	                  Parent = @@UnitProcedureName,
 	  	                  StartTime = UDE.start_time,
 	  	                  EndTime = EndTimeData.Result,
 	  	                  Status = psd.ProdStatus_Desc,
 	  	  	  	              Color = Case 
 	  	  	  	                When psd.Status_Valid_For_Input > 0 Then 0
 	  	  	  	                Else 2 
 	  	  	  	              End,
 	  	  	  	  	  	   BaseName = Replace(@@OperationName, @@EventNumber + ':', '')
 	  	             From User_Defined_Events UDE
 	  	             Join Variables_base EndTimeDataVariable ON EndTimeDataVariable.Var_Desc = '<OperationTimestamp>' and UDE.PU_Id = EndTimeDataVariable.PU_Id
 	  	             Join Tests EndTimeData ON EndTimeData.Var_Id = EndTimeDataVariable.Var_Id and EndTimeData.Result_On = UDE.End_Time
 	  	  	  	  	  	  	  	 Join Events UnitProcedure on UnitProcedure.Event_id = @@UnitProcedureId
 	  	             Join Production_Status psd on psd.ProdStatus_Id = UnitProcedure.Event_Status 
                Where UDE_Id = @@OperationId   
            -- Insert Phase Records Into Procedure Summary        
 	  	         Insert Into #ProcedureList 
 	  	           Select Name = UDE.UDE_Desc,
 	  	                  Type = dbo.fnTranslate(@LangId, 34906, 'Phase'),
   	  	  	  	  	  	  	   	  	  TypeId = 3,
 	  	                  Parent = @@OperationName,
 	  	                  StartTime = UDE.start_time,
 	  	                  EndTime = EndTimeData.Result,
 	  	                  Status = psd.ProdStatus_Desc,
 	  	  	  	              Color = Case 
 	  	  	  	                When psd.Status_Valid_For_Input > 0 Then 0
 	  	  	  	                Else 2 
 	  	  	  	              End,
 	  	  	  	  	  	  	 BaseName = Replace(UDE.UDE_Desc, @@EventNumber + ':', '')
 	  	  	  	  	  	  	  	 From User_Defined_Events UDE
 	  	  	  	  	  	  	  	  	 Join Events E on E.Event_ID = @@UnitProcedureId
 	  	  	  	  	  	  	  	  	 Join Variables_base EndTimeDataVariable ON EndTimeDataVariable.Var_Desc = '<PhaseTimestamp>' and UDE.PU_Id = EndTimeDataVariable.PU_Id
 	  	               Join Tests EndTimeData ON EndTimeData.Var_Id = EndTimeDataVariable.Var_Id and EndTimeData.Result_On = UDE.End_Time
 	                 Join Production_Status psd on psd.ProdStatus_Id = e.Event_Status 
 	  	  	  	  	  	  	  	 Where UDE.Parent_UDE_Id = @@OperationId
            Fetch Next From OperationCursor Into @@OperationId, @@OperationName
          End
        Close OperationCursor
        Deallocate OperationCursor  
        Fetch Next From UnitProcedureCursor Into @@UnitProcedureId, @@UnitProcedureName
      End
    Close UnitProcedureCursor
    Deallocate UnitProcedureCursor  
    update #ProcedureList set StartTime = [dbo].[fnServer_CmnConvertFromDbTime] (StartTime,@InTimeZone),
 	   EndTime= [dbo].[fnServer_CmnConvertFromDbTime] (EndTime,@InTimeZone)  
 	 Select * From #ProcedureList Order By StartTime ASC
    Insert Into #MasterList
      Select Name, Type, TypeId,
             Parent = Parent,
             StartTime,
 	  	  	  	 BaseName
        From #ProcedureList
 	  	 Fetch Next From Batch_Cursor Into @@EventId, @@EventNumber, @@Unit, @@StartTime, @@EndTime, @@EventStatus
  End
Close Batch_Cursor
Deallocate Batch_Cursor
Select Name, Type, TypeId, Parent, min(StartTime), BaseName
  From #MasterList
  Group By Name, Type, TypeId, Parent, BaseName
  Order By min(StartTime)
Drop Table #MasterList
Drop Table #Events
Drop Table #ProcedureList
