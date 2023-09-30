   /*  
Stored Procedure: spLocal_SetGrade  
Author:   Matthew Wells (MSI)  
Date Created:  08/01/01  
  
Description:  
=========  
Cascades the product currently running on the source production unit to all specified sub-units.  
  
Change Date Who What  
=========== ==== =====  
11/05/01 MKW Added comment.  
02/01/02 MKW Overhauled routine to allow for updates and cleanup.  
02/21/02 MKW Excluded the <Null> product (Prod_Id = 1)  
04/23/02 PAP Added 2 inputs for Converting -- additional Master PUid  
05/05/06 EP  Put the last 2 parameters optionnal  
*/  
  
  
CREATE procedure dbo.spLocal_SetGrade  
@Output_Value   varchar(25) OUTPUT,  
@Parent_PU_Id  int,  
@Parent_Start_Time  datetime,  
@Child_PU_Id1   int,  
@Child_PU_Id2   int,  
@Child_PU_Id3  int,  
@Child_PU_Id4   int,  
@Child_PU_Id5   int,  
@Child_PU_Id6   int,  
@Child_PU_Id7   int,  
@Child_PU_Id8   int,  
@Child_PU_Id9   int,  
@Child_PU_Id10  int = 0,  
@Child_PU_Id11  int = 0  
AS  
  
/*  
Select  @Parent_PU_Id   = 8,  
 @Parent_Start_Time  = '2002-02-01 09:45:00.000',  
 @Child_PU_Id1   = 2,  
 @Child_PU_Id2   = 5,  
 @Child_PU_Id3   = 6,  
 @Child_PU_Id4   = 12  
*/  
  
Declare @Start_Id    int,  
 @Parent_Prod_Id   int,  
 @Child_PU_Id   int,  
 @Child_Prod_Id   int,  
 @Count    int,  
 @Max_Count   int,  
 @Last_Parent_Prod_Id  int,  
 @Last_Parent_Start_Time datetime,  
 @Next_Parent_Start_Time datetime,  
 @Valid_Prod_Id   int  
  
DECLARE @ProductChanges TABLE(  
-- Create Table #ProductChanges (  
 Result_Set_Type int Default 3,  
 Start_Id   int Null,  
 PU_Id   int Null,  
 Prod_Id   int Null,  
 Start_Time   datetime Null,  
 Post_Update  int Default 0)  
  
-- DECLARE @Tests TABLE(  
-- --Create Table #Tests (  
--  Result_Set_Type int Default 2,  
--  Var_Id   int Null,  
--  PU_Id   int Null,  
--  User_Id      int Default 1,  
--  Canceled  int Default 0,  
--  Result         varchar(30) Null,  
--  Result_On  datetime Null,  
--  Transaction_Type int Default 1,  
--  Post_Update  int Default 0  
-- )  
  
/* Initialization */  
Select  @Max_Count = 12,  
 @Count = 1  
  
Select @Parent_Prod_Id = Prod_Id  
From [dbo].Production_Starts  
Where PU_Id = @Parent_PU_Id And Start_Time = @Parent_Start_Time  
  
If @Parent_Prod_Id Is Not Null And @Parent_Prod_Id > 1  
     Begin  
     While @Count < @Max_Count  
          Begin  
          /* Initialization */  
          Select @Child_PU_Id = Case @Count  
                                 When 1 Then @Child_PU_Id1  
                                 When 2 Then @Child_PU_Id2  
                                 When 3 Then @Child_PU_Id3  
                                 When 4 Then @Child_PU_Id4  
                                 When 5 Then @Child_PU_Id5  
                                 When 6 Then @Child_PU_Id6  
                                 When 7 Then @Child_PU_Id7  
                                 When 8 Then @Child_PU_Id8  
                                 When 9 Then @Child_PU_Id9  
               When 10 Then @Child_PU_Id10  
               When 11 Then @Child_PU_Id11  
                                 End  
          Select @Valid_Prod_Id = Null  
  
          If @Child_PU_Id Is Null  
               Break  
  
          /* Get last Product Change on the Parent and then get the next one (if available) as well */  
          Select TOP 1 @Last_Parent_Start_Time = Start_Time, @Last_Parent_Prod_Id = Prod_Id  
          From [dbo].Production_Starts  
          Where PU_Id = @Parent_PU_Id And Start_Time < @Parent_Start_Time  
          Order By Start_Time Desc  
       
          Select TOP 1 @Next_Parent_Start_Time = Start_Time  
          From [dbo].Production_Starts  
          Where PU_Id = @Parent_PU_Id And Start_Time > @Parent_Start_Time  
          Order By Start_Time Asc  
  
          /* Delete any invalid product changes during that time period */  
          Insert Into @ProductChanges (Start_Id, PU_Id, Prod_Id, Start_Time)  
          Select Start_Id, PU_Id, @Last_Parent_Prod_Id, Start_Time  
          From [dbo].Production_Starts  
          Where PU_Id = @Child_PU_Id And Start_Time > @Last_Parent_Start_TIme And   
                (Start_Time < @Next_Parent_Start_Time Or @Next_Parent_Start_Time Is Null) And Start_Time <> @Parent_Start_Time   
          Order By Start_Time Asc  
       
          /* Verify that product is available on the child unit */  
          Select @Valid_Prod_Id = Prod_Id  
          From [dbo].PU_Products  
          Where PU_Id = @Child_PU_Id  
  
          /* Create new product change */  
          If @Valid_Prod_Id Is Not Null  
               Insert Into @ProductChanges (PU_Id, Prod_Id, Start_Time)  
               Values (@Child_PU_Id, @Parent_Prod_Id, @Parent_Start_Time)  
  
          /* Increment counter */  
          Select @Count = @Count + 1  
          End  
     End  
  
Select @Output_Value = convert(varchar(25), @Parent_Prod_Id)  
  
If (Select Count(Result_Set_Type) From @ProductChanges) > 0  
     Select Result_Set_Type,  
    Start_Id,  
    PU_Id,  
    Prod_Id,  
    Start_Time,  
    Post_Update   
  From @ProductChanges  
  
--If Select Count(Result_Set_Type) From #ProductChanges > 0  
--     Select * From #Tests  
  
-- Drop Table #ProductChanges  
-- Drop Table #Tests  
  
  
  
  
  
  
