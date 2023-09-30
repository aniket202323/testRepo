  CREATE  Procedure [dbo].[spLocal_RptRunTimeASP]  
  
-- declare   
        @report_type_id as int  
  
-- set @report_type_id = 130  
As  
--------------------------------------------------------------------------------------------------  
--Create temp tables  
--------------------------------------------------------------------------------------------------  
Create Table #Temp_Time (  
Time_Option        nvarchar(25),  
Time_Desc          nvarchar(100),  
Start_Date         datetime,  
End_Date           datetime,  
order_by           int)  
  
Create Table #Temporary (  
Start_Date        datetime,  
End_Date          datetime)  
  
-----------------------------------------------------------------------------------------------  
  
-- Create parameters for calling the sp  
declare   
    @strRptTimeOption               as         nvarchar(100),   -- Report time option from asp page  
    @intRptShiftLength              as         int,             -- Shift length from Local_PG_ShiftLength  
    @dateRptShiftStartTime          as         datetime,        -- Start time of the shift from Local_PG_StartShift  
    @in_strRptStartDate             as         datetime,        -- Report StartDate parameter  
    @in_strRptEndDate               as         datetime         -- Report EndDate parameter  
  
-- Insert time option default values  
Insert Into #Temp_Time (Time_Option,Time_Desc,order_by)  
Select rrd_id,default_prompt_desc,convert(int,rrd_id)  
From report_relative_dates  
Where date_type_id = 3 Order By rrd_id  
  
-- Insert User Defined default Option  
Insert Into #Temp_Time (Time_Option,Time_Desc,Start_Date,End_Date,order_by)  
Values ('0','User Defined',GetDate(),GetDate(),999999)  
  
select @in_strRptStartDate = rtp.default_value  
from report_type_parameters rtp  
join report_parameters rp on rp.rp_id = rtp.rp_id  
where report_type_id = @report_type_id  
and rp_name = 'StartDate'   
  
  
select @in_strRptEndDate = rtp.default_value  
from report_type_parameters rtp  
join report_parameters rp on rp.rp_id = rtp.rp_id  
where report_type_id = @report_type_id  
and rp_name = 'EndDate'  
  
  
select @dateRptShiftStartTime = rtp.default_value  
from report_type_parameters rtp  
join report_parameters rp on rp.rp_id = rtp.rp_id  
where report_type_id = @report_type_id  
and rp_name = 'Local_PG_StartShift'  
  
select @intRptShiftLength = rtp.default_value  
from report_type_parameters rtp  
join report_parameters rp on rp.rp_id = rtp.rp_id  
where report_type_id = @report_type_id  
and rp_name = 'Local_PG_ShiftLength'  
  
  
  
  
Declare cTime Cursor  For (Select rrd_id  
From report_relative_dates  
Where date_type_id = 3)  
  
open cTime  
fetch next from cTime into @strRptTimeOption  
while @@fetch_status = 0  
begin  
    Truncate Table #Temporary  
  
    Insert Into #Temporary(Start_Date,End_Date)  
    exec spLocal_RptRunTime @strRptTimeOption ,  
    @intRptShiftLength,  
    @dateRptShiftStartTime,  
    @in_strRptStartDate,  
    @in_strRptEndDate  
  
    Update #Temp_Time  
        Set Start_Date = (Select Start_Date From #Temporary),  
            End_Date = (Select End_Date From #Temporary)  
    Where Time_Option = @strRptTimeOption  
  
    fetch next from cTime into @strRptTimeOption  
  
End  
     
close cTime  
deallocate cTime   
  
Update #Temp_Time  
    Set Start_Date = (Select Start_Date From #Temp_Time Where Time_Option = '30'),  
        End_Date = (Select Start_Date From #Temp_Time Where Time_Option = '30')  
Where Time_Option = '0'  
  
Select Time_Option,Time_Desc,  
Convert(varchar,year(Start_Date)) +'-'+   
Case Len(convert(varchar,month(Start_Date))) When 2 Then convert(varchar,month(Start_Date)) Else '0' + convert(varchar,month(Start_Date)) End  + '-' +   
Case Len(convert(varchar,day(Start_Date))) When 2 Then convert(varchar,day(Start_Date)) Else '0' + convert(varchar,day(Start_Date)) End  +   
' ' +   
Case Len(convert(varchar,datepart(hh,Start_Date))) When 2 Then convert(varchar,datepart(hh,Start_Date)) Else + '0' + convert(varchar,datepart(hh,Start_Date)) End  
+ ':'+   
Case Len(convert(varchar,datepart(mi,Start_Date))) When 2 Then convert(varchar,datepart(mi,Start_Date)) Else + '0' + convert(varchar,datepart(mi,Start_Date)) End as Start_Date ,  
  
Convert(varchar,year(End_Date)) +'-'+   
Case Len(convert(varchar,month(End_Date))) When 2 Then convert(varchar,month(End_Date)) Else '0' + convert(varchar,month(End_Date)) End  + '-' +   
Case Len(convert(varchar,day(End_Date))) When 2 Then convert(varchar,day(End_Date)) Else '0' + convert(varchar,day(End_Date)) End  +   
' ' +   
Case Len(convert(varchar,datepart(hh,End_Date))) When 2 Then convert(varchar,datepart(hh,End_Date)) Else + '0' + convert(varchar,datepart(hh,End_Date)) End  
+ ':'+   
Case Len(convert(varchar,datepart(mi,End_Date))) When 2 Then convert(varchar,datepart(mi,End_Date)) Else + '0' + convert(varchar,datepart(mi,End_Date)) End as End_Date   
  
From #Temp_Time Order By order_by  
  
Drop Table #Temp_Time  
Drop Table #Temporary  
  
Return  
  
  
  
  
  
