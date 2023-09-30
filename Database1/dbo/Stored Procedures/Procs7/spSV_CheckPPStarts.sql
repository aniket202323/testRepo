CREATE Procedure dbo.spSV_CheckPPStarts
--Declare
@Action int,
@LanguageId int,
@PathId int,
@PPId int,
@PPStartId int,
@StartTime datetime,
@EndTime datetime OUTPUT,
@Message varchar(7000) OUTPUT,
@VBMsgBoxStyle int OUTPUT
AS
--VBMsgBoxStyle
--vbYesNo = 4
--vbInformation = 64
--@Action
--Update = 1
--Close = 2
Select @Message = '', @VBMsgBoxStyle = 64
--Select @Action = 1, @LanguageId = 0, @PathId = 9, @PPId = 24342, @PPStartId = 819, @StartTime = '2005-04-27 11:06:34', @EndTime = '2005-04-28 08:19:12', @Message = NULL, @VBMsgBoxStyle = NULL
--Select PP_Id, Process_Order, PP_Status_Id, Forecast_Start_Date, Actual_Start_Time, Forecast_End_Date, Actual_End_Time From Production_Plan Where PP_Id = @PPId
Declare @IsScheduleUnit int, @IsScheduleStartTime datetime, @IsScheduleEndTime datetime, @IsSchedulePPStartId int
Declare @CurrentPUId int, @CurrentStartTime datetime, @CurrentEndTime datetime
Declare @PreviousEndTime datetime, @NextStartTime datetime
Declare @Next_PPId int, @Next_POStartTime datetime, @Min_ImpliedSequence int, @ImpliedSequence int, @POEndTime datetime
Select @CurrentPUId = PU_Id, @CurrentStartTime = Start_Time, @CurrentEndTime = End_Time
 	 From Production_Plan_Starts
 	 Where PP_Start_Id = @PPStartId
--Select @CurrentPUId as CurrentPUId
Select @IsScheduleUnit = PU_Id
 	 From PrdExec_Path_Units
 	 Where Path_Id = @PathId
 	 And Is_Schedule_Point = 1
--Select @IsScheduleUnit as IsScheduleUnit
Select @IsScheduleStartTime = Max(Start_TIme)
 	 From Production_Plan_Starts
 	 Where PP_Id = @PPId
 	 And PU_Id = @IsScheduleUnit
 	 And Start_Time <= @CurrentStartTime
--Select @IsScheduleStartTime as 'IsScheduleStartTime'
Select @IsScheduleEndTime = Min(End_TIme)
 	 From Production_Plan_Starts
 	 Where PP_Id = @PPId
 	 And PU_Id = @IsScheduleUnit
 	 And End_Time >= @CurrentEndTime
--Select @IsScheduleEndTime as 'IsScheduleEndTime'
Select @IsSchedulePPStartId = PP_Start_Id
 	 From Production_Plan_Starts
 	 Where PP_Id = @PPId
 	 And PU_Id = @IsScheduleUnit
 	 And Start_Time = @IsScheduleStartTime
--Select @IsSchedulePPStartId as IsSchedulePPStartId
Select @ImpliedSequence = Implied_Sequence --, @POEndTime = Actual_End_Time
 	 From Production_Plan
 	 Where PP_Id = @PPId
--Get the latest end time of the scheduleing point - this handles reworks
Select @POEndTime = End_Time
  From Production_Plan_Starts 
 	 Where PP_Id = @PPId and PU_Id = @IsScheduleUnit 
    and Start_Time = 
          (Select max(Start_Time) 
             From Production_Plan_Starts 
             Where PP_Id = @PPId and PU_Id = @IsScheduleUnit) 
--Select @ImpliedSequence as ImpliedSequence, @POEndTime as POEndTime
Select @Min_ImpliedSequence = Min(Implied_Sequence)
  From Production_Plan
  Where Path_Id = @PathId
  And Implied_Sequence > @ImpliedSequence
--Select @Min_ImpliedSequence as Min_ImpliedSequence
Select @Next_POStartTime = Actual_Start_Time, @Next_PPId = PP_Id
  From Production_Plan
  Where Path_Id = @PathId
  And Implied_Sequence = @Min_ImpliedSequence
