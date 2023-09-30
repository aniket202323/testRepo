Create Procedure dbo.spGE_SiblingEventComponentData
  @Component_Id int
 AS
Declare @Event_Id Int
Declare @Source_Id Int
Create Table #ColumnFormats (
  TimeColumns nvarchar(50)
)
Insert into #ColumnFormats (TimeColumns) Values ('Time')
Select TimeColumns From #ColumnFormats
Drop Table #ColumnFormats
Select @Event_Id = Event_Id,@Source_Id = Source_Event_Id from Event_Components where Component_Id = @Component_Id
Select [Key] = Component_Id ,[Source] = e1.event_Num,[Destination] = e.event_Num,[Prod Unit] = PU_Desc,[Time] = ec.TimeStamp
 	 From Event_Components ec
 	 Join Events e on e.event_Id = ec.Event_Id
 	 Join Events e1 on e1.event_Id = ec.Source_Event_Id
 	 Join Prod_Units pu on pu.PU_Id = e.PU_Id
 	 Where  Source_Event_Id = @Source_Id and ec.Event_Id = @Event_Id
Order by ec.Source_Event_Id,ec.TimeStamp
