 /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-23  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Created by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
*/  
  
  
CREATE procedure dbo.spLocal_CleanSpeedChanges   
@OutputValue varchar(25) OUTPUT,  
@Child_PU_Id int,  
@Parent_PU_Id int,  
@Reference_End_Time datetime,  
@Prop_Desc varchar(25)  
AS  
SET NOCOUNT ON  
  
Declare @Child_Start_Id  int,  
 @Child_Prod_Id  int,  
 @Child_Speed_Id int,  
 @Child_Start_Time  datetime,  
 @Parent_Start_Id  int,  
 @Parent_Prod_Id  int,  
 @Parent_Start_Time  datetime,    
 @Last_Start_Id  int,  
 @Reference_Time datetime,  
 @Prop_Id  int,  
 @Child_Fetch_Status int,  
 @Parent_Fetch_Status int  
  
DECLARE @ValidSpeeds TABLE(  
 Parent_Prod_Id   int,  
 Child_Prod_Code  varchar(25),  
 Child_Prod_Id   int)  
  
DECLARE @FalseProductChanges TABLE(  
 Start_Id   int,  
 Prod_Id   int,  
 Start_Time   datetime,  
 Prev_Prod_Id  int)  
  
/* Initialization */  
Select @Reference_Time = dateadd(dd, -5, @Reference_End_Time)  
  
Select @Prop_Id = Prop_Id  
From [dbo].Product_Properties  
Where Prop_Desc Like rtrim(ltrim(@Prop_Desc))  
  
/* Testing  
Select @Child_PU_Id = 2169  
Select @Parent_PU_Id = 2  
*/  
  
/* Get the valid speed prod ids */  
Insert Into @ValidSpeeds (Parent_Prod_Id, Child_Prod_Code, Child_Prod_Id)  
Select Parent.Prod_Id, Child.Prod_Code, Child.Prod_Id  
From [dbo].PU_Products   
   Inner Join [dbo].Products As Parent On PU_Products.Prod_Id = Parent.Prod_Id   
       Inner Join [dbo].Characteristic_Groups As Grp On Parent.Prod_Code = Grp.Characteristic_Grp_Desc  
       Inner Join [dbo].Characteristic_Group_Data As Dat On Grp.Characteristic_Grp_Id = Dat.Characteristic_Grp_Id  
       Inner Join [dbo].Characteristics As Chrs On Dat.Char_Id = Chrs.Char_Id  
       Inner Join [dbo].Products As Child On Chrs.Char_Desc = Child.Prod_Code  
Where PU_Products.PU_Id = @Parent_PU_Id And Grp.Prop_Id = @Prop_Id  
  
/* Search product changes */  
Declare ChildProductChanges Cursor For  
Select Production_Starts.Start_Id, Production_Starts.Prod_Id, Production_Starts.Start_Time  
From [dbo].Production_Starts  
Where PU_Id = @Child_PU_Id and Start_Time > @Reference_Time   
Order By Start_Id Desc  
Open ChildProductChanges  
  
Declare ParentProductChanges Cursor For  
Select Start_Id, Prod_Id, Start_Time  
From [dbo].Production_Starts  
Where PU_Id = @Parent_PU_Id and Start_Time > @Reference_Time   
Order By Start_Id Desc  
Open ParentProductChanges  
  
Fetch Next From ChildProductChanges Into @Child_Start_Id, @Child_Speed_Id, @Child_Start_Time  
Select @Child_Fetch_Status = @@FETCH_STATUS  
Fetch Next From ParentProductChanges Into @Parent_Start_Id, @Parent_Prod_Id, @Parent_Start_Time  
Select @Parent_Fetch_Status = @@FETCH_STATUS  
  
While @Child_Fetch_Status = 0 And @Parent_Fetch_Status = 0  
Begin  
     If @Child_Start_Id < @Parent_Start_Id  
     Begin  
          /* Create missing product changes */  
          /* Increment */  
          Fetch Next From ParentProductChanges Into @Parent_Start_Id, @Parent_Prod_Id, @Parent_Start_Time  
          Select @Parent_Fetch_Status = @@FETCH_STATUS  
     End  
     Else  
     Begin  
          Select @Child_Prod_Id = Child_Prod_Id  
          From @ValidSpeeds  
          Where Child_Prod_Id = @Child_Speed_Id And Parent_Prod_Id = @Parent_Prod_Id  
  
          If @Child_Prod_Id Is Null or @Child_Start_Time <> @Parent_Start_Time  
          Begin  
               /* Delete bad product changes */  
               Insert into @FalseProductChanges (Start_Id, Prod_Id, Start_Time)  
               Values (@Child_Start_Id, @Child_Speed_Id, @Child_Start_Time)  
               Select @Last_Start_Id = @Child_Start_Id  
               /* Increment */  
               Fetch Next From ChildProductChanges Into @Child_Start_Id, @Child_Speed_Id, @Child_Start_Time  
               Select @Child_Fetch_Status = @@FETCH_STATUS  
               /* Update previous product id */  
               Update @FalseProductChanges  
               Set Prev_Prod_Id = @Child_Speed_Id  
               Where Start_Id = @Last_Start_Id  
          End  
          Else  
          Begin  
               Fetch Next From ChildProductChanges Into @Child_Start_Id, @Child_Speed_Id, @Child_Start_Time  
               Select @Child_Fetch_Status = @@FETCH_STATUS  
               Fetch Next From ParentProductChanges Into @Parent_Start_Id, @Parent_Prod_Id, @Parent_Start_Time  
               Select @Parent_Fetch_Status = @@FETCH_STATUS  
          End  
     End  
End  
  
/* Issue Product Change deletions */  
Select 3, Start_Id, @Child_PU_Id, Prod_Id, Start_Time, 0 From @FalseProductChanges  
  
/* Return number of records modified */  
Select @OutputValue = convert(varchar(25), Count(Start_Id)) From @FalseProductChanges  
If @OutputValue Is Null  
     Select @OutputValue = '0'  
  
/* Cleanup */  
Close ChildProductChanges  
Close ParentProductChanges  
Deallocate ChildProductChanges  
Deallocate ParentProductChanges  
  
SET NOCOUNT OFF  
  
