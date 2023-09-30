 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE procedure dbo.spLocal_GetCrewAutoCL  
@TimeStamp  datetime,  
@EC_ID int,  
@OutputValue varchar(25) OUTPUT  
As  
  
SET NOCOUNT ON  
  
Declare @Crew   varchar(25),  
 @PU_Id int  
  
Select @PU_Id = PU_Id   
From [dbo].Event_Configuration  
Where EC_Id = @EC_Id  
  
Select @Crew = Crew   
From [dbo].Local_Crew_Schedule  
Where Date <= @TimeStamp And End_Time > @TimeStamp And PU_Id = @PU_Id  
  
Select @OutputValue = @Crew  
  
SET NOCOUNT OFF  
  
