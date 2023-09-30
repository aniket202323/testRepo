CREATE PROCEDURE spLocal_ReportBladeChanges  
  
  @Start   datetime,  
  @End   datetime,  
  @UnitHeader  varchar(10),  
  @HomeUnit  int,  
  @UserName  char(20),  
  @DEBUG_STATUS int  
AS  
--declare variables  
 DECLARE  
  @PUID  int,  
  @UnitTail varchar(40),  
  @VarHeader varchar(30),  
  @VarTailDur varchar(20),  
  @VarTailCau varchar(20),  
  @VarTailRea varchar(20),  
  @VarTailTO varchar(20),  
  @ReportDate datetime  
/*  
--set variables  
 set @UnitHeader = 'GP06 '  
 set @Start = '2002-01-29 00:00:00'  
 set @End = '2002-01-30 00:00:00'  
 set @HomeUnit = 8  
*/  
 set @VarTailDur = 'Duration'  
 set @VarTailCau= 'Cause'  
 set @VarTailRea = 'Reason'  
 set @VartailTO = 'Turnover'  
 set @ReportDate = getdate()  
/*  
--create temp table  
 create table #fgo(  
  Starttime datetime,  
  BladeType varchar(50),  
  Life  float(7),  
  Cause  varchar(50),  
  Reason  varchar(50),  
  Turnover varchar(50),  
  Team  varchar(50),  
  Shift  varchar(50))  
*/  
--get the data for the Cleaning Blade  
 --get the unit id  
  set @UnitTail = ' Cleaning Blade'  
  set @VarHeader = 'Cleaning Blade Change '  
  
  select @PUID = pu_id  
   from prod_units  
   where pu_desc = @UnitHeader + @UnitTail  
  
 --get the events  
  insert into Local_ReportPMKGBlades(Eventtime,BladeType,UserName,ReportDate,pu_id)  
   (select events.timestamp,@UnitTail,@UserName,@ReportDate,pu_id  
     from events  
    where pu_id = @PUID  
     and events.timestamp >= @Start and events.timestamp <= @end)  
  
 --get durations  
  exec spLocal_ReportBlades @VarHeader,@VarTailDur,@PUID,'Life',1,@DEBUG_STATUS  
 --get cause  
  exec spLocal_ReportBlades @VarHeader,@VarTailCau,@PUID,'Cause',1,@DEBUG_STATUS  
 --get reason  
  exec spLocal_ReportBlades @VarHeader,@VarTailRea,@PUID,'Reason',1,@DEBUG_STATUS  
 --get turnover  
  exec spLocal_ReportBlades @VarHeader,@VarTailTO,@PUID,'Turnover',1,@DEBUG_STATUS  
--get the data for the Creping Blade  
 --get the unit id  
  set @UnitTail = ' Creping Blade'    
  set @VarHeader = 'Creping Blade Change '  
  select @PUID = pu_id  
   from prod_units  
   where pu_desc = @UnitHeader + @UnitTail  
  
 --get the events  
  insert into Local_ReportPMKGBlades(Eventtime,BladeType,UserName)  
   (select events.timestamp,@UnitTail,@UserName  
     from events  
    where pu_id = @PUID  
     and events.timestamp >= @Start and events.timestamp <= @end)  
  
 --get durations  
  exec spLocal_ReportBlades @VarHeader,@VarTailDur,@PUID,'Life',@UserName,@DEBUG_STATUS  
 --get cause  
  exec spLocal_ReportBlades @VarHeader,@VarTailCau,@PUID,'Cause',@UserName,@DEBUG_STATUS  
 --get reason  
  exec spLocal_ReportBlades @VarHeader,@VarTailRea,@PUID,'Reason',@UserName,@DEBUG_STATUS  
 --get turnover  
  exec spLocal_ReportBlades @VarHeader,@VarTailTO,@PUID,'Turnover',@UserName,@DEBUG_STATUS  
 --update team and shift  
  print 'update the team and shift'  
   
  update Local_ReportPMKGBlades  
    set team = Crew_Desc,  
     Local_ReportPMKGBlades.shift = Crew_Schedule.Shift_Desc  
   from Crew_Schedule  
   where Local_ReportPMKGBlades.Eventtime >= Crew_Schedule.start_time   
    and Local_ReportPMKGBlades.Eventtime <= Crew_Schedule.end_time  
    and @HomeUnit = Crew_Schedule.PU_ID  
  
--update product  
  IF @DEBUG_STATUS = 1  
   BEGIN  
    print 'Update Product'  
   END  
   
  update Local_ReportPMKGBlades  
   set product = prod_desc  
     
   from products  
    inner join production_starts on (production_starts.prod_id = products.prod_ID)  
    inner join prod_units on (prod_units.pu_ID = production_starts.pu_ID)  
   where start_time<=eventtime  and (end_time>=eventtime or end_time is null )  
    and prod_desc <> 'No Grade'  
    and prod_units.PU_ID =@HomeUnit  
    and username = @USername  
  
  
  
  
  
  
  
  
  
  
  
  
  
  
