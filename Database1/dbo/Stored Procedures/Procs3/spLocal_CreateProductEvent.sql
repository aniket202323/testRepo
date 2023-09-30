 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-24  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     SET NOCOUNT ON/OFF   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
CREATE procedure dbo.spLocal_CreateProductEvent  
@Output_Value As varchar(25) OUTPUT,  
@Source_PU_Id int,  
@Start_Time datetime  
AS  
SET NOCOUNT ON  
DECLARE @Start_Id int  
DECLARE @Prod_Id int  
  
SELECT @Start_Id = MAX( Start_Id)  
FROM [dbo].Production_Starts  
  
SELECT TOP 1 @Prod_Id = Prod_Id  
FROM [dbo].Production_Starts  
WHERE PU_ID = @Source_PU_Id  
ORDER BY Start_Time DESC  
  
SELECT 3, @Start_Id+1, @Source_PU_Id, 19, @Start_Time, 0  
  
SELECT @Output_Value = convert(varchar(25), @Prod_Id)  
If @Output_Value Is Null  
     Select @Output_Value = '0'  
  
SET NOCOUNT OFF  
  
