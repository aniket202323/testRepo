CREATE PROCEDURE dbo.spSDK_IncomingVariable
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @VariableName 	  	  	 nvarchar(50),
 	 @CharacteristicName 	 nvarchar(50),
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @TimeStamp 	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	  	 INT,
 	 @Result 	  	  	  	  	 nvarchar(25),
 	 -- Input/Output Parameters
 	 @SignoffUserId  	  	 INT OUTPUT,
 	 @ApproverUserId  	  	 INT OUTPUT,
    @ESignatureId           INT OUTPUT,
 	 @TransNum  	  	  	  	 INT OUTPUT,
 	 @TestId 	  	  	  	  	 BigInt OUTPUT,
 	 -- Output Parameters
 	 @VariableId 	  	  	  	 INT OUTPUT,
 	 @PUId 	  	  	  	  	  	 INT OUTPUT,
 	 @CommentId 	  	  	  	 INT OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Unit Not Found
-- 3 - Variable Not Found
-- 4 - Access Denied To Variable
-- 5 - Line Not Found
-- 6 - Direct Write Failed
-- 7 - Approver User Name Not Found
DECLARE 	 @Temp 	  	  	  	 INT,
 	  	  	 @GroupId 	  	  	 INT,
 	  	  	 @AccessLevel 	 INT,
 	  	  	 @PLId 	  	  	  	  	 INT,
 	  	  	 @ESignatureLevel INT,
      @Prod_Id INT
--Lookup Variable
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id 
 	 FROM 	 Prod_Lines (nolock)
 	 WHERE 	 PL_Desc = @LineName
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
IF @PLId IS NULL RETURN(5)
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id 
 	 FROM 	 Prod_Units (nolock)
 	 WHERE 	 PU_Desc = @UnitName AND
 	  	  	 PL_Id = @PLId
IF @PUId IS NULL RETURN(2)
SELECT 	 @VariableId = NULL
SELECT 	 @VariableId = Var_Id 
 	 FROM 	 Variables (nolock)
 	 WHERE Var_Desc = @VariableName AND 
 	  	  	 PU_Id = @PUId 
IF @VariableId IS NULL RETURN(3)
IF @TestId IS NULL OR @TestId = 0
BEGIN
 	 SELECT 	 @TestId = NULL
 	 SELECT 	 @TestId = Test_Id,
 	  	  	  	 @CommentId = Comment_Id
 	  	 FROM 	 Tests (nolock)
 	  	 WHERE 	 Var_Id = @VariableId AND
 	  	  	  	 Result_On = @Timestamp
END ELSE
BEGIN
 	 SELECT 	 @CommentId = Comment_Id
 	  	 FROM 	 Tests (nolock)
 	  	 WHERE 	 Test_Id = @TestId
END
--If There Is No Security Group Attached, Bail With Success
IF @GroupId IS NOT NULL 
BEGIN
 	 --Check Security Group
 	 SELECT 	 @AccessLevel = NULL
 	 SELECT 	 @AccessLevel = MAX(Access_Level)
 	  	 FROM 	 User_Security (nolock)
 	  	 WHERE User_id = @UserId AND 
 	  	  	  	 Group_id = @GroupId
 	 
 	 IF @AccessLevel IS NULL RETURN(4)
 	 
 	 IF @AccessLevel < 2 RETURN(4)
END
Select @Prod_Id = NULL 
Select @Prod_Id = Prod_id 
  From Production_starts (nolock)
  Where PU_Id = @PUId and Start_Time <= @TimeStamp and (End_time IS NULL or End_time > @Timestamp)
Select @ESignatureLevel = 0
Select @ESignatureLevel = Coalesce(Esignature_Level, 0)
 	 From Var_Specs (nolock)
 	 Where Var_Id = @VariableId
  AND Prod_Id = @Prod_Id
 	 And ((Effective_Date <= @TimeStamp) And ((Expiration_Date is NULL) OR (Expiration_Date > @Timestamp)))
IF @ESignatureLevel = 0
 	 BEGIN
 	  	 Select @ESignatureLevel = Coalesce(Esignature_Level, 0)
 	  	  	 From Variables  (nolock)
 	  	  	 Where Var_Id = @VariableId
 	 END
IF @ESignatureLevel = 2 and (@ESignatureId is NULL or @ESignatureId = 0)
 	 BEGIN
 	  	 IF ((@TestId = 0 or @TestId is NULL) OR (@TestId > 0 AND @TransNum <> 4 AND @TransNum <> 5)) AND (@SignoffUserId <= 0 OR @SignoffUserId IS NULL) RETURN(7) 	 
 	  	 IF @TestId > 0 AND (@ApproverUserId <= 0 OR @ApproverUserId IS NULL) RETURN(8)
 	 END
ELSE IF @ESignatureLevel = 1 and (@ESignatureId is NULL or @ESignatureId = 0)
 	 BEGIN
 	  	 IF @SignoffUserId <= 0 OR @SignoffUserId IS NULL RETURN(7)
 	 END
IF @TestId = 0 OR @TestId IS NULL
 	 BEGIN
 	  	 SELECT @ApproverUserId = NULL
 	 END
ELSE
 	 BEGIN
 	  	 IF @TransNum = 0 	 --UPDATE
 	  	  	 BEGIN
 	  	  	  	 SELECT @ApproverUserId = Second_User_Id
 	  	  	  	  	 FROM 	 Tests  (nolock)
 	  	  	  	  	 WHERE 	 Test_Id = @TestId
 	  	  	  	 SELECT @TransNum = 0
 	  	  	 END
 	  	 ELSE IF @TransNum = 4 	 --APPROVE
 	  	  	 BEGIN
 	  	  	  	 IF @ApproverUserId IS NULL RETURN(8)
 	  	  	 END
 	  	 ELSE IF @TransNum = 5 	 --UNAPPROVE
 	  	  	 BEGIN
 	  	  	  	 IF @ApproverUserId IS NULL RETURN(8)
 	  	  	  	 SELECT @ApproverUserId = NULL
 	  	  	 END
 	 END
IF @WriteDirect = 1 AND @UpdateClientOnly = 0
BEGIN
 	 DECLARE 	 @RC 	  	  	  	 INT,
 	  	  	  	 @EventId 	  	  	 INT,
 	  	  	  	 @EntryOn 	  	  	 DATETIME
 	 
 	 SET 	 @EntryOn = dbo.fnServer_CmnGetDate(getUTCdate())
 	 -- Set parameter values
 	 EXECUTE @RC = spServer_DBMgrUpdTest2
 	  	  	  	 @VariableId,
 	  	  	  	 @UserId,
 	  	  	  	 0,
 	  	  	  	 @Result, 
 	  	  	  	 @Timestamp, 
 	  	  	  	 0, 
 	  	  	  	 @CommentId, 
 	  	  	  	 NULL, 
 	  	  	  	 @EventId OUTPUT , 
 	  	  	  	 @PUId OUTPUT , 
 	  	  	  	 @TestId OUTPUT , 
 	  	  	  	 @EntryOn OUTPUT , 
 	  	  	  	 @ApproverUserId,
                NULL,
                @ESignatureId
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(6)
 	 END
END
RETURN(0)
