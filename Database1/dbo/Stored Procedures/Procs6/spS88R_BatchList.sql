CREATE procedure [dbo].[spS88R_BatchList]
--declare
@NameMask nvarchar(100),
@Units nvarchar(1000),
@Products nvarchar(1000),
@Statuses nvarchar(1000), 
@StartTime datetime,
@EndTime datetime, 
@CrewName nvarchar(25),
@ShiftName nvarchar(25),
@MinSize real,
@MaxSize real,
@InTimeZone nvarchar(200)=NULL
AS
-- sps88r_BatchList null,null,null,null,'1-1-2000', '1-1-2006','','',null,null
Declare @SQL nvarchar(3000)
Declare @UnitId int
Declare @UnitCount int
 	 select @StartTime=[dbo].[fnServer_CmnConvertToDbTime] (@StartTime,@InTimeZone)
 	 Select @EndTime=[dbo].[fnServer_CmnConvertToDbTime] (@EndTime,@InTimeZone)
 Create Table #UnitList (
  UnitId int
)
Select @SQL = 'Select PU_Id From Prod_Units Where PU_Id in (' + @Units + ')'
Insert Into #UnitList
  Exec (@SQL)
Select @Unitcount = count(UnitId) From #UnitList
If @UnitCount = 0 
  Begin
    Print 'No Units Selected, Selecting All Units'
    Insert Into #UnitList
    Select pu.PU_ID
    From Prod_Units pu
    WHERE pu.PU_Desc like '<%>' and PU.PU_Id <> 0
  End
Select @Unitcount = count(UnitId) From #UnitList
If @UnitCount = 0 
  Begin
    RaisError ('No Units Available With A Batch Model Configured',16,1)
    Return
  End
-- Go Get The Events
Create Table #FinalEventList (
  EventId int,
  ProductId int,
  StatusId int,
  StartTime datetime,
  EndTime datetime,
  CrewName nvarchar(25) NULL,
  ShiftName nvarchar(25) NULL,
  OtherUnit int NULL,
  DimensionX Float Null,
  PUId 	  	 Int,
  CommentId Int,
  EventNum 	 nvarchar(100),
  Conf 	  	 Int
)
-- Cursor Through Each Unit And Gather Events
Declare UnitCursor Insensitive Cursor 
 	 For Select UnitId From #UnitList
 	 For Read Only
  Open UnitCursor
  Fetch Next From UnitCursor Into @UnitId
    While @@Fetch_Status = 0
      Begin
 	 Insert Into #FinalEventList (EventId, ProductId, StartTime, EndTime, StatusId,DimensionX,PUId,CommentId,EventNum,conf)
 	   Select e.Event_Id, 
   	  	  Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End,
                 Case when e.Start_Time Is Null Then e.Timestamp Else e.Start_Time End,
                 e.Timestamp,
                 e.Event_Status,ed.initial_dimension_x,@UnitId,e.Comment_Id,e.Event_Num,e.Conformance 
          From Events e
          Left Join Event_Details ed On ed.Event_Id = e.Event_Id 
          join Production_Starts ps on ps.pu_id = @UnitId and ps.Start_Time <= e.Timestamp and (ps.End_Time > e.Timestamp or ps.End_Time Is Null) 
          Where e.PU_Id = @UnitId and
                e.Timestamp between @StartTime and @EndTime              
        -- Purge Batches With Wrong Product
 	  	     If @Products Is Not Null
 	  	       Begin
 	  	         Select @SQL = 'Delete From #FinalEventList Where ProductId Not in (' + @Products + ')'
 	  	         Exec (@SQL)        
 	  	       End
 	  	     -- Purge Batches With Wrong Status
 	  	     If @Statuses Is Not Null
 	  	       Begin
 	  	         Select @SQL = 'Delete From #FinalEventList Where StatusId Not in (' + @Statuses + ')'
 	  	         Exec (@SQL)        
 	  	       End
        Fetch Next From UnitCursor Into @UnitId
 	  	  	 End
Close UnitCursor
Deallocate UnitCursor
 -- Join In Crew Information
Update #FinalEventList  Set CrewName = cs.Crew_Desc,Shiftname = cs.Shift_Desc
From #FinalEventList a
JOIN Crew_schedule cs ON cs.PU_Id = a.PUId  
WHERE cs.Start_Time <= a.StartTime and cs.End_Time > a.StartTime
If @CrewName is Not Null And @CrewName <> ''
  Delete From #FinalEventList Where CrewName <> @CrewName
If @ShiftName Is Not Null And @ShiftName <> ''
  Delete From #FinalEventList Where ShiftName <> @ShiftName
If @MinSize Is Not Null
 	 DELETE FROM #FinalEventList WHERE DimensionX  < @MinSize
If @MaxSize Is Not Null
 	 DELETE FROM #FinalEventList WHERE DimensionX  > @MaxSize
 	 
Select Id = eventid, BatchName = EventNum, Product = p.Prod_Code, Status = psd.ProdStatus_Desc,
  Conformance = Case
    When conf = 4 Then 'Entry'
    When conf = 3 Then 'Reject'
    When conf = 2 Then 'Warning'
    When conf = 1 Then 'User'
    Else 'NA'                        
  End, 
  DepartmentName = dp.Dept_Desc, LineName = pl.PL_Desc, UnitName = pu.PU_Desc,   
  StartTime =   [dbo].[fnServer_CmnConvertFromDbTime] (l.StartTime,@InTimeZone), 
  EndTime =  [dbo].[fnServer_CmnConvertFromDbTime] (l.EndTime,@InTimeZone),
  CrewName = l.Crewname, ShiftName = l.ShiftName,
  BatchSize = DimensionX,
  Comment = c.Comment_Text, UnitId = pu.PU_ID, ProductId = l.ProductId
From #FinalEventList l
  Join Production_Status psd on psd.ProdStatus_id =l.StatusId 
  Join Products p on p.Prod_id = l.ProductId
  Join Prod_Units pu on pu.PU_Id = l.puid
  Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
  Join Departments dp on dp.Dept_Id = pl.Dept_Id
  left outer join comments c on c.comment_id = l.CommentId
order by l.StartTime ASC,eventid
Drop Table #UnitList
Drop Table #FinalEventList
