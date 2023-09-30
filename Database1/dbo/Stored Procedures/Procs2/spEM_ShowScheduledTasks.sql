Create Procedure dbo.spEM_ShowScheduledTasks
 AS
DECLARE  @TT Table(TIMECOLUMNS nvarchar(50))
Insert Into @TT  (TIMECOLUMNS) Values ('Actual Time')
Insert Into @TT  (TIMECOLUMNS) Values ('WorkStartedTime')
select * from @TT
Select [Service] = SubString(b.Owner,1,20), 
 	    [Task] = b.TaskDesc,
 	    [Unit] = Coalesce(pu.PU_Desc,''),
 	    [Actual Time] = a.Timestamp,
 	    [Misc] = a.Misc,
       [Work Started] = case When a.WorkStarted = 1 Then 'True' 
 	  	  	  	  	  	 Else 'False'
 	  	  	  	  	  	 End, 
       WorkStartedTime = Convert(nvarchar(20),a.WorkStartedTime),
 	    [PU Id] = a.PU_Id,
 	    [Actual Id] = a.ActualId 	     
  From PendingTasks a
  Join Tasks b on b.TaskId = a.TaskId
  Left Join Prod_Units pu on pu.PU_Id = a.PU_Id
  Order by b.Owner,b.TaskDesc,a.WorkStarted,a.ActualId
