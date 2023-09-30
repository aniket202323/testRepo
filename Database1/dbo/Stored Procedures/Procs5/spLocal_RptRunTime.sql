  --*********************************************************************************************************************  
-- FRio  : 2006-05-19 Fixed bug on this month option  
-- Added : 2006-04-15 3 new time options : Last 24 Hours, Last Calendar Month, This Calendar Month  
-- Created On : 2005-09-27 FRio  
-- Emulates the logic embebbed on the xlt files, in order to replace it for a call to this sp.  
-- Call statement example : spLocal_RptRunTime '31',12,'5:55:00 AM','9/27/2005','9/28/2005'  
--*********************************************************************************************************************  
CREATE Procedure [dbo].[spLocal_RptRunTime]  
  
-- declare   
  
    @strRptTimeOption               as         nvarchar(100),        -- Report time option from asp page  
    @intRptShiftLength              as         int,                  -- Shift length from Local_PG_ShiftLength  
    @dateRptShiftStartTime          as         datetime,             -- Start time of the shift from Local_PG_StartShift  
    @in_strRptStartDate             as         datetime,             -- Report StartDate parameter  
    @in_strRptEndDate               as         datetime              -- Report EndDate parameter  
  
  
As  
  
---------------------------------------------------------------------------------------------------------------  
-- Test Values  
/*  
set @strRptTimeOption                =                 'THISMONTH'  
set @intRptShiftLength               =                 12  
set @dateRptShiftStartTime           =                 '05:55:00 AM'  
*/  
--  
---------------------------------------------------------------------------------------------------------------  
-- Store Procedure Variables  
-- output variables  
declare  
        @strRptStartDate                as         datetime,  
        @strRptEndDate                  as         datetime  
--  
declare   
        @actual_Time                    as         datetime,  
        @production_day_start           as         datetime,  
        @calendar_day_start             as         datetime,  
        @1st_day_production_month       as         datetime,  
        @production_day_12PM            as         datetime,  
  @1st_day_calendar_month   as     datetime  
  
  
---------------------------------------------------------------------------------------------------------------  
-- Store Procedure Temporary Tables  
Create Table #Temp_Shifts   
(rec_no              int,  
StartTime            datetime,  
EndTime              datetime)  
  
---------------------------------------------------------------------------------------------------------  
-- Format the @dateRptShiftStartTime from HH:MM:SS to 1/1/1999 HH:MM:SS   
---------------------------------------------------------------------------------------------------------  
set @dateRptShiftStartTime = Convert(datetime,'1/1/1999 ' +  @dateRptShiftStartTime)  
  
---------------------------------------------------------------------------------------------------------  
-- Set variables that will help on date calculations  
---------------------------------------------------------------------------------------------------------  
set         @actual_time                 =        GetDate()  
set         @production_day_start        =        Convert(datetime,Left(Convert(varchar,@actual_time),12) + ' ' + Right(Convert(varchar,@dateRptShiftStartTime),8))  
set         @calendar_day_start          =        Convert(datetime,Left(Convert(varchar,@actual_time),12) + ' ' + '00:00:00 AM')  
set         @1st_day_production_month    =        Convert(datetime,Convert(varchar,Month(@actual_time))+'/1/'+Convert(varchar,Year(GetDate())) + ' ' + Right(Convert(varchar,@dateRptShiftStartTime),8))  
set         @1st_day_calendar_month      =        Convert(datetime,Convert(varchar,Month(@actual_time))+'/1/'+Convert(varchar,Year(GetDate())) + ' ' + '00:00:00 AM')  
set         @production_day_12PM         =        Convert(datetime,Left(Convert(varchar,@actual_time),12) + ' ' + '12:00:00 AM')  
---------------------------------------------------------------------------------------------------------  
-- Variables Testing  
---------------------------------------------------------------------------------------------------------  
-- print '@actual_time                 ----------> '+ Convert(varchar,@actual_time)  
-- print '@production_day_start        ----------> '+ Convert(varchar,@production_day_start)  
-- print '@calendar_day_start          ----------> '+ Convert(varchar,@calendar_day_start)  
-- print '@1st_day_production_month    ----------> '+ Convert(varchar,@1st_day_production_month)  
-- print '@production_day_12PM         ----------> '+ Convert(varchar,@production_day_12PM)  
---------------------------------------------------------------------------------------------------------  
-- BUILD A TEMPORARY TABLE TO HOLD LAST 40 SHIFTS  
---------------------------------------------------------------------------------------------------------  
Declare       
        @i_shift         as         int,  
        @s_startTime     as         datetime,  
        @s_endTime       as         datetime  
  
