Create Procedure dbo.spCmn_AlarmCounts
 	 @LowCount 	 Int 	 Output,
 	 @MediumCount 	 Int 	 Output,
 	 @HighCount 	 Int 	 Output,
 	 @StartTs 	 DateTime,
 	 @EndTs 	 DateTime,
 	 @PU_Id 	 Int
 AS
Declare @ApId  	  Int
Select @LowCount = 0
Select @MediumCount = 0
Select @HighCount = 0
Declare @PriorityTable Table (AP_iD int)
Insert into @PriorityTable (AP_id)
  Select isnull(r.AP_Id, vrd.AP_Id)
    from Alarms a
    Join Alarm_Template_Var_Data atd  on atd.ATD_Id = a.ATD_Id
    Join Variables v on v.Var_Id = atd.Var_Id and v.PU_Id = @PU_Id
    Left outer Join Alarm_Template_SPC_Rule_Data r on r.AT_Id = atd.AT_Id and r.ATSRD_Id = a.ATSRD_Id
    Left outer Join Alarm_Template_Variable_Rule_Data vrd on vrd.AT_Id = atd.AT_Id and vrd.ATVRD_Id = a.ATVRD_Id
    Where (Start_Time <= @EndTs) and (End_Time >  @StartTs or End_Time Is Null)
Select @LowCount    = count(*) from @PriorityTable Where AP_Id = 1
Select @MediumCount = count(*) from @PriorityTable Where AP_Id = 2
Select @HighCount   = count(*) from @PriorityTable Where AP_Id = 3
