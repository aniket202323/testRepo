     /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-16  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_TurnoverDiameter  
Author:   Matthew Wells (MSI)  
Date Created:  06/04/02  
  
Description:  
=========  
Calculates the turnover diameter by calculating the reel time and then multiplying it by the reel speed.  
  
Change Date Who What  
=========== ==== =====  
06/04/02 MKW Created.  
07/02/02 MKW Added conversion factor.  
06/11/04 MKW Added check for negative value in sqrt  
*/  
  
CREATE procedure dbo.spLocal_TurnoverDiameter  
@Output_Value   varchar(25) OUTPUT,  
@Reel_Start_Time  datetime,  -- a  
@Reel_End_Time  datetime,  -- b  
@Sheetbreak_PU_Id   int,   -- c  
@Downtime_PU_Id  int,   -- d  
@Invalid_Status_Name  varchar(50),  -- e  
@Reel_Speed_Str  varchar(25),  -- f  
@Last_Reel_Speed_Str  varchar(25),  -- g  
@Caliper_Str   varchar(25),  -- h  
@Last_Caliper_Str  varchar(25),  -- i  
@Diameter_Factor_Str  varchar(25),  -- j  
@Conversion_Factor_Str  varchar(25)  -- k  
As  
SET NOCOUNT ON  
  
/* Testing   
Select  @Reel_Start_Time  = '2002-06-03 12:00:00',  
 @Reel_End_Time  = '2002-06-03 13:00:00',  
 @Sheetbreak_PU_Id = 510,  
 @Downtime_PU_Id  = 508,  
 @Production_Rate_Str = '0.102'  
*/  
  
Declare @Sheetbreak_Invalid_Status_Id  int,  
 @Sheetbreak_Time   real,  
 @Downtime_Invalid_Status_Id  int,  
 @Downtime    real,  
 @Reel_Speed    real,  
 @Reel_Length    real,  
 @Caliper    real,  
 @Diameter_Factor   real,  
 @Conversion_Factor   real  
  
/* Initialization */  
Select  @Output_Value   = Null,  
 @Conversion_Factor = 1.0  
  
  
If isnumeric(@Last_Reel_Speed_Str) = 1  
     If convert(real, @Last_Reel_Speed_Str) > 0  
          Select @Reel_Speed = convert(real, @Last_Reel_Speed_Str)  
If isnumeric(@Reel_Speed_Str) = 1  
     If convert(real, @Reel_Speed_Str) > 0  
          Select @Reel_Speed = convert(real, @Reel_Speed_Str)  
If isnumeric(@Last_Caliper_Str) = 1  
     If convert(real, @Last_Caliper_Str) > 0  
          Select @Caliper = convert(real, @Last_Caliper_Str)  
If isnumeric(@Caliper_Str) = 1  
     If convert(real, @Caliper_Str) > 0  
          Select @Caliper = convert(real, @Caliper_Str)  
If isnumeric(@Diameter_Factor_Str) = 1  
     Select @Diameter_Factor = convert(real, @Diameter_Factor_Str)  
If isnumeric(@Conversion_Factor_Str) = 1  
     Select @Conversion_Factor = convert(real, @Conversion_Factor_Str)  
  
/* Check argument */  
If isnumeric(@Reel_Speed_Str) = 1  
     Begin  
     /* Argument conversion */  
     Select @Reel_Speed = convert(real, @Reel_Speed_Str)  
  
     /* Get the invalid status id so can exclude those records */  
     Select @Sheetbreak_Invalid_Status_Id = TEStatus_Id  
     From [dbo].Timed_Event_Status  
     Where PU_Id = @Sheetbreak_PU_Id And TEStatus_Name = @Invalid_Status_Name  
  
     Select @Downtime_Invalid_Status_Id = TEStatus_Id  
     From [dbo].Timed_Event_Status  
     Where PU_Id = @Downtime_PU_Id And TEStatus_Name = @Invalid_Status_Name  
  
     /* Get the downtime for the turnover period */  
     Select @Downtime = convert(real, Sum(Datediff(s,  Case   
       When Start_Time < @Reel_Start_Time Then @Reel_Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Reel_End_Time Or End_Time Is Null Then @Reel_End_Time  
        Else End_Time   
       End)))/60  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @Downtime_PU_Id And (TEStatus_Id <> @Downtime_Invalid_Status_Id Or TEStatus_Id Is Null) And  
                Start_Time < @Reel_End_Time And (End_Time > @Reel_Start_Time Or End_Time Is Null)  
  
     /* Get the sheetbreak time for the turnover period */  
     Select @Sheetbreak_Time = convert(real, Sum(Datediff(s, Case   
       When Start_Time < @Reel_Start_Time Then @Reel_Start_Time  
              Else Start_Time   
       End,  
           Case   
       When End_Time > @Reel_End_Time Or End_Time Is Null Then @Reel_End_Time  
        Else End_Time   
       End)))/60  
     From [dbo].Timed_Event_Details  
     Where PU_Id = @Sheetbreak_PU_Id And (TEStatus_Id <> @Sheetbreak_Invalid_Status_Id Or TEStatus_Id Is Null) And  
                Start_Time < @Reel_End_Time And (End_Time > @Reel_Start_Time Or End_Time Is Null)  
  
     /* Multiply reel time by the production rate */  
     Select @Reel_Length = ltrim(str((convert(real, datediff(s, @Reel_Start_Time, @Reel_End_Time))/60-isnull(@Sheetbreak_Time, 0)-isnull(@Downtime, 0))*@Reel_Speed, 15, 3))  
  
     IF (4*@Caliper*@Reel_Length*@Diameter_Factor/3.141) > 0  
          BEGIN  
        Select @Output_Value = sqrt(4*@Caliper*@Reel_Length*@Diameter_Factor/3.141)*@Conversion_Factor  
          END  
     End  
  
  
  
  
  
SET NOCOUNT OFF  
  
  
  
