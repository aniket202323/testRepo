Create Procedure dbo.spPO_GetQualityData
 	 @PU_Id int
  AS
DECLARE @MasterPU_Id int,
 	  	 @EventId 	      int,
 	  	 @TimeStamp   DateTime,
 	  	 @Applied_Product 	 Int,
 	  	 @Now 	  	 DateTime
Select @Now = dbo.fnServer_CmnGetDate(GetUTCdate())
Create Table #Events(  	 Event_Id int,
 	  	  	 Event_num nvarchar(25),
 	  	  	 ProdStatus_Desc nvarchar(25) Null,
 	  	  	 Timestamp  Datetime,
 	  	  	 Applied_Product Int Null,
 	  	  	 Icon_Id Int Null)
  SELECT @MasterPU_Id  = coalesce((select master_unit from prod_units where pu_id = @PU_Id),@PU_Id)
  --
Insert into #Events(Event_Id,Event_num,Timestamp,ProdStatus_Desc,Applied_Product,Icon_Id)
  SELECT  Event_Id,Event_num,Timestamp,ProdStatus_Desc,Applied_Product,Icon_Id
    FROM Events e
    Join  Production_Status p on p.ProdStatus_Id = e.event_status and p.Count_For_Inventory = 1
   where  e.pu_id  = @MasterPU_Id  and timestamp between  '01/01/1970'  and @Now
    order by Timestamp desc
Execute ( 'Declare EventCursor Cursor ' +
  'For Select Event_Id,TimeStamp,Applied_Product from #Events ' +
  'For Update')
  Open  EventCursor   
 EventCursorLoop1:
  Fetch Next From  EventCursor  Into @EventId,@TimeStamp,@Applied_Product
  If (@@Fetch_Status = 0)
    Begin
 	  	 If @Applied_Product Is Null
 	  	   update #Events set Applied_Product =
 	  	  	 (Select prod_id 
  	  	  	    From Production_Starts s
 	  	  	    Where s.Start_Time < @TimeStamp and  (s.End_time >= @TimeStamp or  s.End_time is null) and s.pu_id = @MasterPU_Id)
 	  	  	 Where current of EventCursor
        Goto EventCursorLoop1
    End
Close  EventCursor 
Deallocate  EventCursor 
DECLARE @TT Table  (TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values ('Date / Time')
select * from @TT
Select [Key] = Event_Id,
 	    Icon = Icon_Id,
 	    [Event Number] = Event_num,
 	    Status = ProdStatus_Desc,
 	    [Date / Time] = Timestamp,
 	    [Product Code] = 	 Prod_Code 
 	    From  #Events e
 	    Left Join Products p on p.Prod_Id = e.Applied_Product
Drop table #Events
