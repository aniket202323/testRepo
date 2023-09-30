Create Procedure dbo.spMSITopic_UnitInventoryDetails
@value int OUTPUT,
@Key int,
@Topic int
as
Declare @Inventory 	 Float,
 	 @Quality 	  	 VarChar(25),
 	 @StartTime 	  	 Datetime,
 	 @Endtime 	  	 DateTime,
 	 @Good 	  	  	 Float,
 	 @Bad 	  	  	 Float,
 	 @Total  	  	  	 Float,
 	 @Label 	  	  	 VarChar(50)
Select @EndTime =   	 Case @Topic
 	  	  	   When 101 Then  dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	   When 103 Then  dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	   When 105 Then  dbo.fnServer_CmnGetDate(getUTCdate())
 	  	  	 End
Select 	 @StartTime = Case @Topic
 	  	  	   When 101 Then  Convert(DateTime,(select convert(varchar(10),DatePart(mm,dbo.fnServer_CmnGetDate(getUTCdate()))) + '/'+  convert(varchar(10),DatePart(dd,dbo.fnServer_CmnGetDate(getUTCdate())))+'/' +   convert(varchar(10),datepart(yy,dbo.fnServer_CmnGetDate(getUTCdate())))))
 	  	  	   When 103 Then  DateAdd(hh,-12,@EndTime)
 	  	  	   When 105 Then  DateAdd(hh,-24,@EndTime)
 	  	  	 End
Select @Good = (Select Count(*) From Events e WITH(index (Event_By_PU_And_Status))
 	  	  	  	 Join Production_Status p on e.Event_Status  = p.ProdStatus_Id and p.Status_Valid_For_Input = 1  and p.Count_For_Inventory = 1
   	  	  	  	 Where pu_Id = @Key and TimeStamp between '1/1/1970' and @EndTime)
Select @Bad = (Select Count(*) From Events e WITH (index(Event_By_PU_And_Status))
 	  	  	  	 Join Production_Status p on e.Event_Status  = p.ProdStatus_Id and p.Status_Valid_For_Input = 0 and p.Count_For_Inventory = 1
   	  	  	  	 Where pu_Id = @Key and TimeStamp between '1/1/1970' and @EndTime)
Select @Label = Event_Subtype_Desc
    From event_Configuration e
    Join event_subtypes es on es.Event_Subtype_Id = e.Event_Subtype_Id
    Where e.pu_Id = @Key and e.ET_Id =  1
If @Label is null or ltrim(rtrim(@Label)) = ''
  Select @Label = 'Events'
Select @Inventory = @Good + @Bad
select  	 Type 	  	  	 =4, 
 	 Topic 	  	  	 =@Topic,
 	 KeyValue 	  	 =@Key,
 	 StartTime 	  	 = Convert(VarChar(25),@StartTime,120),
 	 EndTime  	  	 = Convert(VarChar(25),@EndTime,120),
 	 Inventory 	  	 = Convert(Varchar(25),@Inventory) + ' ' + @Label, 
 	 Quality 	  	  	 =  case When @Inventory = 0.0 Then 'n/a' 
 	  	  	  	              Else convert(Varchar(10),Cast(Round(@Good/@Inventory * 100,0) as decimal (5,1))) + '%'
 	  	  	  	      End,
 	 Pu_Id 	  	  	 = @Key