--Select @Next_POStartTime as Next_POStartTime, @Next_PPId as Next_PPId
--Select PP_Id, Process_Order, PP_Status_Id, Forecast_Start_Date, Actual_Start_Time, Forecast_End_Date, Actual_End_Time From Production_Plan Where PP_Id = @Next_PPId
If @Action = 1 --Update
 	 Begin
 	  	 If (@IsSchedulePPStartId <> @PPStartId And @StartTime < @IsScheduleStartTime)
 	  	  	 Begin
 	  	  	  	 --Start Time Cannot Be Before the Scheduling Unit Start Time.
 	  	  	  	 Select @Message = coalesce(ld2.Prompt_String, ld.Prompt_String), @VBMsgBoxStyle = 64 from Language_Data ld 
 	  	       Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	  	       where ld.Language_Id = 0 and ld.Prompt_Number = 20460
 	  	  	 End
 	  	 Else If (@IsSchedulePPStartId <> @PPStartId And @EndTime > @IsScheduleEndTime)
 	  	  	 Begin
 	  	  	  	 --End Time Cannot Be After the Scheduling Unit End Time.
 	  	  	  	 Select @Message = coalesce(ld2.Prompt_String, ld.Prompt_String), @VBMsgBoxStyle = 64 from Language_Data ld 
 	  	       Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	  	       where ld.Language_Id = 0 and ld.Prompt_Number = 20464
 	  	  	 End
 	  	 Else If (@EndTime > @POEndTime and @POEndTime is NOT NULL) or (@EndTime > @Next_POStartTime and @Next_POStartTime is NOT NULL)
 	  	  	 Begin
 	  	  	  	 --End Time Cannot Exceed the Actual End Time of the Active Process Order or the Actual Start Time of the Next Process Order.
 	  	  	  	 Select @Message = coalesce(ld2.Prompt_String, ld.Prompt_String), @VBMsgBoxStyle = 64 from Language_Data ld 
 	  	       Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	  	       where ld.Language_Id = 0 and ld.Prompt_Number = 20461
 	  	  	 End
 	  	 Else
 	  	  	 Begin 	  	  	  	 
 	  	  	  	 If (Select Count(*) From Production_Plan_Starts Where PP_Id = @PPId and PU_Id = @CurrentPUId) > 1
 	  	  	  	  	 Begin
 	  	  	  	  	  	 Select @PreviousEndTime = Max(End_Time)
 	  	  	  	  	  	  	 From Production_Plan_Starts
 	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	 And PU_Id = @CurrentPUId
 	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	 And End_Time <= @CurrentStartTime
 	  	  	  	  	  	 
--  	  	  	  	  	  	 Select @PreviousEndTime as PreviousEndTime
 	  	  	  	  	  	 
 	  	  	  	  	  	 Select @NextStartTime = Min(Start_TIme)
 	  	  	  	  	  	  	 From Production_Plan_Starts
 	  	  	  	  	  	  	 Where PP_Id = @PPId
 	  	  	  	  	  	  	 And PU_Id = @CurrentPUId
 	  	  	  	  	  	  	 And PP_Start_Id <> @PPStartId
 	  	  	  	  	  	  	 And Start_Time >= @CurrentEndTime
 	  	  	  	  	  	 
--  	  	  	  	  	  	 Select @NextStartTime as NextStartTime
 	  	  	  	  	  	 If @StartTime < @PreviousEndTime or @EndTime > @NextStartTime
 	  	  	  	  	  	  	 Begin
 	  	  	  	  	  	  	  	 --Would You Like To Merge Run Time Records?
 	  	  	  	  	  	  	  	 Select @Message = coalesce(ld2.Prompt_String, ld.Prompt_String), @VBMsgBoxStyle = 4 from Language_Data ld 
 	  	  	  	  	  	       Left outer Join Language_Data ld2 on ld2.Prompt_Number = ld.Prompt_Number and ld2.Language_Id = @LanguageId
 	  	  	  	  	  	       where ld.Language_Id = 0 and ld.Prompt_Number = 20462
 	  	  	  	  	  	  	 End 	  	 
 	  	  	  	  	 End
 	  	  	 End
 	 End
Else If @Action = 2 --Close
 	 Begin
 	  	 If (@EndTime > @POEndTime and @POEndTime is NOT NULL)
 	  	  	 Select @EndTime = @POEndTime
 	  	 Else If (@EndTime > @Next_POStartTime and @Next_POStartTime is NOT NULL)
 	  	  	 Select @EndTime = @Next_POStartTime
 	  	 Else
 	  	  	 Select @EndTime = @EndTime
 	 End
