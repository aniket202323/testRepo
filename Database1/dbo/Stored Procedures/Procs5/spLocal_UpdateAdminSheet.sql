    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Stephane Turner, System Technologies for Industry  
Date   : 2005-11-17  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
CREATE procedure dbo.spLocal_UpdateAdminSheet  
@OutputValue varchar(25) OUTPUT,  
@TimeStamp datetime,  
@Sheet_Id int  
AS  
SET NOCOUNT ON  
  
Declare @Prev_TimeStamp datetime  
  
/* Calculate timestamp of the Product/Time variable */  
Select @Prev_TimeStamp = DateAdd(s, -Datepart(s,@TimeStamp) - 1, @TimeStamp)  
  
/* Create the Product Change column and delete the Product/Time column */  
Select 212, @Sheet_Id, 1, 1, @TimeStamp, 0  
Select 212, @Sheet_Id, 1, 3, @Prev_TimeStamp, 0  
  
  
SET NOCOUNT OFF  
  
  
