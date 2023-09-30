CREATE PROCEDURE dbo.spSDK_QueryTransactions
 	 @UserId 	  	  	  	 INT,
 	 @TransStatus 	  	 INT,
 	 @GroupMask  	  	  	 nvarchar(50) = NULL,
 	 @NameMask  	  	  	 nvarchar(50) = NULL,
 	 @StartTime 	  	  	 DATETIME = NULL,
 	 @EndTime 	  	  	  	 DATETIME = NULL
AS
SELECT 	 @GroupMask = 	 REPLACE(COALESCE(@GroupMask, '*'), '*', '%')
SELECT 	 @GroupMask = 	 REPLACE(REPLACE(@GroupMask, '?', '_'), '[', '[[]')
SELECT 	 @NameMask = 	  	 REPLACE(COALESCE(@NameMask, '*'), '*', '%')
SELECT 	 @NameMask = 	  	 REPLACE(REPLACE(@NameMask, '?', '_'), '[', '[[]')
IF @EndTime IS NULL
BEGIN
 	 SELECT @EndTime = dbo.fnServer_CmnGetDate(getUTCdate())
END
IF @StartTime IS NULL
BEGIN
 	 SELECT 	 @StartTime = MIN(Trans_Create_Date)
 	  	 FROM 	 Transactions
END
SELECT 	 Trans_Id
   FROM 	 Transactions t 	  	  	  	 LEFT JOIN
 	  	  	 Transaction_Groups tg 	 ON tg.Transaction_Grp_Id = t.Transaction_Grp_Id
 	 WHERE 	 COALESCE(tg.Transaction_Grp_Desc, '') LIKE @GroupMask AND
 	  	  	 t.Trans_Desc LIKE @NameMask AND
 	  	  	 t.Trans_Create_Date BETWEEN @StartTime AND @EndTime AND
 	  	  	 1 = CASE 
 	  	  	  	  	 WHEN t.Approved_On IS NULL AND @TransStatus IN (0,1) THEN 1 
 	  	  	  	  	 WHEN t.Approved_On IS NOT NULL AND @TransStatus IN (0,2) THEN 1 
 	  	  	  	  	 ELSE 0
 	  	  	  	  END
