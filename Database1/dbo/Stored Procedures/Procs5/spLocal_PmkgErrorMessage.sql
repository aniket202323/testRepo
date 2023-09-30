  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-04  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_PmkgErrorMessage  
Author:   Matthew Wells (MSI)  
Date Created:  02/03/27  
  
Description:  
=========  
Issues an error message as an alarm.  
  
Change Date Who What  
=========== ==== =====  
*/  
  
CREATE PROCEDURE spLocal_PmkgErrorMessage  
@Message  varchar(50),  
@PU_Id  int,  
@User_Id  int = 26  
AS  
SET NOCOUNT ON  
  
DECLARE @TimeStamp   datetime,  
  @Alarm_Id   int,  
  @ATD_Id   int,  
  @Alarm_Type_Id  int,  
  @AT_Id   int,  
  @AT_Desc   varchar(50),  
  @Var_Id   int,  
  @Var_Desc   varchar(50),  
  @Alarm_Count   int  
  
DECLARE @Alarms TABLE(  
 Result_Set_Type  int Default 6,  
 Pre_Update   int Default 0,  
 Trans_Num   int Default 0,  
 Alarm_Id   int Null,  
 ATD_Id    int Null,  
 Start_Time   datetime Null,  
 End_Time   datetime Null,  
 Duration   float Null,  
 Ack    bit Default 0,  
 Ack_On    datetime Null,  
 Ack_By    int Null,  
 Start_Result   varchar(25) Null,  
 End_Result   varchar(25) Null,  
 Min_Result   varchar(25) Null,  
 Max_Result   varchar(25) Null,  
 Cause1    int Null,  
 Cause2    int Null,  
 Cause3    int Null,  
 Cause4    int Null,  
 Cause_Comment_Id  int Null,  
 Action1    int Null,  
 Action2    int Null,  
 Action3    int Null,  
 Action4    int Null,  
 Action_Comment_Id  int Null,  
 Research_User_Id  int Null,  
 Research_Status_Id  int Null,  
 Research_Open_Date  datetime Null,  
 Research_Close_Date  datetime Null,  
 Research_Comment_Id  int Null,  
 Source_PU_Id   int Null,  
 Alarm_Type_Id   int Null,  
 Key_Id    int Null,  
 Alarm_Desc   char(50),  
 Trans_Type   int Null,  
 Template_Variable_Comment_Id int Null,  
 AP_Id    int Null,  
 AT_Id    int Null,  
 Var_Comment_Id   int Null,  
 Cutoff    tinyint Null)  
  
--Initialization  
SELECT @AT_Desc  = 'Pmkg Error Messages',  
  @Var_Desc  = 'Error Message',  
  @TimeStamp  = convert(varchar(25), getdate(), 120)  
  
SELECT @AT_Id  = AT_Id,  
  @Alarm_Type_Id = Alarm_Type_Id  
FROM [dbo].Alarm_Templates  
WHERE AT_Desc = @AT_Desc  
  
SELECT @Var_Id  = Var_Id  
FROM [dbo].Variables  
WHERE PU_Id = @PU_Id And Var_Desc = @Var_Desc  
  
SELECT  @ATD_Id = ATD_Id  
FROM [dbo].Alarm_Template_Var_Data  
WHERE Var_Id = @Var_Id And AT_Id = @AT_Id  
  
IF @Var_Id Is Not Null And @AT_Id Is Not Null And @ATD_Id Is Not Null  
     BEGIN  
     SELECT @Alarm_Count = count(Alarm_Id) + 1  
     FROM [dbo].Alarms  
     WHERE ATD_Id = @ATD_Id And Key_Id = @Var_Id And Start_Time = @TimeStamp  
  
