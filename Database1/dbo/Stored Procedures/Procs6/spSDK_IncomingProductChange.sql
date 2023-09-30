CREATE PROCEDURE dbo.spSDK_IncomingProductChange
 	 -- Input Parameters
 	 @WriteDirect 	  	  	 BIT,
 	 @UpdateClientOnly 	  	 BIT,
 	 @UnitName 	  	  	  	 nvarchar(50),
 	 @LineName 	  	  	  	 nvarchar(50),
 	 @ProdCode  	  	  	  	 nvarchar(50),
 	 @StartTime  	  	  	  	 DATETIME,
 	 @EndTime 	  	  	  	  	 DATETIME,
 	 @UserId 	  	  	  	  	 INT,
 	 -- Input/Output Parameters
 	 @StartId 	  	  	  	  	 INT OUTPUT,
 	 @TransactionType 	  	 INT OUTPUT,
        @ESignatureId           INT OUTPUT,
 	 -- Output Parameters
 	 @PUId 	  	  	  	  	  	 INT OUTPUT,
 	 @ProdId  	  	  	  	  	 INT OUTPUT,
 	 @CommentId  	  	  	  	 INT OUTPUT,
 	 @EventSubTypeId 	  	 INT OUTPUT
AS
-- Return Values
-- 0 - Success
-- 2 - Line Not Found
-- 3 - Unit Not Found
-- 4 - Product Not Found
-- 5 - Event SubType Not Found
-- 6 - Update, but Production_Starts row not found
-- 7 - New Product matches Previous Product
-- 8 - New Product matches Next Product
DECLARE 	 @TempStartTime 	 DATETIME,
 	  	  	 @TempEndTime 	 DATETIME,
 	  	  	 @TempProdId 	  	 INT,
 	  	  	 @PLId 	  	  	  	 INT,
 	  	  	 @RC 	  	  	  	 INT,
 	  	  	 @SecondUserId 	 INT
IF @ESignatureId = 0 SELECT @ESignatureId = NULL
--Lookup Unit
SELECT 	 @PLId = NULL
SELECT 	 @PLId = PL_Id 
 	 FROM 	 Prod_Lines 
 	 WHERE 	 PL_Desc = @LineName
IF @PLId IS NULL RETURN(2)
SELECT 	 @PUId = NULL
SELECT 	 @PUId = PU_Id
 	 FROM 	 Prod_Units 
 	 WHERE 	 PU_Desc = @UnitName AND 
 	  	  	 PL_Id = @PLId
IF @PUId IS NULL RETURN(3)
--Lookup Product
IF @ProdCode IS NOT NULL
BEGIN
 	 SELECT 	 @ProdId = NULL
 	 SELECT 	 @ProdId = Prod_Id 
 	  	 FROM 	 Products 
 	  	 WHERE 	 Prod_Code = @ProdCode
 	 IF @ProdId IS NULL RETURN(4)
END
--Try to find the Start_Id
SELECT @CommentId = NULL
IF @StartId IS NULL
BEGIN
 	 SELECT 	 @StartId = Start_Id, 
 	  	  	  	 @TempStartTime = Start_Time, 
 	  	  	  	 @TempEndTime = End_Time, 
 	  	  	  	 @CommentId = Comment_Id FROM Production_Starts 
 	  	 WHERE 	 PU_Id = @PUId AND 
 	  	  	  	 Start_Time = @StartTime
END ELSE
BEGIN
 	 SELECT 	 @StartId = Start_Id, 
 	  	  	  	 @TempStartTime = Start_Time, 
 	  	  	  	 @TempEndTime = End_Time, 
 	  	  	  	 @CommentId = Comment_Id FROM Production_Starts 
 	  	 WHERE 	 PU_Id = @PUId AND 
 	  	  	  	 Start_Id = @StartId
END
--Trying to update, but did not find the Production Starts row
IF @StartId IS NULL AND @TransactionType = 2 RETURN (6)
--New Product matches Previous Product
SELECT 	 @TempProdId = Prod_Id from Production_Starts
 	 WHERE 	 PU_Id = @PUId AND 
 	  	  	 End_Time = @TempStartTime
IF @TempProdId = @ProdId RETURN(7)
--New Product matches Next Product
SELECT 	 @TempProdId = Prod_Id 
 	 FROM 	 Production_Starts
  	 WHERE PU_Id = @PUId AND Start_Time = @TempEndTime
IF @TempProdId = @ProdId RETURN(8)
IF @WriteDirect = 1 AND @UpdateClientOnly = 0
BEGIN
 	 EXECUTE @RC = spServer_DBMgrUpdGrade2
 	  	  	  	 @StartId OUTPUT , 
 	  	  	  	 @PUId, 
 	  	  	  	 @ProdId, 
 	  	  	  	 1, 
 	  	  	  	 @StartTime OUTPUT , 
 	  	  	  	 0, 
 	  	  	  	 @UserId, 
 	  	  	  	 @CommentId, 
 	  	  	  	 @EventSubTypeId, 
 	  	  	  	 @EndTime OUTPUT , 
 	  	  	  	 @ProdCode OUTPUT , 
 	  	  	  	 0, 
 	  	  	  	 NULL,  -- Modified Start
 	  	  	  	 NULL,  -- Modified End
 	  	  	  	 @SecondUserId,
                                @ESignatureId
 	  	  	  	 
 	 IF @RC < 0
 	 BEGIN
 	  	 RETURN(9)
 	 END
END
RETURN(0)
