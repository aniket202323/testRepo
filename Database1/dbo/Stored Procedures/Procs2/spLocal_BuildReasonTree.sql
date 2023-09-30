   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-26  
Version  : 1.0.1  
Purpose  : SET nocount + Version number   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
*/  
  
  
CREATE procedure dbo.spLocal_BuildReasonTree  
@TreeName varchar (50),  
@Level1 varchar (100),  
@Level2 varchar (100),  
@Level3 varchar (100),  
@Level4 varchar (100)  
AS  
  
SET NOCOUNT ON  
  
Insert Into HDI_TreeInfo (TreeName, Level1, Level2, Level3, Level4)  
 Values (@TreeName,   
  @Level1,   
  @Level2,   
  @Level3,   
  @Level4)  
  
SET NOCOUNT OFF  
  