set @i_shift       = 1  
set @s_startTime   = Dateadd(dd,1,@production_day_start)  
set @s_endTime     = dateadd(hh,@intRptShiftLength,@s_startTime)  
  
While @i_shift <= 40  
Begin  
      
    insert into #Temp_Shifts(rec_no,StartTime,EndTime)  
    values(@i_shift,@s_startTime,@s_endTime)  
  
    set @i_shift = @i_shift + 1  
    set @s_endTime = @s_startTime  
    set @s_startTime = dateadd(hh,-1 * @intRptShiftLength,@s_endTime)  
  
End  
--------------------------------------------------------------------------------------------------  
-- END BUILD TABLE  
--------------------------------------------------------------------------------------------------  
  
  
--*******************************************************************************************************                                  
--                                 SHIFTLY                                                             --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'SHIFTLY' Or @strRptTimeOption = '10001'  
Begin  
        Select @strRptStartDate = StartTime, @strRptEndDate = EndTime   
        From #Temp_Shifts  
        Where @actual_time >= StartTime and @actual_time < EndTime  
          
        If @strRptEndDate > @actual_time  
           set @strRptEndDate = @actual_time  
  
End  
  
--*******************************************************************************************************                                  
--                                 LAST SHIFT                                                          --  
--*******************************************************************************************************                                  
  
If (Upper(@strRptTimeOption) = 'LASTSHIFT' Or @strRptTimeOption = '10002')   
Begin  
    Select @strRptStartDate = StartTime, @strRptEndDate = EndTime    
    From #Temp_Shifts Where EndTime =  
    (Select StartTime   
        From #Temp_Shifts  
        Where @actual_time >= StartTime and @actual_time < EndTime)  
End  
  
--*******************************************************************************************************                                  
--                                 LAST 5 SHIFTS                                                       --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'LAST5SHIFTS' Or @strRptTimeOption = '10003'  
Begin  
    Select @strRptStartDate = StartTime From   
    #Temp_Shifts Where rec_no =  
      (Select rec_no + 5  
        From #Temp_Shifts  
        Where @actual_time >= StartTime and @actual_time < EndTime)  
  
    Select @strRptEndDate = EndTime From   
    #Temp_Shifts Where rec_no =  
      (Select rec_no + 1  
        From #Temp_Shifts  
        Where @actual_time >= StartTime and @actual_time < EndTime)  
End  
  
--*******************************************************************************************************                                  
--                                 TODAY, Current Calendar Day                                         --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'CURRENTCALDAY' Or @strRptTimeOption = '10004'  
Begin  
          set @strRptStartDate = @calendar_day_start  
          set @strRptEndDate = @actual_time  
End  
  
--*******************************************************************************************************                                  
--                                 TODAY, Current production day                                       --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'TODAY' Or @strRptTimeOption = '30'  
Begin  
   set @strRptStartDate = @production_day_start  
   If @strRptStartDate > @actual_time   
           set @strRptStartDate = DateAdd(d, -1, @strRptStartDate)  
  
   set @strRptEndDate = @actual_time  
End  
  
--*******************************************************************************************************                                  
--                                 LAST CALENDAR DAY                                                   --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'LASTCALDAY' Or @strRptTimeOption = '10005'  
Begin  
           set @strRptEndDate = @calendar_day_start  
           set @strRptStartDate = DateAdd(hh, -24, @strRptEndDate)  
End  
  
