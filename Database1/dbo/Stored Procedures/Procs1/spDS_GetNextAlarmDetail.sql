Create Procedure dbo.spDS_GetNextAlarmDetail
--@PUId int,
--@TimeStamp datetime,
@Orientation int,   -- 0-> previous, -1 --> next
--@PriorityId int,
@OriginalAlarmId int,
@NewAlarmId int Output,
@NewAlarmStartTime datetime Output,
@NewAlarmEndTime datetime Output
AS
 Declare @NewTimeStamp datetime,
         @PUId  int,
         @TimeStamp  datetime,
         @PriorityId int
 /*
declare @newAL int
declare @NewALST datetime
declare @NewALET datetime
exec spDS_GetNextAlarmDetail  @Orientation=1, @OriginalAlarmId=5,
@NewAlarmId = @NewAL output, @NewAlarmStartTime=@NEWALST output, @NewAlarmEndTime=@NewALET output
select @NewAl
*/
----------------------------------------------------------------
-- Initialize variables
---------------------------------------------------------------- 
 Select @NewAlarmId = 0
----------------------------------------------------------------
-- Get Alarm Information
---------------------------------------------------------------
 Select @PUId = AL.Source_PU_Id, @TimeStamp = AL.STart_Time, 
        @PriorityId = AT.AP_Id
         From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
                        Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id
          Where AL.Alarm_Id = @OriginalAlarmId
----------------------------------------------------------------
-- Get immediate next/previous timestamp
----------------------------------------------------------------
 If (@Orientation = 1) -- next
  Select @NewTimeStamp = Min(AL.Start_Time) 
   From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
                  Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id
    Where AL.Source_pu_id = @PUId 
     And AL.Start_Time >= @TimeStamp 
      And AT.AP_Id =@PriorityId 
--       And AL.Alarm_Id <> @OriginalAlarmId
       And AL.Alarm_Id > @OriginalAlarmId
--   And Start_Time > @TimeStamp
  Else  -- =0 , previous
   Select @NewTimeStamp = Max(Start_Time) 
    From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
                   Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id
     Where AL.Source_pu_id = @PUId 
      And AL.Start_Time <= @TimeStamp 
       And AT.AP_Id =@PriorityId 
--        And AL.Alarm_Id<> @OriginalAlarmId
        And AL.Alarm_Id< @OriginalAlarmId
----------------------------------------------------------------
-- Get Id for the immediate next/previous
---------------------------------------------------------------
  If (@NewTimeStamp Is Not NULL)
   Begin
    If (@Orientation=1) -- next
     Begin
      Select @NewAlarmId = Min(Alarm_Id)
       From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
                      Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id
        Where AL.Source_pu_id = @PUId
         And AL.Start_Time = @NewTimeStamp 
          And AT.AP_Id =@PriorityId 
           And AL.Alarm_Id > @OriginalAlarmId
     End
    Else
     Begin  -- previous
      Select @NewAlarmId = Max(Alarm_Id)
       From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
                      Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id
        Where AL.Source_pu_id = @PUId
         And AL.Start_Time = @NewTimeStamp 
          And AT.AP_Id =@PriorityId 
           And AL.Alarm_Id<@OriginalAlarmId
     End
---------------------------------------------------------------
-- set output parameters
--------------------------------------------------------------    
    Select  @NewAlarmStartTime = AL.Start_Time, @NewAlarmEndTime =Coalesce(AL.End_Time,AL.Start_Time) 
     From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
                    Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id        
      Where AL.Alarm_Id = @NewAlarmId
    End 
--   Select @NewAlarmId = AL.Alarm_Id, @NewAlarmStartTime=AL.Start_Time, @NewAlarmEndTime=Coalesce(AL.End_Time,AL.Start_Time)  
--    From Alarms AL Inner Join Alarm_template_Var_Data AD On AL.Atd_Id = AD.ATD_Id
--                   Inner Join Alarm_Templates AT On AT.AT_Id = AD.AT_Id 
--     Where AL.source_Pu_id = @PUId 
--      And AL.Start_Time = @NewTimeStamp
--       And AT.AP_Id = @PriorityId 
--      And AL.Alarm_Id <> @OriginalAlarmId
--  If (@NewAlarmEndTime is null) Select @NewAlarmEndTime = @NewAlarmStartTime 
