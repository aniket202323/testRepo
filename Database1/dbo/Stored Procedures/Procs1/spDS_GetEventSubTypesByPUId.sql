Create Procedure dbo.spDS_GetEventSubTypesByPUId
 @PUId int
AS
 Declare  @NoEventSubType nVarChar(25)
 Select @NoEventSubType = '<None>'
----------------------------------------------------
-- Event SubTypes
----------------------------------------------------
 Create Table #EventSubTypes (
  EventSubTypeId int,
  EventSubTypeDesc nVarChar(50) NULL)
 Insert Into #EventSubTypes
  Select ev.Event_Subtype_Id, ev.Event_SubType_Desc
   From Event_Subtypes ev
    Join Event_Configuration ec on ev.Event_Subtype_Id = ec.Event_Subtype_Id
    Where ev.ET_Id = 14 and ec.PU_Id = @PUId
 Insert Into #EventSubTypes values(0, @NoEventSubType)
 Select * From #EventSubTypes Order by EventSubTypeDesc 
 Drop Table #EventSubTypes