--*******************************************************************************************************                                  
--                                 YESTERDAY, Last production day                                      --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'YESTERDAY' Or @strRptTimeOption = '31'   
Begin  
           set @strRptEndDate = @production_day_start  
           If @strRptEndDate > @actual_time And @production_day_start > @production_day_12PM  
                    set @strRptEndDate = DateAdd(dd, -1, @strRptEndDate)  
  
            If @strRptEndDate > @actual_time  
                set @strRptEndDate = (DateAdd(dd, -1, @strRptEndDate))  
  
            set @strRptStartDate = (DateAdd(hh, -24, @strRptEndDate))  
End  
  
--*******************************************************************************************************                                  
--                                Last 3 Production days                                               --  
--                                Last 5 Production Days                                               --  
--                                Last 7 Production Days                                               --  
--                                Last 28 Production Days                                              --  
--                                Last 30 Production Days                                              --  
--*******************************************************************************************************                                  
  
If (Upper(@strRptTimeOption) = 'LAST3DAYS' Or Upper(@strRptTimeOption) = 'THREEDAYS' Or @strRptTimeOption = '28') Or  
   (Upper(@strRptTimeOption) = 'LAST5DAYS' Or @strRptTimeOption = '10006') Or  
   (Upper(@strRptTimeOption) = 'LAST7DAYS' Or @strRptTimeOption = '26') Or  
   (Upper(@strRptTimeOption) = 'LAST28DAYS' Or @strRptTimeOption = '10007') Or  
   (Upper(@strRptTimeOption) = 'LAST30DAYS' Or @strRptTimeOption = '27')  
  
Begin  
            set @strRptEndDate = @production_day_start  
  
            If @strRptEndDate > @actual_time And @production_day_start > @production_day_12PM  
                    set @strRptEndDate = DateAdd(dd, -1, @strRptEndDate)  
  
            If @strRptEndDate > @actual_time   
                set @strRptEndDate = DateAdd(dd, -1, @strRptEndDate)  
  
            If (Upper(@strRptTimeOption) = 'LAST3DAYS' Or Upper(@strRptTimeOption) = 'THREEDAYS' Or @strRptTimeOption = '28')                  
                    set @strRptStartDate = DateAdd(dd, -3, @strRptEndDate)  
  
            If (Upper(@strRptTimeOption) = 'LAST5DAYS' Or @strRptTimeOption = '10006')  
                    set @strRptStartDate = (DateAdd(dd, -5, @strRptEndDate))  
  
            If (Upper(@strRptTimeOption) = 'LAST7DAYS' Or @strRptTimeOption = '26')  
                    set @strRptStartDate = (DateAdd(dd, -7, @strRptEndDate))  
  
            If (Upper(@strRptTimeOption) = 'LAST28DAYS' Or @strRptTimeOption = '10007')  
                    set @strRptStartDate = (DateAdd(dd, -28, @strRptEndDate))  
  
            If (Upper(@strRptTimeOption) = 'LAST30DAYS' Or @strRptTimeOption = '27')  
                    set @strRptStartDate = DateAdd(dd, -30, @strRptEndDate)  
  
End  
  
--*******************************************************************************************************                                  
--                                Month to Now() MTD                                                   --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'THISMONTH' Or @strRptTimeOption = '29'   
Begin  
            If (Day(@actual_time) = 1 And @actual_time < @production_day_start)   
            Begin  
      
                set @strRptEndDate = @1st_day_production_month  
                set @strRptStartDate = DateAdd(mm, -1, @strRptEndDate)  
                --If @production_day_start > @actual_time And @production_day_start > @production_day_12PM  
                        set @strRptEndDate = @actual_time  
                  
                --set @strRptStartDate = DateAdd(mm, -1, @strRptEndDate)  
                  
            End  
            Else  
            Begin  
                set @strRptStartDate = @1st_day_production_month          
                set @strRptEndDate = @actual_time  
            End  
End  
  
