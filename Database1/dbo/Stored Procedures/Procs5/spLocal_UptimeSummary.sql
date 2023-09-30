    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-22  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_UptimeSummary  
Author:   Matthew Wells (MSI)  
Date Created:  08/27/01  
  
Description:  
=========  
This procedure summarizes uptime duration for a defined period.  From a given start time, end time, production unit, and fault it will  
summarize the downtime for that fault (or all if fault is Null).  
  
Called By:  
========  
CalcMgr  
spLocal_ClothingLifeSummary  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment  
02/21/02 MKW Changed to point to standard spLocal_DowntimeSummary  
*/  
  
CREATE procedure dbo.spLocal_UptimeSummary  
@Output_Value varchar(25) OUTPUT,  
@PU_ID int,  
@Start_Time datetime,  
@End_Time datetime,  
@Conversion float  
As  
  
SET NOCOUNT ON  
/* Testing */  
/*  
Select  @PU_ID = 2148,  
 @Start_Time = '2001-06-13 00:00:00',  
 @End_Time = '2001-06-14 00:00:00',  
 @Conversion = 3600.0  
*/  
  
Declare @Fault_Start_Time datetime,  
 @Fault_End_Time datetime,  
 @Uptime  real,  
 @Invalid_Status_Name varchar(50)  
  
Select @Invalid_Status_Name = 'Invalid'  
  
Exec [dbo].spLocal_DowntimeSummary @Output_Value OUTPUT, @PU_Id, @Start_Time, @End_Time, Null, @Conversion, @Invalid_Status_Name  
  
Select @Output_Value = convert(varchar(30), Datediff(s, @Start_Time, @End_Time)/@Conversion - convert(float, @Output_Value))  
  
SET NOCOUNT OFF  
