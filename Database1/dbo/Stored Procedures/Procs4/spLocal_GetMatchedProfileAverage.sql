    /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-02  
Version  : 1.0.2  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Stored Procedure: spLocal_GetMatchedProfileAverage  
Author:   Matthew Wells (MSI)  
Date Created:  11/27/01  
  
Description:  
=========  
Calculates the average for an element of a calculated profile.  The source profile is essentially folded in half and the corresponding  
elements are averaged (ie. 1&44, 2&43, 3&42 etc...)  
  
Change Date Who What  
=========== ==== =====  
11/27/01 MKW Created procedure  
02/18/02 MKW Modified to account for the fact that only the nth element onwards is specified in the dependencies.  
*/  
CREATE Procedure dbo.spLocal_GetMatchedProfileAverage  
@Output_Value  varchar(25) OUTPUT,  
@Var_Id  int,  
@TimeStamp  datetime,  
@Element_Str  varchar(25)  
As  
  
SET NOCOUNT ON  
  
Declare @Calc_Id int,  
 @Element int,  
 @Elements int,  
 @Result1 float,  
 @Result2 float  
  
/* Testing   
Select  @Var_Id  = 7386,  
 @TimeStamp  = '27-Nov-01 18:36:42',  
 @Element_Str  = '2'  
*/  
  
DECLARE @Profile TABLE (  
 Profile_Id  int Identity,  
 Var_Id   int,  
 Result   varchar(25)  
)  
  
/* Initialize */  
If IsNumeric(@Element_Str) = 1  
    Begin  
    Select @Element = convert(int, @Element_Str)  
  
     Insert Into @Profile (Var_Id, Result)  
     Select v.Var_Id, t.Result  
     From [dbo].Variables v  
          Inner Join [dbo].Calculation_Instance_Dependencies cid On cid.Var_Id = v.Var_Id  
          Inner Join [dbo].tests t On t.Var_Id = v.Var_Id   
     Where cid.Result_Var_Id = @Var_Id And t.Result_On = @TimeStamp And t.Result Is Not Null  
     Order By v.Var_Desc Asc  
  
     /* Changed the following to work with only have the 15th element on in the dependencies */  
     Select @Elements = count(Profile_Id) + @Element - 1  
     From @Profile  
  
     If @Element <= (@Elements/2)  
          Begin  
          Select @Result1 = convert(float, Result)  
          From @Profile  
          Where Profile_Id = 1 --@Element  
  
          Select @Result2 = convert(float, Result)  
          From @Profile  
          Where  Profile_Id = @Elements - 2*@Element + 2  
--          Where Profile_Id = @Elements - @Element + 1  
  
          Select @Output_Value = convert(varchar(25), (@Result1+@Result2)/2)  
          End  
     End  
  
-- Drop Table #Profile  
  
SET NOCOUNT OFF  
  
