     /*  
  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Added ORDER BY on all TOP instruction  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_DowntimeByCategory  
Author:   Matthew Wells (MSI)  
Date Created:  11/12/01  
  
Description:  
=========  
This stored procedure takes the Downtime event id and looks up the associated event category for a specified level or, alternatively, for any reason level.  
A category mask can also be defined to restrict the search to a specific category (or category type) when there are multiple categories assigned to the  
same reason.  It returns the duration of the downtime if the category matches.  The downtime is calculated in seconds so a conversion factor is also  
supplied to convert that into other time units.  The conversion factor is divided.  
  
Change Date Who What  
=========== ==== =====  
11/12/01 MKW Creation.  
*/  
  
CREATE procedure dbo.spLocal_DowntimeByCategory  
@Output_Value   varchar(25) OUTPUT, -- Category  
@TEDet_Id    int,   -- a : Timed_Event_Detail id for the associated downtime event  
@Category_Mask  varchar(25),  -- b : Category Mask so can refine which category to look for  
@Category_Level_Str  varchar(25),  
@Conversion_Factor_Str  varchar(25)  
As  
  
SET NOCOUNT ON  
  
/* Testing   
Select  @Category_Mask = 'Test:%',  
 @Category_Level_Str = '3'  
*/  
  
/* Declarations */  
Declare @Location  int,  
 @Tree_Id  int,  
 @Reason_Level1  int,  
 @Reason_Level2  int,  
 @Reason_Level3  int,  
 @Reason_Level4  int,  
 @Reason_Level_Id1  int,  
 @Reason_Level_Id2  int,  
 @Reason_Level_Id3  int,  
 @Reason_Level_Id4  int,  
 @Category  varchar(25),  
 @Category_Level int,  
 @Start_Time  datetime,  
 @End_Time  datetime,  
 @Conversion_Factor float  
  
/* Initialization */  
Select  @Category = Null  
If IsNumeric(@Conversion_Factor_Str) = 1  
     Select @Conversion_Factor = convert(float, @Conversion_Factor_Str)  
Else  
     Select @Conversion_Factor = 1.0  
  
/* Argument verification */  
If LTrim(RTrim(@Category_Mask)) = '' Or @Category_Mask Is Null  
     Select @Category_Mask = '%'  
  
If IsNumeric(@Category_Level_Str) = 1  
     Select @Category_Level = convert(int, @Category_Level_Str)  
Else  
     Select @Category_Level = 0  
  
/* Get reason tree selection */  
Select  @Location = Source_PU_Id,  
 @Reason_Level1 = Reason_Level1,  
 @Reason_Level2 = Reason_Level2,  
 @Reason_Level3 = Reason_Level3,  
 @Reason_Level4 = Reason_Level4,  
 @Start_Time    = Start_Time,  
 @End_Time    = End_Time  
From [dbo].Timed_Event_Details  
Where TEDet_Id = @TEDet_Id  
  
/* Validate reason selection */  
If ((@Category_Level = 1 Or @Category_Level = -1) And @Reason_Level1 Is Not Null) Or  
   ((@Category_Level = 2 Or @Category_Level = -1) And @Reason_Level2 Is Not Null) Or  
   ((@Category_Level = 3 Or @Category_Level = -1) And @Reason_Level3 Is Not Null) Or  
   ((@Category_Level = 4 Or @Category_Level = -1) And @Reason_Level4 Is Not Null)  
     Begin  
     /* Get reason tree id - NOTE: Event_Type of 2 = Downtime */  
     Select @Tree_Id = Name_Id  
     From [dbo].Prod_Events  
     Where PU_Id = @Location And Event_Type = 2  
  
     /* Get Level 1 reason tree branch id */  
     Select @Reason_Level_Id1 = Event_Reason_Tree_Data_Id  
     From [dbo].Event_Reason_Tree_Data  
     Where Tree_Name_Id = @Tree_Id And Event_Reason_Level = 1 And Event_Reason_Id = @Reason_Level1 And Parent_Event_R_Tree_Data_Id Is Null  
  
     /* Get Level 2 reason tree branch id */  
     Select @Reason_Level_Id2 = Event_Reason_Tree_Data_Id  
     From [dbo].Event_Reason_Tree_Data  
     Where Tree_Name_Id = @Tree_Id And Event_Reason_Level = 2 And Event_Reason_Id = @Reason_Level2 And Parent_Event_R_Tree_Data_Id = @Reason_Level_Id1  
  
     /* Get Level 3 reason tree branch id */  
     Select @Reason_Level_Id3 = Event_Reason_Tree_Data_Id  
     From [dbo].Event_Reason_Tree_Data  
     Where Tree_Name_Id = @Tree_Id And Event_Reason_Level = 3 And Event_Reason_Id = @Reason_Level3 And Parent_Event_R_Tree_Data_Id = @Reason_Level_Id2  
  
     /* Get Level 4 reason tree branch id */  
     Select @Reason_Level_Id4 = Event_Reason_Tree_Data_Id  
     From [dbo].Event_Reason_Tree_Data  
     Where Tree_Name_Id = @Tree_Id And Event_Reason_Level = 4 And Event_Reason_Id = @Reason_Level4 And Parent_Event_R_Tree_Data_Id = @Reason_Level_Id3  
  
     If @Category_Level = 1 Or @Category_Level = -1  
          Select TOP 1 @Category = ERC_Desc  
          From [dbo].Event_Reason_Catagories erc  
               Inner Join [dbo].Event_Reason_Category_Data ercd On erc.ERC_Id = ercd.ERC_Id  
          Where ercd.Event_Reason_Tree_Data_Id = @Reason_Level_Id1 And erc.ERC_Desc Like @Category_Mask  
   ORDER BY erc.ERC_Id  
  
     If @Category_Level = 2 Or (@Category_Level = -1 And @Category Is Null)  
          Select TOP 1 @Category = ERC_Desc  
          From [dbo].Event_Reason_Catagories erc  
               Inner Join [dbo].Event_Reason_Category_Data ercd On erc.ERC_Id = ercd.ERC_Id  
          Where ercd.Event_Reason_Tree_Data_Id = @Reason_Level_Id2 And erc.ERC_Desc Like @Category_Mask  
   ORDER BY erc.ERC_Id  
  
     If @Category_Level = 3 Or (@Category_Level = -1 And @Category Is Null)  
          Select TOP 1 @Category = ERC_Desc  
          From [dbo].Event_Reason_Catagories erc  
               Inner Join [dbo].Event_Reason_Category_Data ercd On erc.ERC_Id = ercd.ERC_Id  
          Where ercd.Event_Reason_Tree_Data_Id = @Reason_Level_Id3 And erc.ERC_Desc Like @Category_Mask  
   ORDER BY erc.ERC_Id  
  
     If @Category_Level = 4 Or (@Category_Level = -1 And @Category Is Null)  
          Select TOP 1 @Category = ERC_Desc  
          From [dbo].Event_Reason_Catagories erc  
               Inner Join [dbo].Event_Reason_Category_Data ercd On erc.ERC_Id = ercd.ERC_Id  
          Where ercd.Event_Reason_Tree_Data_Id = @Reason_Level_Id4 And erc.ERC_Desc Like @Category_Mask  
   ORDER BY erc.ERC_Id  
  
     If @Category Is Not Null  
          Select @Output_Value = convert(varchar(25), Datediff(s, @Start_Time, @End_Time)/@Conversion_Factor)  
     Else  
          Select @Output_Value = '0'  
  
     End  
Else  
    Select @Output_Value = '0'  
  
SET NOCOUNT OFF  
  
