CREATE PROCEDURE dbo.spEM_IEFindERTDataId(
@TreeName nVarChar(100),
@Reason1 nVarChar(100),
@Reason2 nVarChar(100),
@Reason3 nVarChar(100),
@Reason4 nVarChar(100),
@R1Id Int Output,
@R2Id Int Output,
@R3Id Int Output,
@R4Id Int Output,
@TreeId 	 Int Output,
@ErtDataId Int Output)
AS
SELECT 
 	  	 @R1Id = Null,
 	  	 @R2Id = Null,
 	  	 @R3Id = Null,
 	  	 @R4Id = Null,
 	  	 @TreeId 	 = Null,
 	  	 @ErtDataId = Null
IF @TreeName Is Not Null
 	  	 SELECT @TreeId = a.Tree_Name_Id
 	  	  	 FROM Event_Reason_Tree a
 	  	  	 WHERE a.Tree_Name = @TreeName
IF @TreeId IS Not NULL
BEGIN
 	 IF @Reason1 Is Null
 	 BEGIN
 	  	 RETURN 
 	 END
 	 SELECT @R1Id = a.Event_Reason_Id
 	  	 FROM Event_Reasons a
 	  	 WHERE a.Event_Reason_Name = @Reason1
 	 IF @Reason2 Is Null
 	 BEGIN
 	  	 SELECT @ErtDataId = a.Event_Reason_Tree_Data_Id 
 	  	 FROM Event_Reason_Tree_Data a
 	  	 WHERE a.Level1_Id = @R1Id and a.Level2_Id Is Null and a.Tree_Name_Id = @TreeId
 	  	 RETURN 
 	 END
 	 SELECT @R2Id = a.Event_Reason_Id
 	  	 FROM Event_Reasons a
 	  	 WHERE a.Event_Reason_Name = @Reason2
 	 IF @Reason3 Is Null
 	 BEGIN
 	  	 SELECT @ErtDataId = a.Event_Reason_Tree_Data_Id 
 	  	 FROM Event_Reason_Tree_Data a
 	  	 WHERE a.Level1_Id = @R1Id and a.Level2_Id = @R2Id  And a.Level3_Id Is Null and a.Tree_Name_Id = @TreeId
 	  	 RETURN 
 	 END
 	 SELECT @R3Id = a.Event_Reason_Id
 	  	 FROM Event_Reasons a
 	  	 WHERE a.Event_Reason_Name = @Reason3
 	 IF @Reason4 Is Null
 	 BEGIN
 	  	 SELECT @ErtDataId = a.Event_Reason_Tree_Data_Id 
 	  	 FROM Event_Reason_Tree_Data a
 	  	 WHERE a.Level1_Id = @R1Id and a.Level2_Id = @R2Id  And a.Level3_Id = @R3Id  And a.Level4_Id Is Null and a.Tree_Name_Id = @TreeId
 	  	 RETURN 
 	 END
 	 SELECT @R4Id = a.Event_Reason_Id
 	  	 FROM Event_Reasons a
 	  	 WHERE a.Event_Reason_Name = @Reason4
 	 SELECT @ErtDataId = a.Event_Reason_Tree_Data_Id 
 	  	 FROM Event_Reason_Tree_Data a
 	  	 WHERE a.Level1_Id = @R1Id and a.Level2_Id = @R2Id  And a.Level3_Id = @R3Id  And  a.Level4_Id = @R4Id and a.Tree_Name_Id = @TreeId
END
