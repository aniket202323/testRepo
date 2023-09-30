   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-09  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_SetStatus  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
07/10/02 MKW Added check for valid input data type (ie. can't expect 'int').  
*/  
  
CREATE procedure dbo.spLocal_SetStatus  
@Output_Value  varchar(25) OUTPUT,  
@Event_Id  int,  
@Last_Status_Str varchar(30),  
@Status_Flag_Str varchar(30),  
@ProdStatus_Desc varchar(30)  
AS  
SET NOCOUNT ON  
  
Declare @Last_Status  int,  
 @Status_Flag  int,  
 @ProdStatus_Id  int,  
 @Event_Status  int,  
 @PU_Id  int,  
 @Event_Num  varchar(30),  
 @TimeStamp  varchar(30),  
 @Source_Event  int,  
 @StrSQL    varchar(8000),  
 @AppVersion   varchar(30),  
 @User_id   int  
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
/* Initialization */  
Select @Last_Status = Null,  
 @Status_Flag = Null  
  
/* Verify and convert arguments */  
If isnumeric(@Last_Status_Str) = 1  
     Select @Last_Status = convert(int, convert(float, @Last_Status_Str))  
If isnumeric(@Status_Flag_Str) = 1  
     Select @Status_Flag = convert(int, convert(float, @Status_Flag_Str))  
  
Select @ProdStatus_Id = 0  
  
Select @ProdStatus_Id = ProdStatus_Id  
From [dbo].Production_Status  
Where ProdStatus_Desc = @ProdStatus_Desc  
  
Select  @Event_Num  = Event_Num,  
 @PU_Id  = PU_Id,  
 @TimeStamp  = convert(varchar(30), TimeStamp, 120),   
 @Source_Event = Source_Event,  
 @Event_Status = Event_Status  
From [dbo].Events  
Where Event_Id = @Event_Id  
  
If @Status_Flag = 1 And @ProdStatus_Id <> @Event_Status And @ProdStatus_Id > 0  
     Begin  
  IF @AppVersion LIKE '4%'  
   BEGIN  
    Select 1, 1, 2, @Event_Id, @Event_Num, @PU_Id, @TimeStamp, Null, @Source_Event, @ProdStatus_Id, 1, @User_id, 0,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null  
   END  
  ELSE  
   BEGIN  
    Select 1, 1, 2, @Event_Id, @Event_Num, @PU_Id, @TimeStamp, Null, @Source_Event, @ProdStatus_Id, 1, @User_id, 0  
   END  
     Select @Output_Value = @Event_Status  
     End  
Else If @Status_Flag = 0 And @ProdStatus_Id = @Event_Status And @Last_Status > 0  
     Begin  
   IF @AppVersion LIKE '4%'  
    BEGIN  
     Select 1, 1, 2, @Event_Id, @Event_Num, @PU_Id, @TimeStamp, Null, @Source_Event, @Last_Status, 1, @User_id, 0,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null ,Null  
    END  
   ELSE  
    BEGIN  
     Select 1, 1, 2, @Event_Id, @Event_Num, @PU_Id, @TimeStamp, Null, @Source_Event, @Last_Status, 1, @User_id, 0  
    END       
     Select @Output_Value = @Last_Status  
     End  
Else  
     Begin  
     Select @Output_Value = @Last_Status  
     End  
  
SET NOCOUNT OFF  
  
