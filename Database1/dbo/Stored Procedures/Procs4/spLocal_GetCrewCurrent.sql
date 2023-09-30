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
  
  
CREATE procedure dbo.spLocal_GetCrewCurrent  
@OutputValue varchar(25) OUTPUT,  
@CurrentTime  datetime,  
@PU_Id int  
AS  
  
SET NOCOUNT ON  
  
DECLARE @Crew as varchar(25)  
  
SELECT TOP 1 @Crew = Crew_Desc   
FROM [dbo].Crew_Schedule  
WHERE Start_Time <= @CurrentTime And End_Time > @CurrentTime And PU_Id = @PU_Id  
ORDER BY Start_Time DESC  
  
SELECT @OutputValue = @Crew  
  
SET NOCOUNT OFF  
  
