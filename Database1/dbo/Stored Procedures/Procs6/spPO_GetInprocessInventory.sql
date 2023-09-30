Create Procedure dbo.spPO_GetInprocessInventory
 	 @PU_Id int
  AS
set nocount ON
DECLARE @MasterPU_Id 	 Int,
 	     @EventId 	  	 Int,
 	     @TimeStamp  	  	 DateTime,
 	  	 @App_Prod 	  	 Int,
 	  	 @ATitle 	  	  	 nvarchar(50),
 	  	 @XTitle 	  	  	 nvarchar(50),
 	  	 @YTitle 	  	  	 nvarchar(50),
 	  	 @ZTitle 	  	  	 nvarchar(50),
 	  	 @AEnabled 	  	 TinyInt,
 	  	 @YEnabled 	  	 TinyInt,
 	  	 @ZEnabled 	  	 TinyInt,
 	  	 @SqlStmt 	  	 VarChar(7000),
 	  	 @Now 	  	  	 DateTime
Select @Now = dbo.fnServer_CmnGetDate(GetUTCdate())
Select  	 @XTitle = Coalesce(Dimension_X_Name,'<none>'),
 	 @ATitle 	 = Coalesce(Dimension_A_Name,'<none>'),
 	 @YTitle = Coalesce(Dimension_Y_Name,'<none>'),
 	 @ZTitle = Coalesce(Dimension_Z_Name,'<none>'),
 	 @AEnabled = Coalesce(Dimension_A_Enabled,0),
 	 @YEnabled = Coalesce(Dimension_Y_Enabled,0),
 	 @ZEnabled = Coalesce(Dimension_Z_Enabled,0)
  From event_configuration ec  
  Left Join Event_Subtypes es on es.Event_Subtype_Id = ec.Event_Subtype_Id
 Where ec.Pu_Id = @PU_Id and ec.et_id = 1 and ec.Is_Active = 1
If ltrim(rtrim(@ATitle)) = '' or ltrim(rtrim(@ATitle)) is null 
   Select @ATitle = '<none>'
If ltrim(rtrim(@YTitle)) = '' or ltrim(rtrim(@YTitle)) is null 
   Select @YTitle = '<none>'
If ltrim(rtrim(@ZTitle)) = '' or ltrim(rtrim(@ZTitle)) is null 
   Select @ZTitle = '<none>'
If ltrim(rtrim(@XTitle)) = '' or ltrim(rtrim(@XTitle)) is null 
   Select @XTitle = '<none>'
Create Table #Events(  	 Event_Id int,
 	  	  	 Event_num nvarchar(25),
 	  	  	 ProdStatus_Desc nvarchar(25) Null,
 	  	  	 Timestamp  Datetime,
 	  	  	 Applied_Product 	 Int Null,
 	  	  	 Icon_Id 	 Int Null)
  SELECT @MasterPU_Id  = coalesce((select master_unit from prod_units where pu_id = @PU_Id),@PU_Id)
  --
Insert into #Events(Event_Id,Event_num,Timestamp,ProdStatus_Desc,Applied_Product,Icon_Id)
  SELECT  Event_Id,Event_num,Timestamp,ProdStatus_Desc,Applied_Product,p.Icon_Id
    FROM Events e
    Join  Production_Status p on p.ProdStatus_Id = e.event_status  and p.Count_For_Inventory = 1 and p.Status_Valid_For_Input = 1
   where  e.pu_id  = @MasterPU_Id and timestamp between  '1/1/1970'  and  @Now
    order by Timestamp desc
Execute ( 'Declare EventCursor Cursor ' +
  'For Select Event_Id,TimeStamp,Applied_Product from #Events ' +
  'For Update')
  Open  EventCursor   
 EventCursorLoop1:
  Fetch Next From  EventCursor  Into @EventId,@TimeStamp,@App_Prod
  If (@@Fetch_Status = 0)
    Begin
 	  	 If @App_Prod is null
 	  	   Begin
 	  	  	 Update #Events set Applied_Product =  (Select Prod_Id 
             From Production_Starts s
 	          Where s.Start_Time < @TimeStamp and  (s.End_time >= @TimeStamp or  s.End_time is null) and s.pu_id = @MasterPU_Id)
  	         where current of EventCursor
         End
          Goto EventCursorLoop1
    End
Close  EventCursor 
Deallocate  EventCursor
DECLARE  @TT Table(TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values ('Date / Time')
select * from @TT
Select @SqlStmt = 'Select [Key] = e.Event_Id,Icon = Icon_Id,[Event Number] = e.Event_num,Status = ProdStatus_Desc,[Date / Time] = e.Timestamp,  ' 
Select @SqlStmt = @SqlStmt + '[Product Code] =Prod_Code,Age = DateDiff(mi,e.timestamp,dbo.fnServer_CmnGetDate(GetUTCdate())),'
Select @SqlStmt = @SqlStmt + '[' + @XTitle + '] = ed.Initial_Dimension_X,'
If  @YEnabled = 1
  Select @SqlStmt = @SqlStmt + '[' + @YTitle + '] = ed.Initial_Dimension_Y,' 
If  @ZEnabled = 1
  Select @SqlStmt = @SqlStmt + '[' + @ZTitle + '] = ed.Initial_Dimension_Z,'  
If  @AEnabled = 1
  Select @SqlStmt = @SqlStmt + '[' + @ATitle + '] = ed.Initial_Dimension_A,'
Select  @SqlStmt = substring(@SqlStmt,1,len(@SqlStmt) - 1) + ' '
Select @SqlStmt = @SqlStmt + ' From  #Events e Left Join event_Details ed on ed.event_Id = e.Event_Id '
Select @SqlStmt = @SqlStmt + 'Left Join Products p on p.Prod_Id = e.Applied_Product Order by [Date / Time]  '
Execute (@SqlStmt)
Drop table #Events
set nocount off
