 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2006-01-31  
Version  : 1.0.4  
Purpose  : Added : Result IS NOT NULL to avoid "Warning: Null value is eliminated by an aggregate or other SET operation."  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.3  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetTestTotal  
Author:   Matthew Wells (MSI)  
Date Created:  00/00/00  
  
Description:  
=========  
  
Change Date Who What  
=========== ==== =====  
03/10/03 MKW Added comment and fixed issue with integer summary.  
10/17/05 FGO added so a value is always stubbed in  
*/  
  
CREATE  PROCEDURE spLocal_GetTestTotal  
@Output_Value  varchar(25) OUTPUT,  
@Var_Id  int,  
@Start_Time_Str varchar(25),  
@End_Time_Str  varchar(25)  
As  
  
SET NOCOUNT ON  
  
Declare @Start_Time  datetime,  
 @End_Time  datetime,  
 @Total   int,  
 @Data_Type_Id  int,  
 @SumValue  int  
  
/* Testing...  
Select  @Var_Id = 3928,  
 @Start_Time_Str = '2001-10-14 01:45:00.000',  
 @End_Time_Str = '2001-10-15 01:45:00.000'  
*/  
  
-- Initialization   
Select @Output_Value = '0'  
  
Select @Data_Type_Id = Data_Type_Id   
From [dbo].Variables   
Where Var_Id = @Var_Id  
  
-- Summarize integer data   
If isdate(@Start_Time_Str) = 1 And isdate(@End_Time_Str) = 1  
     Begin  
     Select @Start_Time = convert(datetime, @Start_Time_Str),  
  @End_Time = convert(datetime, @End_Time_Str)  
  
     If @Data_Type_Id = 1  
          Select @SumValue =  convert(int, sum(convert(real, Result)))  
          From [dbo].Tests  
          Where Var_Id = @Var_Id And Result_On > @Start_Time And Result_On <= @End_Time AND Result IS NOT NULL  
     Else If @Data_Type_Id = 2  
          Select @SumValue =  sum(convert(float, Result))  
          From [dbo].Tests  
          Where Var_Id = @Var_Id And Result_On > @Start_Time And Result_On <= @End_Time AND Result IS NOT NULL  
     End  
  
SELECT @Output_Value =  
 CASE  
  WHEN @SumValue IS NULL THEN 0  
  ELSE @SumValue  
 END  
  
SET NOCOUNT OFF  
  