--*******************************************************************************************************                                  
--                                Month to Date(1st Shift)                                             --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'MTD' Or @strRptTimeOption = '10011'  
Begin  
            If (Day(@actual_time) = 1 And @actual_time < @production_day_start)   
            Begin  
                set @strRptEndDate = @1st_day_production_month  
                If @production_day_start > @actual_time And @production_day_start > @production_day_12PM  
                        set @strRptEndDate = (DateAdd(dd, -1, @strRptEndDate))  
  
                set @strRptStartDate = DateAdd(m, -1, @strRptEndDate)  
  
                -- set @strRptEndDate = @production_day_start  
  
                select @strRptEndDate = StartTime from #Temp_Shifts  
                Where @actual_time >= StartTime and @actual_time < EndTime  
  
            End  
            Else  
            Begin  
                set @strRptStartDate = @1st_day_production_month  
                If @production_day_start > @actual_time And @production_day_start > @production_day_12PM  
                        set @strRptStartDate = (DateAdd(dd, -1, @strRptStartDate))  
                  
                set @strRptEndDate = @production_day_start  
            End   
End  
  
--*******************************************************************************************************                                  
--                                Last Production Month                                                --  
--                                Last 3 Production Months                                             --  
--                                Last 6 Production Months                                             --  
--                                Last 12 Production Months                                            --  
--*******************************************************************************************************     
                               
If (Upper(@strRptTimeOption) = 'LASTMONTH' Or @strRptTimeOption = '25') Or  
   (Upper(@strRptTimeOption) = 'LAST3MONTHS' Or @strRptTimeOption = '10008') Or  
   (Upper(@strRptTimeOption) = 'LAST6MONTHS' Or @strRptTimeOption = '10009') Or  
   (Upper(@strRptTimeOption) = 'LAST12MONTHS' Or @strRptTimeOption = '10010')  
  
Begin  
            set @strRptEndDate = @1st_day_production_month  
            If @production_day_start > @actual_time And @production_day_start > @production_day_12PM  
                    set @strRptEndDate = (DateAdd(d, -1, @strRptEndDate))  
  
            If (Upper(@strRptTimeOption) = 'LASTMONTH' Or @strRptTimeOption = '25')  
                        -- set @strRptStartDate = RptSubstractMonth(CDate(@strRptEndDate))  
                        set @strRptStartDate = DateAdd(m, -1, @strRptEndDate)  
  
            If (Upper(@strRptTimeOption) = 'LAST3MONTHS' Or @strRptTimeOption = '10008')  
                        set @strRptStartDate = DateAdd(m, -3, @strRptEndDate)  
  
            If (Upper(@strRptTimeOption) = 'LAST6MONTHS' Or @strRptTimeOption = '10009')  
                        set @strRptStartDate = DateAdd(m, -6, @strRptEndDate)  
  
            If (Upper(@strRptTimeOption) = 'LAST12MONTHS' Or @strRptTimeOption = '10010')  
                        set @strRptStartDate = DateAdd(m, -12, @strRptEndDate)  
              
End  
  
--*******************************************************************************************************                                  
--                                        User Defined                                                 --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'USER' Or @strRptTimeOption = '0'  
Begin  
            set @strRptStartDate        =         @in_strRptStartDate      
            set @strRptEndDate          =         @in_strRptEndDate      
End  
  
  
--*******************************************************************************************************                                  
--                                 LAST 24 HOURS          
-- Actual Time, but does not make use of the minutes  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'LAST24HRS' Or @strRptTimeOption = '10012'  
Begin        
     set @strRptEndDate =  @actual_time        
           set @strRptStartDate = DateAdd(hh, -24, @strRptEndDate)  
End  
  
--*******************************************************************************************************                                  
--                                 LAST CALENDAR MONTH                                                 --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'LASTCALMONTH' Or @strRptTimeOption = '10013'  
Begin  
           set @strRptEndDate = @1st_day_calendar_month  
           set @strRptStartDate = DateAdd(m, -1, @strRptEndDate)  
End  
  
--*******************************************************************************************************                                  
--                                  THIS CALENDAR MONTH                                                --  
--*******************************************************************************************************                                  
  
If Upper(@strRptTimeOption) = 'THISCALMONTH' Or @strRptTimeOption = '10014'  
Begin  
           set @strRptEndDate = @calendar_day_start  
           set @strRptStartDate = @1st_day_calendar_month  
End  
  
-- Select * from #temp_shifts order by starttime  
Select @strRptStartDate as StartDate,@strRptEndDate as EndDate  
  
Drop Table #Temp_Shifts  
  
Return  
  
  
  
  
