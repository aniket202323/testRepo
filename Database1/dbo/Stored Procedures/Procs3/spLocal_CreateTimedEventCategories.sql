   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-10-27  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Stored Procedure: spLocal_CreateTimedEventCategories  
Author:   Matthew Wells (MSI)  
Date Created:  11/11/02  
  
Description:  
=========  
This sp looks up the associated categories for the last level of the reason tree and inserts the data   
into the Local_Timed_Event_Categories table for historical purposes (ie. so the data is not lost upon reason tree changes)  
  
Change Date Who What  
=========== ==== =====  
11/11/02 MKW Created.  
*/  
  
CREATE procedure dbo.spLocal_CreateTimedEventCategories  
@OutputValue  varchar(25) OUTPUT,  
@TEDet_Id  int  
As  
  
SET NOCOUNT ON  
  
Declare @PU_Id   int,  
 @Source_PU_Id  int,  
 @Tree_Id   int,  
 @ERTD_Id   int,  
 @Reason_Id1   int,  
 @Reason_Id2   int,  
 @Reason_Id3   int,  
 @Reason_Id4   int  
  
/************************************************************************************************************************************************************************  
*                                                                                    Get Downtime Detail Record Data                                          *  
************************************************************************************************************************************************************************/  
Select  @PU_Id   = PU_Id,  
 @Source_PU_Id = Source_PU_Id,  
 @Reason_Id1  = Reason_Level1,  
 @Reason_Id2  = Reason_Level2,  
 @Reason_Id3  = Reason_Level3,  
 @Reason_Id4  = Reason_Level4  
From [dbo].Timed_Event_Details   
Where TEDet_Id = @TEDet_Id  
  
/************************************************************************************************************************************************************************  
*                                                                               Convert Ids to  Names/Descriptions                                                                                        *  
************************************************************************************************************************************************************************/  
If @Source_PU_Id Is Not Null  
     Begin  
     Select @Tree_Id = Name_Id  
     From [dbo].Prod_Events  
     Where PU_Id = @Source_PU_Id And Event_Type = 2 -- Event_Type = Downtime (as opposed to Waste)  
  
     If @Tree_Id Is Not Null  
          Begin  
          If @Reason_Id1 Is Not Null  
               Begin  
               Select @ERTD_Id = Event_Reason_Tree_Data_Id  
               From [dbo].Event_Reason_Tree_Data  
               Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id1 And Event_Reason_Level = 1 And Parent_Event_R_Tree_Data_Id Is Null  
  
               If @Reason_Id2 Is Not Null  
                    Begin  
                    Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                    From [dbo].Event_Reason_Tree_Data  
                    Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id2 And Event_Reason_Level = 2 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
  
                    If @Reason_Id3 Is Not Null  
                         Begin  
                         Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                         From [dbo].Event_Reason_Tree_Data  
                         Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id3 And Event_Reason_Level = 3 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
  
                         If @Reason_Id4 Is Not Null  
                              Begin  
                              Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                              From [dbo].Event_Reason_Tree_Data  
                              Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @Reason_Id4 And Event_Reason_Level = 4 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
                              End  
                         End  
                    End  
               End  
  
          If @ERTD_Id Is Not Null  
               Begin  
               -- Remove any existing assignments  
               Delete  
               From [dbo].Local_Timed_Event_Categories  
               Where TEDet_Id = @TEDet_Id  
  
               -- Add new categories  
               Insert Into [dbo].Local_Timed_Event_Categories ( TEDet_Id,  
       ERC_Id)  
               Select @TEDet_Id,  
  ERC_Id  
               From [dbo].Event_Reason_Category_Data  
               Where Event_Reason_Tree_Data_Id = @ERTD_Id  
               End  
          End  
     End  
  
/* Cleanup */  
Select @OutputValue = 'DONOTHING'  
  
SET NOCOUNT OFF  
  