/* MKW - Not used for now  
     IF @Alarm_Id IS NOT NULL  
          BEGIN  
          DELETE   
          FROM Alarm_History  
          WHERE Alarm_Id = @Alarm_Id  
     
          DELETE  
          FROM Alarms  
          WHERE Alarm_Id = @Alarm_Id  
  
          INSERT #Alarms ( Pre_Update,   
   Trans_Num,   
   Alarm_Id,   
   ATD_Id,   
   Start_Time,   
   End_Time,  
   Duration,   
   Ack,   
   Ack_On,   
   Ack_By,   
   Start_Result,   
   End_Result,   
   Min_Result,  
   Max_Result,   
   Cause1,   
   Cause2,   
   Cause3,   
   Cause4,   
   Cause_Comment_Id,  
   Action1,   
   Action2,   
   Action3,   
   Action4,   
   Action_Comment_Id,   
   Research_User_Id,  
   Research_Status_Id,   
   Research_Open_Date,   
   Research_Close_Date,  
   Research_Comment_Id,   
   Source_PU_Id,   
   Alarm_Type_Id,   
   Key_Id,   
   Alarm_Desc,  
   Trans_Type,   
   Template_Variable_Comment_Id,   
   AP_Id,   
   AT_Id,   
   Var_Comment_Id,  
   Cutoff)  
          SELECT 0,   
  0,   
  a.Alarm_Id,   
  a.ATD_Id,   
  a.Start_Time,   
  a.End_Time,  
  a.Duration,   
  a.Ack,   
  a.Ack_On,   
  a.Ack_By,   
  a.Start_Result,   
  a.End_Result,   
  a.Min_Result,  
  a.Max_Result,   
  a.Cause1,   
  a.Cause2,   
  a.Cause3,   
  a.Cause4,   
  a.Cause_Comment_Id,  
  a.Action1,   
  a.Action2,   
  a.Action3,   
  a.Action4,   
  a.Action_Comment_Id,   
  a.Research_User_Id,  
  a.Research_Status_Id,   
  a.Research_Open_Date,   
  a.Research_Close_Date,  
  a.Research_Comment_Id,   
  a.Source_PU_Id,   
  a.Alarm_Type_Id,   
  a.Key_Id,   
  a.Alarm_Desc,  
  3,  
  d.Comment_Id,   
  t.AP_Id,   
  d.AT_Id,  
  v.Comment_Id,  
  0  
          FROM Alarms a  
               INNER JOIN Variables v ON a.Key_Id = v.Var_Id  
               INNER JOIN Alarm_Template_Var_Data d ON a.ATD_Id = d.ATD_Id  
               INNER JOIN Alarm_Templates t ON d.AT_Id = t.AT_Id  
          WHERE a.Alarm_Id = @Alarm_Id  
          END  
*/  
     INSERT [dbo].Alarms ( ATD_Id,   
   Start_Time,  
   Start_Result,  
   Alarm_Type_Id,   
   Key_Id,  
   Alarm_Desc,  
   User_Id )  
     VALUES ( @ATD_Id,  
  @TimeStamp,  
  @Alarm_Count,  
  @Alarm_Type_Id,  
  @Var_Id,  
  @Message,  
  @User_Id)  
     SELECT @Alarm_Id = @@Identity  
  
     INSERT @Alarms ( Pre_Update,   
   Trans_Num,   
   Alarm_Id,   
   ATD_Id,   
   Start_Time,   
   End_Time,  
   Duration,   
   Ack,   
   Ack_On,   
   Ack_By,   
   Start_Result,   
   End_Result,   
   Min_Result,  
   Max_Result,   
   Cause1,   
   Cause2,   
   Cause3,   
   Cause4,   
   Cause_Comment_Id,  
   Action1,   
   Action2,   
   Action3,   
   Action4,   
   Action_Comment_Id,   
   Research_User_Id,  
   Research_Status_Id,   
   Research_Open_Date,   
   Research_Close_Date,  
   Research_Comment_Id,   
   Source_PU_Id,   
   Alarm_Type_Id,   
   Key_Id,   
   Alarm_Desc,  
   Trans_Type,   
   Template_Variable_Comment_Id,   
   AP_Id,   
   AT_Id,   
   Var_Comment_Id,  
   Cutoff)  
     SELECT 0,   
  0,   
  a.Alarm_Id,   
  a.ATD_Id,   
  a.Start_Time,   
  a.End_Time,  
  a.Duration,   
  a.Ack,   
  a.Ack_On,   
  a.Ack_By,   
  a.Start_Result,   
  a.End_Result,   
  a.Min_Result,  
  a.Max_Result,   
  a.Cause1,   
  a.Cause2,   
  a.Cause3,   
  a.Cause4,   
  a.Cause_Comment_Id,  
  a.Action1,   
  a.Action2,   
  a.Action3,   
  a.Action4,   
  a.Action_Comment_Id,   
  a.Research_User_Id,  
  a.Research_Status_Id,   
  a.Research_Open_Date,   
  a.Research_Close_Date,  
  a.Research_Comment_Id,   
  a.Source_PU_Id,   
  a.Alarm_Type_Id,   
  a.Key_Id,   
  a.Alarm_Desc,  
  1,   
  d.Comment_Id,   
  t.AP_Id,   
  d.AT_Id,  
  v.Comment_Id,  
  0  
     FROM [dbo].Alarms a  
          INNER JOIN [dbo].Variables v ON a.Key_Id = v.Var_Id  
          INNER JOIN [dbo].Alarm_Template_Var_Data d ON a.ATD_Id = d.ATD_Id  
          INNER JOIN [dbo].Alarm_Templates t ON d.AT_Id = t.AT_Id  
     WHERE a.Alarm_Id = @Alarm_Id  
  
     UPDATE [dbo].Alarms  
     SET End_Time = dateadd(minute, 1, @TimeStamp)  
     WHERE Alarm_Id = @Alarm_Id  
  
     INSERT @Alarms ( Pre_Update,   
   Trans_Num,   
   Alarm_Id,   
   ATD_Id,   
   Start_Time,   
   End_Time,  
   Duration,   
   Ack,   
   Ack_On,   
   Ack_By,   
   Start_Result,   
   End_Result,   
   Min_Result,  
   Max_Result,   
   Cause1,   
   Cause2,   
   Cause3,   
   Cause4,   
   Cause_Comment_Id,  
   Action1,   
   Action2,   
   Action3,   
   Action4,   
   Action_Comment_Id,   
   Research_User_Id,  
   Research_Status_Id,   
   Research_Open_Date,   
   Research_Close_Date,  
   Research_Comment_Id,   
   Source_PU_Id,   
   Alarm_Type_Id,   
   Key_Id,   
   Alarm_Desc,  
   Trans_Type,   
   Template_Variable_Comment_Id,   
   AP_Id,   
   AT_Id,   
   Var_Comment_Id,  
   Cutoff)  
     SELECT 0,   
  0,   
  a.Alarm_Id,   
  a.ATD_Id,   
  a.Start_Time,   
  a.End_Time,  
  a.Duration,   
  a.Ack,   
  a.Ack_On,   
  a.Ack_By,   
  a.Start_Result,   
  a.End_Result,   
  a.Min_Result,  
  a.Max_Result,   
  a.Cause1,   
  a.Cause2,   
  a.Cause3,   
  a.Cause4,   
  a.Cause_Comment_Id,  
  a.Action1,   
  a.Action2,   
  a.Action3,   
  a.Action4,   
  a.Action_Comment_Id,   
  a.Research_User_Id,  
  a.Research_Status_Id,   
  a.Research_Open_Date,   
  a.Research_Close_Date,  
  a.Research_Comment_Id,   
  a.Source_PU_Id,   
  a.Alarm_Type_Id,   
  a.Key_Id,   
  a.Alarm_Desc,  
  2,  
  d.Comment_Id,   
  t.AP_Id,   
  d.AT_Id,   
  v.Comment_Id,  
  0  
     FROM [dbo].Alarms a  
          INNER JOIN [dbo].Variables v ON a.Key_Id = v.Var_Id  
          INNER JOIN [dbo].Alarm_Template_Var_Data d ON a.ATD_Id = d.ATD_Id  
          INNER JOIN [dbo].Alarm_Templates t ON d.AT_Id = t.AT_Id  
     WHERE a.Alarm_Id = @Alarm_Id  
  
     SELECT Result_Set_Type,  
  Pre_Update,   
  Trans_Num,   
  Alarm_Id,   
  ATD_Id,   
  Start_Time,   
  End_Time,  
  Duration,   
  Ack,   
  Ack_On,   
  Ack_By,   
  Start_Result,   
  End_Result,   
  Min_Result,  
  Max_Result,   
  Cause1,   
  Cause2,   
  Cause3,   
  Cause4,   
  Cause_Comment_Id,  
  Action1,   
  Action2,   
  Action3,   
  Action4,   
  Action_Comment_Id,   
  Research_User_Id,  
  Research_Status_Id,   
  Research_Open_Date,   
  Research_Close_Date,  
  Research_Comment_Id,   
  Source_PU_Id,   
  Alarm_Type_Id,   
  Key_Id,   
  Alarm_Desc,  
  Trans_Type,   
  Template_Variable_Comment_Id,   
  AP_Id,   
  AT_Id,   
  Var_Comment_Id,  
  Cutoff  
     FROM @Alarms  
     END  
  
  
SET NOCOUNT OFF  
  
