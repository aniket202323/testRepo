/*  
Stored Procedure: spLocal_UpdateStopsReportData  
Author:   Matthew Wells (MSI)  
Date Created:  04/11/02  
  
Description:  
=========  
This procedure updates specific data associated with the downtime.  
  
Change Date Who What  
=========== ==== =====  
04/11/02 MKW Created  
*/  
CREATE PROCEDURE spLocal_UpdateStopsReportData  
@Output_Value    varchar(25) OUTPUT,  
@TimeStamp    datetime, --a  
@Triggering_Var_Id   int,  --b  
@Lost_Prod_Var_Id   int,  --c - Papermaking downtime/repulper tons  
@PRID_Internal_Var_Id   int,  --d - Converting internal backstand PRID   
@PRID_External_Var_Id   int,  --e - Converting external backstand PRID  
@Sheet_Width_Internal_Var_Id  int,  --f - Converting internal backstand sheet width  
@Sheet_Width_External_Var_Id  int,  --g - Converting external backstand sheet width  
@Actual_Speed_Var_Id   int,  --h - Papermaking rate loss actual speed  
@Target_Speed_Var_Id   int,  --i - Papermaking rate loss target speed  
@Effective_Downtime_Var_Id  int  --j - Papermaking rate loss effective downtime  
As  
  
Declare @PU_Id int,  
 @TEDet_Id int,  
 @UserName varchar(50),  
 @Result varchar(25)  
  
Return  
--Begin Transaction  
  
/* Initialization */  
Select  @TEDet_Id = Null,  
 @UserName = 'XXXX0001'  
  
/* Get Timed Event Detail Id */   
Select @PU_Id = PU_Id  
From Variables  
Where Var_Id = @Triggering_Var_Id  
  
Select @TEDet_Id = TEDet_Id  
From Timed_Event_Details  
Where PU_Id = @PU_Id And Start_Time = @TimeStamp  
  
If @TEDet_Id Is Not Null  
     Begin  
     Select @Result = Result  
     From tests  
     Where Result_On = @TimeStamp And Var_Id = @Triggering_Var_Id  
  
     If @Triggering_Var_Id = @Lost_Prod_Var_Id  
          Update Local_ReportStopsFinal  
          Set LostProd = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @Sheet_Width_Internal_Var_Id  
          Update Local_ReportStopsFinal  
          Set SheetWidth = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @Sheet_Width_External_Var_Id  
          Update Local_ReportStopsFinal  
          Set SheetWidth = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @PRID_Internal_Var_Id  
          Update Local_ReportStopsFinal  
          Set Turnover = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @PRID_External_Var_Id  
          Update Local_ReportStopsFinal  
          Set Turnover = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @Actual_Speed_Var_Id  
          Update Local_ReportStopsFinal  
          Set ActualSpeed = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @Target_Speed_Var_Id  
          Update Local_ReportStopsFinal  
          Set TargetSpeed = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     Else If @Triggering_Var_Id = @Effective_Downtime_Var_Id  
          Update Local_ReportStopsFinal  
          Set EffectiveDowntime = convert(float, @Result)  
          Where UserName = @UserName And TEDet_Id = @TEDet_Id  
     End  
  
Select @Output_Value = convert(varchar(25), @Triggering_Var_Id)  
  
--Commit Transaction  
  
  
  
