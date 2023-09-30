CREATE procedure [dbo].[sps88R_GetBatchListFromIds_Bak_177]
@Ids varchar(4000),
@InTimeZone nVarChar(200)=NULL
AS
DECLARE @SQL VarChar(6000)
/*
exec spS88R_BatchList @NameMask = NULL, @Units = N'52', @Products = NULL, @Statuses = NULL, @StartTime = 'Jan  1 2001 12:00:00:000AM', @EndTime = 'Dec 30 2003  8:40:42:000AM', @CrewName = N'', @ShiftName = N'', @minSize = NULL, @MaxSize = NULL
sps88R_GetBatchListFromIds '30690'
*/
-- Go Get The Events
Create Table #FinalEventList (
  EventId int,
  ProductId int,
  StatusId int,
  StartTime datetime,
  EndTime datetime,
  CrewName nVarChar(25) NULL,
  ShiftName nVarChar(25) NULL,
  OtherUnit int NULL
)
Select @SQL = ' 	 SELECT Event_Id,
 	  	        Case When e.Applied_Product Is Null Then ps.Prod_Id Else e.Applied_Product End, 
                       Case when e.Start_Time Is Null Then e.Timestamp Else e.Start_Time End,
                       e.Timestamp,
                       e.Event_Status 
 	  	 FROM Events e 
 	  	 Join Production_Starts ps on ps.pu_id = E.PU_Id and ps.Start_Time <= e.Start_Time and (ps.End_Time > e.Start_Time or ps.End_Time Is Null) 
 	  	 WHERE Event_Id IN (' + @Ids + ')'
Insert Into #FinalEventList (EventId, ProductId, StartTime, EndTime, StatusId) 
EXEC (@SQL)
Update #FinalEventList 
      Set #FinalEventList.CrewName = (
        Select cs.Crew_Desc 
         From Crew_schedule cs 
 	     JOIN Events e ON e.Event_id = #FinalEventList.EventId
         Where cs.PU_Id = e.PU_ID and 
               cs.Start_Time <= #FinalEventList.StartTime and 
               cs.End_Time > #FinalEventList.StartTime)
  --TODO: Join In Department
Select Id = e.event_id, BatchName = e.Event_Num, Product = p.Prod_Code, Status = psd.ProdStatus_Desc,
 	 Conformance = Case
 	  	 When e.Conformance = 4 Then 'Entry'
 	  	 When e.Conformance = 3 Then 'Reject'
 	  	 When e.Conformance = 2 Then 'Warning'
 	  	 When e.Conformance = 1 Then 'User'
 	  	 Else 'Good' END, 
        DepartmentName = pl.pl_desc, LineNsme = pl.PL_Desc, UnitName = pu.PU_Desc,   
 	 StartTime = [dbo].[fnServer_CmnConvertFromDbTime] (l.StartTime,@InTimeZone), 
 	 EndTime =[dbo].[fnServer_CmnConvertFromDbTime] (l.EndTime,@InTimeZone), 
 	  CrewName = l.Crewname, ShiftName = l.ShiftName,
        BatchSize = d.initial_dimension_x,
 	 Comment = c.Comment_Text, UnitId = pu.PU_ID
     From #FinalEventList l
 	  Join Events e on e.Event_id = l.EventId
 	  Join Production_Status psd on psd.ProdStatus_id = e.Event_Status
 	  Join Products p on p.Prod_id = l.ProductId
 	  Join Prod_Units pu on pu.PU_Id = e.PU_id 
 	  Join Prod_Lines pl on pl.PL_Id = pu.PL_Id
         left outer Join Event_Details d on d.event_id = e.event_id 
 	  left outer join comments c on c.comment_id = e.comment_id
     order by l.StartTime ASC
Drop Table #FinalEventList
return
