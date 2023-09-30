  /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CvtgTeamByProductChange  
Author:   Matthew Wells (MSI)  
Date Created:  07/30/03  
  
Description:  
=========  
  
  
Change Date Who What  
=========== ==== =====  
07/30/03 MKW Created for 215.508  
*/  
  
CREATE procedure dbo.spLocal_CvtgTeamByProductChange  
@OutputValue varchar(25) OUTPUT,  
@Var_Id  int,  
@TimeStamp  datetime,  
@PU_Id  int  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Team  varchar(25),  
 @Var_PU_Id int,  
 @User_id   int  
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM Users  
WHERE username = 'Reliability System'  
  
DECLARE @Tests Table (  
 Result_Set_Type  int DEFAULT 2,  
 Var_Id        int NULL,  
 PU_Id    int NULL,   
 User_Id   int NULL,  
 Cancelled   int DEFAULT 0,  
 Result    varchar(50) NULL,   
 Result_On   varchar(50) NULL,   
 Transaction_Type  int DEFAULT 1,   
 Post_Update  int DEFAULT 0)  
  
SELECT TOP 1 @Team = Crew_Desc   
FROM [dbo].Crew_Schedule  
WHERE Start_Time <= dateadd(s, 1, @TimeStamp)  
 AND End_Time > dateadd(s, 1, @TimeStamp)  
 AND PU_Id = @PU_Id  
ORDER BY Start_Time DESC  
  
INSERT INTO @Tests ( Var_Id,  
   PU_Id,  
   Result,  
   Result_On)  
SELECT @Var_Id,   
 PU_Id,  
 @Team,  
 convert(varchar(50), dateadd(s, 1, @TimeStamp), 120)  
FROM [dbo].Variables  
WHERE Var_Id = @Var_Id  
  
-- Output results  
SELECT Result_Set_Type,  
 Var_Id,  
 PU_Id,  
 @User_Id,  
 Cancelled,  
 Result,  
 Result_On,  
 Transaction_Type,  
 Post_Update  
FROM @Tests  
  
SELECT TOP 1 @Team = Crew_Desc   
FROM [dbo].Crew_Schedule  
WHERE Start_Time <= @TimeStamp  
 AND End_Time > @TimeStamp  
 AND PU_Id = @PU_Id  
ORDER BY Start_Time DESC  
  
SELECT @OutputValue = @Team  
  
SET NOCOUNT ON  
  
