Create Procedure dbo.spEMSEC_PutEventConfigInfo 
 	 @PUId 	  	  	  	  	 int,
 	 @ETId 	  	  	  	  	 int,
 	 @CauseTreeId 	  	  	 Int,
 	 @ActionTreeId 	  	  	 int,
 	 @ResearchEnabled 	  	 int,
 	 @Association 	  	  	 Int,
 	 @UserId int
AS
DECLARE @InsertId int
DECLARE @ActionEnabled INt
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEMSEC_PutEventConfigInfo',
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@PUId),'Null') + ','  + 
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@ETId),'Null') + ','  + 
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@CauseTreeId),'Null') + ','  + 
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@ActionTreeId),'Null') + ','  + 
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@ResearchEnabled),'Null') + ','  + 
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@Association),'Null') + ','  + 
 	  	  	  	  	  	 IsNull(Convert(nVarChar(10),@UserId),'Null'), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @InsertId = Scope_Identity()
IF @ActionTreeId Is Null
 	 SELECT @ActionEnabled = 0
ELSE
 	 SELECT @ActionEnabled = 1
IF @Association = 0 or @CauseTreeId iS NULL /* Remove all trees */
BEGIN
 	 DELETE FROM Prod_Events WHERE PU_Id = @PUId AND Event_Type = @ETId
END
ELSE
BEGIN
 	 IF (SELECT Count(*) From Prod_Events Where PU_Id = @PUId and Event_Type = @ETId) = 0
 	 BEGIN
 	  	 INSERT INTO Prod_Events(PU_ID, Name_Id, Event_Type) values (@PUId, @CauseTreeId, @ETId)
 	 END
 	 UPDATE Prod_Events SET Name_Id = @CauseTreeId, Action_Reason_Enabled =@ActionEnabled ,Action_Tree_Id = @ActionTreeId,Research_Enabled = @ResearchEnabled
 	  	 WHERE PU_ID = @PUId AND Event_Type = @ETId
END
IF @ETId = 2
BEGIN
 	 UPDATE Prod_Units SET Timed_Event_Association = @Association WHERE Pu_Id = @PUId
END
ELSE
BEGIN
 	 UPDATE Prod_Units SET Waste_Event_Association = @Association WHERE Pu_Id = @PUId
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0 WHERE Audit_Trail_Id = @InsertId
