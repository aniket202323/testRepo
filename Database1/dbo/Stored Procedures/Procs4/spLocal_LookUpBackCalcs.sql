  /*  
--------------------------------------------------------------------------------------------------------------------------------------------------------------  
Altered by  : Eric Perron, System technologies for industry  
Date   : 2005-11-03  
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
  
CREATE PROCEDURE spLocal_LookUpBackCalcs  
@OutputValue varchar(25) OUTPUT,  
@Pu_Id int,  
@TimeStamp varchar(30),  
@Var_Id int  
AS  
  
SET NOCOUNT ON  
  
Declare @Prop_Id int,  
  @Char_Id varchar(50),  
 @Spec_Id int,  
 @Back_Calc_LookUp varchar(50),  
 @Result varchar(25),  
 @ReasonTreeId Int,  
         @TreeDataId Int,  
         @DowntimeEventType Int,  
 @Source_PU_Id int,  
 @Reason_Level1 int,  
 @Reason_Level2 int,  
 @Reason_Level3 int,  
 @Reason_Level4 int,  
 @User_id   int,  
 @AppVersion   varchar(30)  
   
  
 -- Get the Proficy database version  
 SELECT @AppVersion = App_Version FROM [dbo].[AppVersions] WHERE App_Name = 'Database'   
  
-- user id for the resulset  
SELECT @User_id = User_id   
FROM [dbo].Users  
WHERE username = 'Reliability System'  
  
DECLARE @Timed_Event_Details TABLE(  
 Back_Calc_LookUP varchar(50) NULL,  
 PU_ID int  NULL,  
 PU_Extend_Info varchar(2) NULL,  
 Start_Time datetime NULL ,  
 End_Time datetime NULL ,  
 Source_PU_Id  int NULL ,  
 Reason_Level1  int NULL ,  
 Reason_Level1_Code varchar(25) NULL,  
 Reason_Level1_Result varchar(25) NULL,  
 Reason_Level2  int NULL ,  
 Reason_Level2_Code varchar(25) NULL,  
 Reason_Level2_Result varchar(25) NULL,  
 Reason_Level3  int NULL ,  
 Reason_Level3_Code varchar(25) NULL,  
 Reason_Level3_Result varchar(25) NULL,  
 Reason_Level4  int NULL ,  
 Reason_Level4_Code varchar(25) NULL,  
 Reason_Level4_Result varchar(25) NULL,  
 Prop_Desc Varchar(50) NULL,  
 Prop_Id Int NULL  
 )   
  
-- Create temporary table to store results.  
  
DECLARE @VarUpdates TABLE(  
  Var_Id Int NULL,   
  Var_Desc varchar(50) NULL,  
  PU_Id Int NULL,   
  User_Id Int NULL,   
  Canceled Int NULL,   
  Result Varchar(30) NULL,   
  Result_On Datetime NULL,   
  Trans_Type Int NULL,  
  Prop_Id int NULL,  
  Char_Desc Varchar(50) NULL,  
  Char_Id int NULL,  
  Spec_Id int NULL,  
 Post_Var_Update int DEFAULT 0,  
 SecondUserId  int Null,  
 TransNum    int Null,  
 EventId    int Null,  
 ArrayId    int Null,  
 CommentId   int Null  
)  
  
--Put in values that got passed to me for look up  
  
Insert into @Timed_Event_Details (PU_Id,Start_Time)  
Values(@Pu_Id,@TimeStamp)  
  
--Get the Property Desc from the Extended_Info field in the Variable tables using the Var_Id passed to the procedure.  
  
Update @Timed_Event_Details  
Set Prop_Desc = substring(ltrim(rtrim(v.Extended_Info)),5,50)  
From @Timed_Event_Details u, [dbo].Variables v  
Where @Var_Id = v.Var_Id  
  
--Update the temp table with the Prop_Id returned based on the Property Desc  
  
Update @Timed_Event_Details  
Set Prop_Id = p.Prop_Id  
From @Timed_Event_Details u  
 JOIN [dbo].Product_Properties p ON u.Prop_Desc = p.Prop_Desc  
  
--Update temporary table with End_Time, Source_PU_Id, and Reason Ids  
  
Update @Timed_Event_Details  
Set End_Time = t.End_Time, Source_PU_Id = t.Source_PU_Id,Reason_Level1 = t.Reason_Level1,Reason_Level2 = t.Reason_Level2,Reason_Level3 = t.Reason_Level3,Reason_Level4 = t.Reason_Level4  
From @Timed_Event_Details u  
 JOIN [dbo].Timed_Event_Details t ON u.Pu_Id = t.Pu_Id and u.Start_Time = t.Start_Time  
  
  
--  
-- Get values from temporary table to be used for finding the Reason_Tree_Data_Id which will be used as the Characteristic.  
--  
  
Select @Source_PU_Id = Source_PU_Id, @Reason_Level1 = Reason_Level1, @Reason_Level2 = Reason_Level2, @Reason_Level3 = Reason_Level3, @Reason_Level4 = Reason_Level4  
From @Timed_Event_Details  
Where PU_Id = @PU_Id and Start_Time = @TimeStamp  
  
--  
-- Initialize variables  
--   
Select @DowntimeEventType = 2 -- list event_types table to find more, value of 2 is for Downtime.  
  
--  
-- Get the Reason Tree Id for the passed Product Unit  
--  
Select @ReasonTreeId = Null  
Select @ReasonTreeId = Name_Id  
 From [dbo].Prod_Events  
  Where PU_Id = @Source_PU_Id  
   And Event_Type = @DowntimeEventType  
  
--  
-- Return error message if tree Id is not found  
--  
If (@ReasonTreeId Is Null)  
 Begin  
  Select 'Tree not found for passed PUId'  
  Return  
 End  
  
Select @TreeDataId = Null  
  
  
--  
-- Find the Reason_Tree_Data_Id for Reason Level1. If reason level1 was not passed it returns NULL  
--  
If (@Reason_Level1 Is Null)  
 Select @TreeDataId = Null  
Else  
  
--  
-- If only level 1 was passed  
--  
 If (@Reason_Level2 Is Null)  
  Select @TreeDataId = Event_Reason_Tree_Data_Id  
   From [dbo].Event_Reason_Tree_Data  
    Where Tree_Name_Id = @ReasonTreeId  
     And Event_Reason_Id = @Reason_Level1  
      And Event_Reason_Level = 1  
  Else  
  
--  
-- Levels 1 and 2 were passed  
--  
   If (@Reason_Level3 Is Null)  
    Select @TreeDataId = T2.Event_Reason_Tree_Data_Id  
     From [dbo].Event_Reason_Tree_Data T2  
      Inner Join [dbo].Event_Reason_Tree_Data T1   
       On T2.Parent_Event_R_Tree_Data_Id = T1.Event_Reason_Tree_Data_Id  
       Where T2.Tree_Name_Id = @ReasonTreeId  
        And T2.Event_Reason_Id = @Reason_Level2  
         And T2.Event_Reason_Level = 2  
          And T1.Event_Reason_Id = @Reason_Level1  
    Else   
--  
-- Levels 1, 2 and 3 were passed  
--  
     If (@Reason_Level4 Is Null)  
      Select @TreeDataId = T3.Event_Reason_Tree_Data_Id  
       From [dbo].Event_Reason_Tree_Data T3  
        Inner Join [dbo].Event_Reason_Tree_Data T2  
          On T3.Parent_Event_R_Tree_Data_Id = T2.Event_Reason_Tree_Data_Id  
           Inner Join [dbo].Event_Reason_Tree_Data T1   
            On T2.Parent_Event_R_Tree_Data_Id = T1.Event_Reason_Tree_Data_Id  
             Where T3.Tree_Name_Id = @ReasonTreeId  
              And T3.Event_Reason_Id = @Reason_Level3  
               And T3.Event_Reason_Level = 3  
                And T2.Event_Reason_Id = @Reason_Level2  
                 And T1.Event_Reason_Id = @Reason_Level1  
     Else  
--  
-- All 4 Levels were passed  
--  
      Select @TreeDataId = T4.Event_Reason_Tree_Data_Id  
       From [dbo].Event_Reason_Tree_Data T4  
        Inner Join [dbo].Event_Reason_Tree_Data T3  
         On T4.Parent_Event_R_Tree_Data_Id = T3.Event_Reason_Tree_Data_Id  
          Inner Join [dbo].Event_Reason_Tree_Data T2  
            On T3.Parent_Event_R_Tree_Data_Id = T2.Event_Reason_Tree_Data_Id  
             Inner Join [dbo].Event_Reason_Tree_Data T1   
              On T2.Parent_Event_R_Tree_Data_Id = T1.Event_Reason_Tree_Data_Id  
               Where T4.Tree_Name_Id = @ReasonTreeId  
                And T4.Event_Reason_Id = @Reason_Level4  
                 And T4.Event_Reason_Level = 4  
                  And T3.Event_Reason_Id = @Reason_Level3  
                   And T2.Event_Reason_Id = @Reason_Level2  
                    And T1.Event_Reason_Id = @Reason_Level1   
  
--  
-- Update the temporary table with the Event_Reason_Tree_Data_Id that matches the passed reasons for the tree associated  
-- with the passed PUId  
--  
Update @Timed_Event_Details  
Set Back_Calc_LookUP = @TreeDataId        --PU_Extend_Info + Reason_Level1_Code + Reason_Level2_Code (this code was to build the QW code. - not used)  
  
--Get the Property Id and Back Calc Lookup value (Characteristic) from temporary table.  
  
Select @Prop_Id = Prop_Id From @Timed_Event_Details  
Select @Back_Calc_LookUp = Back_Calc_LookUp From @Timed_Event_Details  
  
--Get the characteristic id based on the property id and Back Calc Lookup (char desc).  
  
Select @Char_Id = Char_id   
From [dbo].Characteristics   
Where Prop_Id = @Prop_Id and Char_Desc = @Back_Calc_LookUp   
  
  
Insert into @VarUpdates(Var_Id,Var_Desc,Pu_Id,User_Id,Canceled,Result_On,Trans_Type,Prop_Id,Char_Id)  
Select v.Var_Id, v.Var_Desc, v.Pu_Id,@User_id,0,@TimeStamp,1,@Prop_Id,@Char_Id  
From [dbo].Calculation_Instance_Dependencies c  
 JOIN [dbo].Variables v on v.var_id = c.Var_Id  
Where c.Result_Var_Id = @Var_Id  
  
Update @VarUpdates   
Set Spec_Id = s.Spec_Id  
From @VarUpdates v  
 JOIN [dbo].Specifications s ON s.Prop_Id = v.Prop_Id and v.Var_Desc = s.Spec_Desc   
  
  
UPDATE @VarUpdates  
SET RESULT = a.Target  
FROM @VarUpdates v  
 JOIN [dbo].Active_Specs a ON a.char_id = v.char_id and a.spec_id = v.spec_id and a.expiration_date is null  
  
  
-- Declare Var_Update INSENSITIVE CURSOR  
--   For (Select Spec_Id,Var_Id From @VarUpdates)  
--   For Read Only  
--   Open Var_Update  
-- Fetch_Loop1:  
--   Fetch Next From Var_Update Into @Spec_Id,@Var_Id  
--   If (@@Fetch_Status = 0)  
--     Begin  
--        Select @Result = Target  
--        From Active_Specs  
--        Where Char_Id = @Char_Id and Spec_Id = @Spec_Id and Expiration_Date is null  
--   
--        Update #VarUPdates  
--        Set Result = @Result  
--        Where Var_Id = @Var_Id  
--      Goto Fetch_Loop1  
--     End  
-- Deallocate Var_Update  
  
Update @VarUpdates  
Set Result  = 'Undefined'  
Where Result is null  
  
If (select count(*) from @VarUpdates) > 0   
Begin  
  
 IF @AppVersion LIKE '4%'  
 BEGIN  
  SELECT 2,  
    Var_Id,   
    PU_Id,   
    User_Id,   
    Canceled,   
    Result,   
    Result_On,   
    Trans_Type,   
    Post_Var_Update,   
    SecondUserId,   
    TransNum,   
    EventId,   
    ArrayId,   
    CommentId  
  From @VarUpdates order by Var_Id  
 END  
ELSE  
 BEGIN  
  Select  ResultSetType = 2,Var_Id,PU_Id,User_Id,Canceled,Result,Result_On = Convert(varchar(30),Result_On, 21),Trans_Type From @VarUpdates order by Var_Id  
 END  
    
End  
  
-- Drop Table #VarUpdates  
-- Drop Table #Timed_Event_Details  
  
SET NOCOUNT OFF  
  
