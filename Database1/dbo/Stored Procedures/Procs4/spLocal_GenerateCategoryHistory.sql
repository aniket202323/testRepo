   /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Peron, System technologies for industry  
Date   : 2005-11-01  
Version  : 1.0.1  
Purpose  : Redesign of SP (Compliant with Proficy 3 and 4).  
     Added [dbo] template when referencing objects.  
     Replace temp table for table variable   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
Altered by  : ?  
Date   : ?  
Version  : 1.0.0  
Purpose  : ?   
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
  
*/  
CREATE PROCEDURE dbo.spLocal_GenerateCategoryHistory  
  
@InputMasterProdUnitPrefix nVarChar(4000)=null  
  
As  
  
SET NOCOUNT ON  
  
Declare @@PUID   INT,   
 @@SourcePUID INT,   
 @@tedet_id INT,    
 @@ReasonID1     INT,    
 @@ReasonID2 INT,   
 @@ReasonID3 INT,   
 @@ReasonID4 INT,  
 @Tree_Id INT,  
 @ERTD_Id        INT,  
 @NumEvents  INT,  
 @EventCounter INT  
  
DECLARE @DownTime TABLE(   
 PUID  INT,  
 SourcePUID INT,  
 tedet_id INT,  
 ReasonID1 INT,  
 ReasonID2 INT,  
 ReasonID3 INT,  
 ReasonID4 INT)  
  
Insert into @DownTime (PUID,SourcePUID,tedet_id, ReasonID1, ReasonID2, ReasonID3, ReasonID4)  
select ted.pu_ID, ted.Source_PU_ID, ted.tedet_id, ted.reason_level1, ted.reason_level2, ted.reason_level3, ted.reason_level4  
FROM [dbo].timed_event_details AS ted   
inner join [dbo].prod_units as pu2 on (pu2.pu_id = ted.pu_id)  
Where pu2.pu_desc like @InputMasterProdUnitPrefix +'%'  
  
set @NumEvents = (select  Count(*) from @downtime)  
  
DECLARE recSCursor INSENSITIVE CURSOR FOR  
 (SELECT SourcePUID, tedet_id,  ReasonID1,  ReasonID2, ReasonID3, ReasonID4  
  FROM @downtime)  
  FOR READ ONLY  
OPEN recSCursor  
FETCH NEXT FROM recSCursor INTO @@SourcePUID, @@tedet_id,  @@ReasonID1,  @@ReasonID2, @@ReasonID3, @@ReasonID4  
WHILE @@Fetch_Status = 0  
begin  
  
If @@SourcePUID Is Not Null  
     Begin  
     Select @Tree_Id = Name_Id  
     From [dbo].Prod_Events  
     Where PU_Id = @@SourcePUID And Event_Type = 2 -- Event_Type = Downtime (as opposed to Waste)  
  
     If @Tree_Id Is Not Null  
          Begin  
          If @@ReasonID1 Is Not Null  
               Begin  
               Select @ERTD_Id = Event_Reason_Tree_Data_Id  
               From [dbo].Event_Reason_Tree_Data  
               Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @@ReasonID1 And Event_Reason_Level = 1 And Parent_Event_R_Tree_Data_Id Is Null  
  
               If @@ReasonID2 Is Not Null  
                    Begin  
                    Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                    From [dbo].Event_Reason_Tree_Data  
                    Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @@ReasonID2 And Event_Reason_Level = 2 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
  
                    If @@ReasonID3 Is Not Null  
                         Begin  
                         Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                         From [dbo].Event_Reason_Tree_Data  
                         Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @@ReasonID3 And Event_Reason_Level = 3 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
  
                         If @@ReasonID4 Is Not Null  
                              Begin  
                              Select @ERTD_Id = Event_Reason_Tree_Data_Id  
                              From [dbo].Event_Reason_Tree_Data  
                              Where Tree_Name_Id = @Tree_Id And Event_Reason_Id = @@ReasonID4 And Event_Reason_Level = 4 And Parent_Event_R_Tree_Data_Id = @ERTD_Id  
                              End  
                         End  
                    End  
               End  
  
          If @ERTD_Id Is Not Null  
               Begin  
               -- Remove any existing assignments  
               Delete  
              From [dbo].Local_Timed_Event_Categories  
               Where TEDet_Id = @@tedet_id  
  
               -- Add new categories  
               Insert Into [dbo].Local_Timed_Event_Categories (TEDet_Id,ERC_Id)  
               Select @@tedet_id,  
        ERC_Id  
               From [dbo].Event_Reason_Category_Data  
               Where Event_Reason_Tree_Data_Id = @ERTD_Id  
               End  
          End  
     End  
  
  
 FETCH NEXT FROM recSCursor INTO @@SourcePUID, @@tedet_id,  @@ReasonID1,  @@ReasonID2, @@ReasonID3, @@ReasonID4  
End  
  
  
deallocate recSCursor  
-- drop table #downtime  
  
SET NOCOUNT OFF  
  
