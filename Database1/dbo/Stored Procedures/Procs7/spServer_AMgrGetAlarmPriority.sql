CREATE PROCEDURE dbo.spServer_AMgrGetAlarmPriority
@AlarmId int,
@Prio int output
AS
declare @KeyId as int,
        @AlarmTypeId as int, 
        @ATDId as int, 
        @ATSRDId as int,
        @SubType as int,
        @ATVRDId as int
select @prio= NULL
select @KeyId=NULL
select @KeyId=Key_Id, @ATVRDId = ATVRD_Id, @ATSRDId=ATSRD_Id, @AlarmTypeId=Alarm_Type_Id, @ATDId=ATD_Id, @SubType=SubType From Alarms where Alarm_Id = @AlarmId
if (@KeyId is not null)
begin
  if @AlarmTypeId = 1 -- Var
  begin
    select @Prio=vrd.AP_ID 
    from alarm_template_var_data atv 
    join alarm_template_Variable_Rule_Data vrd on vrd.at_id = atv.at_id
    where atv.atd_id = @ATDId and @ATVRDId = vrd.ATVRD_Id
  end
  if @AlarmTypeId = 2 -- SPC
  begin
    select @Prio=spc.AP_ID 
    from alarm_template_var_data atv 
    join alarm_template_SPC_Rule_Data spc on spc.at_id = atv.at_id
    where atv.atd_id = @ATDId and @ATSRDId = spc.ATSRD_Id
  end
--  if @AlarmTypeId = 3 -- ProdPlan
--  begin
--    select 0
--  end
  if @AlarmTypeId = 4 -- SPC Group
  begin
    select @Prio=spc.AP_ID 
    from alarm_template_var_data atv 
    join alarm_template_SPC_Rule_Data spc on spc.at_id = atv.at_id
    where atv.atd_id = @SubType and @ATSRDId = spc.ATSRD_Id
  end
--  if @AlarmTypeId = 5 -- Prod Metric
--  begin
--    select @AlarmTypeId
--  end
end
