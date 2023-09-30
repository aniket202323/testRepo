CREATE PROCEDURE dbo.spEM_IEImportReasonCategory
 	 @TreeName 	 nVarChar(100),
 	 @Level1 	  	 nVarChar(100),
 	 @Level2 	  	 nVarChar(100),
 	 @Level3 	  	 nVarChar(100),
 	 @Level4 	  	 nVarChar(100),
 	 @Category 	 nvarchar(50),
 	 @User_Id 	 Int
As
Declare @ERCD_Id 	 int,
 	  	 @ERTD_Id 	 int,
 	  	 @ERC_Id 	  	 int,
 	  	 @iLevel1 	 Int,
 	  	 @iLevel2 	 Int,
 	  	 @iLevel3 	 Int,
 	  	 @iLevel4 	 Int,
 	  	 @iTreeId 	 Int,
 	  	 @LevelCount Int
Select @TreeName = LTrim(RTrim(@TreeName))
Select @Level1 = LTrim(RTrim(@Level1))
Select @Level2 = LTrim(RTrim(@Level2))
Select @Level3 = LTrim(RTrim(@Level3))
Select @Level4 = LTrim(RTrim(@Level4))
Select @Category = LTrim(RTrim(@Category))
Select @iTreeId = Null
Select @iTreeId = Tree_Name_Id From Event_Reason_Tree Where Tree_Name = @TreeName
If @iTreeId is null
  Begin
 	 Select 'Failed - Could not find reason tree.'
 	 Return (-100)
  End
Select @LevelCount = 1
Select @iLevel1 = Null
Select @iLevel1 = Event_Reason_Id From Event_Reasons Where Event_Reason_Name = @Level1
If @iLevel1 is null
 	 Begin
 	   Select 'Failed - Could not find reason level 1.'
 	   Return (-100)
    End
Select @iLevel2 = Null
If @Level2 is not null and @Level2 <> ''
  Begin
 	 Select @LevelCount = 2
 	 Select @iLevel2 = Event_Reason_Id From Event_Reasons Where Event_Reason_Name = @Level2
 	 If @iLevel2 is null
 	   Begin
 	  	 Select 'Failed - Could not find reason level 2.'
 	  	 Return (-100)
 	   End
 	 Select @iLevel3 = Null
 	 If @Level3 is not null and @Level3 <> ''
 	   Begin
 	  	 Select @LevelCount = 3
 	  	 Select @iLevel3 = Event_Reason_Id From Event_Reasons Where Event_Reason_Name = @Level3
 	  	 If @iLevel3 is null
 	  	   Begin
 	  	  	 Select 'Failed - Could not find reason level 3.'
 	  	  	 Return (-100)
 	  	   End
 	  	 Select @iLevel4 = Null
 	  	 If @Level4 is not null and @Level4 <> ''
 	  	   Begin
 	  	  	 Select @LevelCount = 4
 	  	  	 Select @iLevel4 = Event_Reason_Id From Event_Reasons Where Event_Reason_Name = @Level4
 	  	  	 If @iLevel4 is null
 	  	  	   Begin
 	  	  	  	 Select 'Failed - Could not find reason level 4.'
 	  	  	  	 Return (-100)
 	  	  	   End
 	  	   End
 	   End
  End
Select @ERC_Id = Null
Select @ERC_Id = ERC_Id From Event_Reason_Catagories Where ERC_Desc = @Category
If @ERC_Id Is Null
  Begin
 	 Execute spEM_CreateReasonCategory  @Category,@User_Id,@ERC_Id  OUTPUT
 	 If @ERC_Id Is Null 
 	   Begin
 	  	 Select 'Failed - Could not create category.'
 	  	 Return (-100)
 	   End
  End
Select @ERTD_Id = Null
Select @ERTD_Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
  Where Tree_Name_Id = @iTreeId and Event_Reason_Level = 1 And Event_Reason_Id = @iLevel1
If @LevelCount > 1
 Select @ERTD_Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
  Where Tree_Name_Id = @iTreeId and Event_Reason_Level = 2 And Event_Reason_Id = @iLevel2 And Parent_Event_R_Tree_Data_Id = @ERTD_Id
If @LevelCount > 2
 Select @ERTD_Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
  Where Tree_Name_Id = @iTreeId and Event_Reason_Level = 3 And Event_Reason_Id = @iLevel3 And Parent_Event_R_Tree_Data_Id = @ERTD_Id
If @LevelCount > 3
 Select @ERTD_Id = Event_Reason_Tree_Data_Id From Event_Reason_Tree_Data
  Where Tree_Name_Id = @iTreeId and Event_Reason_Level = 4 And Event_Reason_Id = @iLevel4 And Parent_Event_R_Tree_Data_Id = @ERTD_Id
If @ERTD_Id is null 
  Begin
 	 Select 'Failed - Branch not found'
 	 Return (-100)
  End
Select @ERCD_Id = Null
Select @ERCD_Id = ERCD_Id From Event_Reason_Category_Data
 	 Where ERC_Id = @ERC_Id and Event_Reason_Tree_Data_Id = @ERTD_Id
If @ERCD_Id is not null
  Begin
 	 Select 'Failed - Category already exists'
 	 Return (-100)
  End
Execute spEM_CreateCategoryMember @ERTD_Id,@ERC_Id,@User_Id,@ERCD_Id output
If @ERCD_Id is null
  Begin
 	 Select 'Failed - unable to link category'
 	 Return (-100)
  End
RETURN(0)
