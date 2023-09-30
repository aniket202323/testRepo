CREATE PROCEDURE [dbo].[spRS_AssignASPTask]
@Engine_Id int
AS
Declare @Engine_Name varchar(50)
Declare @Schedule_Id int
Declare @Now DateTime
Set @Now = dbo.fnServer_CmnGetDate(GetUtcDate())
----------------------
-- Verify Engine Name
----------------------
Select @Engine_Name = Engine_Name
From Report_Engines
Where Engine_Id = @Engine_Id
If @Engine_Name is null
  Begin
--    print 'no such engine exists'
    return(0)
  End
--print 'you are engine ' + @Engine_Name
-- Get a scheduled report that:
-- 1) is in the queue
-- 2) has a class name of Active Server Page
-- 3) Current Time has exceeded Next_Run_Time
select @Schedule_Id = Min(rs.Schedule_Id)--, rs.Report_Id, rd.Report_Name
from report_schedule rs
Join Report_Que rq on rq.Schedule_Id = rs.Schedule_Id
Join Report_Definitions rd on rd.Report_Id = RS.Report_Id
Join Report_Types rt on rd.Report_Type_Id = rt.Report_Type_Id and rt.Class_Name = 'Active Server Page'
where Process_Id is null
and Computer_Name is null
--and next_run_time < @Now
If @Schedule_Id is null
  Begin
    --There is nothing in the Report_Que to run
--    Print 'Nothing in the report_que to run'
    Select * from Report_Schedule where 1 = 2
    return(0)
  End
Else
  Begin
--    print 'Assigning Schedule_Id ' + convert(varchar(5), @Schedule_Id)
    ---------------------
    -- Begin Transaction
    ---------------------
    Update Report_Schedule
    Set Process_Id = @Engine_Id,
        Computer_Name = @Engine_Name,
        Status = 3
        Where Schedule_Id = @Schedule_Id
 	 Delete from Report_Que where Schedule_Id = @Schedule_Id
        Select RS.Schedule_Id, RS.Report_Id, RD.Report_Name, RT.SPName
        From Report_Schedule RS
        Join Report_Definitions RD on RD.Report_Id = RS.Report_Id
 	 Join Report_Types RT on RD.Report_Type_Id = RT.Report_Type_Id
        Where RS.Schedule_Id = @Schedule_Id
    ---------------------
    -- Commit Transaction
    ---------------------
  End
