Create Procedure dbo.spGE_SiblingEventData
  @Event_Id int,
  @IsParent int
 AS
Create Table #ColumnFormats (
  TimeColumns nvarchar(50)
)
Insert into #ColumnFormats (TimeColumns) Values ('Time')
Select TimeColumns From #ColumnFormats
Drop Table #ColumnFormats
If @IsParent = 1
 Select [Key] = eC.Component_Id,[Event Number] = e.event_Num,[Prod Unit] = PU_Desc,[Time] = ec.TimeStamp,[Dim X] = ec.Dimension_X,[Dim Y] = ec.Dimension_Y,[Dim Z] = ec.Dimension_Z,[Dim A] = ec.Dimension_A,[Event Id] = e.Event_Id
 	 From Event_Components ec
 	 Join Events e on e.event_Id = ec.Source_Event_Id
 	 Join Prod_Units pu on pu.PU_Id = e.PU_Id
 	 Where ec.event_Id = @Event_Id
 	 Order by PU_Desc,ec.TimeStamp
else
 Select [Key] = eC.Component_Id,[Event Number] = e.event_Num,[Prod Unit] = PU_Desc,[Time] = ec.TimeStamp,[Dim X] = ec.Dimension_X,[Dim Y] = ec.Dimension_Y,[Dim Z] = ec.Dimension_Z,[Dim A] = ec.Dimension_A,[Event Id] = e.Event_Id
 	 From Event_Components ec
 	 Join Events e on e.event_Id = ec.Event_Id
 	 Join Prod_Units pu on pu.PU_Id = e.PU_Id
 	 Where ec.Source_Event_Id = @Event_Id
 	 Order by PU_Desc,ec.TimeStamp
