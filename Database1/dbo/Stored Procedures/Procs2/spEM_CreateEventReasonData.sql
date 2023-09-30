CREATE PROCEDURE dbo.spEM_CreateEventReasonData
  @TreeName_Id    int,
  @EventReason_Id           int,
  @ParentEventRData_Id      int,
  @EventReasonLevel         int,
  @User_Id int,
  @EventReasonData_Id       int OUTPUT
  AS
  --
  -- Return Codes:
  --
  --   0 = Success
  --   1 = Unable to create product group data.
  --
DECLARE @ParentEventReason_Id int,
 	     @ReasonCheck int,
        @Insert_Id  	 Int,
 	  	 @L1 	  	  	 Int,
 	  	 @L2 	  	  	 Int,
 	  	 @L3 	  	  	 Int,
 	  	 @L4 	  	  	 Int,
 	  	 @SiblingForCategory Int,
 	  	 @PPFrom 	  	  	  	 INT
Insert into Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@User_Id,'spEM_CreateEventReasonData',
                 convert(nVarChar(10),@TreeName_Id) + ','  + Convert(nVarChar(10),  @EventReason_Id) + ','  +  convert(nVarChar(10),@ParentEventRData_Id) + ','  + Convert(nVarChar(10), @EventReasonLevel) +  ','  + Convert(nVarChar(10), @User_Id),
                dbo.fnServer_CmnGetDate(getUTCdate()))
select @Insert_Id = Scope_Identity()
IF @EventReasonLevel > 4 
 	 BEGIN
 	      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1,Output_Parameters = convert(nVarChar(10),@EventReasonData_Id)  where Audit_Trail_Id = @Insert_Id
 	      RETURN (1)
 	 END
If @ParentEventRData_Id is not null
 	 BEGIN
 	      SELECT @ParentEventReason_Id  = Event_Reason_Id,@L1 = Level1_Id,@L2 = Level2_Id,@L3 = Level3_Id FROM Event_Reason_Tree_Data WHERE Event_Reason_Tree_Data_Id = @ParentEventRData_Id
 	      SELECT @ReasonCheck = Event_Reason_Tree_Data_Id
 	         FROM Event_Reason_Tree_Data
 	        WHERE  Tree_Name_Id = @TreeName_Id AND 	 
 	  	 Event_Reason_Id = @EventReason_Id AND
 	  	 Parent_Event_R_Tree_Data_Id = @ParentEventRData_Id
  	 END
ELSE
 	 BEGIN
 	      SELECT @ReasonCheck = Event_Reason_Tree_Data_Id
 	         FROM Event_Reason_Tree_Data
 	        WHERE  Tree_Name_Id = @TreeName_Id AND 	 
 	  	 Event_Reason_Id = @EventReason_Id AND
 	  	 Parent_Event_R_Tree_Data_Id is null
 	 END
IF @ReasonCheck IS NOT NULL  
 	 BEGIN
 	      -- Branch already exists!!!
  	      SELECT @EventReasonData_Id = @ReasonCheck
 	      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1,Output_Parameters = convert(nVarChar(10),@EventReasonData_Id)  where Audit_Trail_Id = @Insert_Id
 	      RETURN (1)
 	 END 
If @EventReasonLevel = 1
  Select @L1 = @EventReason_Id
Else If @EventReasonLevel = 2
  Select @L2 = @EventReason_Id
Else If @EventReasonLevel = 3
  Select @L3 = @EventReason_Id
Else
  Select @L4 = @EventReason_Id
IF @ParentEventRData_Id IS NOT NULL
BEGIN
 	 IF EXISTS(SELECT  Parent_Event_R_Tree_Data_Id FROM Event_Reason_Tree_Data WHERE Parent_Event_R_Tree_Data_Id = @ParentEventRData_Id)
 	 BEGIN
 	  	 SELECT @SiblingForCategory = MIN( Event_Reason_Tree_Data_Id)
 	  	  	 FROM Event_Reason_Tree_Data 
 	  	  	 WHERE Parent_Event_R_Tree_Data_Id = @ParentEventRData_Id
 	 END
 	 ELSE
 	 BEGIN
 	  	 SELECT @PPFrom = @ParentEventRData_Id
 	  	 SELECT @SiblingForCategory =  @ParentEventRData_Id --First node @ this level
 	 END
END
ELSE
 	 SELECT @SiblingForCategory = MIN(Event_Reason_Tree_Data_Id)
 	  	 FROM Event_Reason_Tree_Data 
 	  	 WHERE Parent_Event_R_Tree_Data_Id IS NULL AND Tree_Name_Id = @TreeName_Id
 BEGIN TRANSACTION
  Update Event_Reason_Tree_Data set Bottom_Of_Tree = 0 Where Event_Reason_Tree_Data_Id = @ParentEventRData_Id
  INSERT Event_Reason_Tree_Data (Tree_Name_Id,Event_Reason_Id, Parent_Event_Reason_Id,Event_Reason_Level,Parent_Event_R_Tree_Data_Id,Level1_id,Level2_id,Level3_id,Level4_id,Bottom_Of_Tree)
       VALUES(@TreeName_Id, @EventReason_Id, @ParentEventReason_Id, @EventReasonLevel,@ParentEventRData_Id,@L1,@L2,@L3,@L4,1)
  SELECT @EventReasonData_Id = Scope_Identity()
  IF @EventReasonData_Id IS NULL
    BEGIN
      ROLLBACK TRANSACTION
      Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 1,Output_Parameters = convert(nVarChar(10),@EventReasonData_Id)  where Audit_Trail_Id = @Insert_Id
      RETURN(1)
    END
  IF @SiblingForCategory IS NOT NULL
  BEGIN
 	 INSERT INTO Event_Reason_Category_Data(ERC_Id,Event_Reason_Tree_Data_Id,Propegated_From_ETDId)
 	  	 SELECT ERC_Id,@EventReasonData_Id,Propegated_From_ETDId
 	  	  	 FROM Event_Reason_Category_Data
 	  	  	 WHERE Event_Reason_Tree_Data_Id = @SiblingForCategory and Propegated_From_ETDId Is Not NULL
 	 IF @PPFrom IS NOT NULL
 	  	 INSERT INTO Event_Reason_Category_Data(ERC_Id,Event_Reason_Tree_Data_Id,Propegated_From_ETDId)
 	  	  	 SELECT ERC_Id,@EventReasonData_Id,@PPFrom
 	  	  	  	 FROM Event_Reason_Category_Data
 	  	  	  	 WHERE Event_Reason_Tree_Data_Id = @SiblingForCategory and Propegated_From_ETDId Is NULL
  END
  COMMIT TRANSACTION
  Update  Audit_Trail set EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),returncode = 0,Output_Parameters = convert(nVarChar(10),@EventReasonData_Id) where Audit_Trail_Id = @Insert_Id
  RETURN(0)
