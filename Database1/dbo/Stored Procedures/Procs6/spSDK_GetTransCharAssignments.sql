CREATE PROCEDURE dbo.spSDK_GetTransCharAssignments
 	 @TransId 	  	  	 INT,
 	 @PUId 	  	  	  	 INT,
 	 @ProdId 	  	  	 INT,
 	 @PropId 	  	  	 INT,
 	 @CharId 	  	  	 INT 	  	  	  	 OUTPUT,
 	 @CharDesc 	  	 nvarchar(50) 	 OUTPUT,
 	 @OldCharDesc 	 nvarchar(50) 	 OUTPUT
AS
DECLARE 	 @OldCharId 	 INT
SELECT 	 @CharId = NULL
SELECT 	 @CharId = CASE 
 	  	  	  	  	  	  	  WHEN tc.Trans_Id IS NULL THEN pc.Char_Id
 	  	  	  	  	  	  	  ELSE tc.Char_Id
 	  	  	  	  	  	  END
 	 FROM 	 Prod_Units pu 	  	  	  	  	 LEFT JOIN
 	  	  	 PU_Characteristics pc 	  	 ON pu.PU_Id = pc.PU_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pc.Prop_Id = @PropId AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pc.Prod_Id = @ProdId LEFT JOIN
 	  	  	 Trans_Characteristics tc  	 ON pu.PU_Id = tc.PU_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 tc.Prop_Id = @PropId AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 tc.Prod_Id = @ProdId
 	 WHERE 	 pu.PU_Id = @PUId
SELECT 	 @OldCharId = NULL
SELECT 	 @OldCharId = pc.Char_Id
 	 FROM 	 Prod_Units pu 	  	  	  	  	 LEFT JOIN
 	  	  	 PU_Characteristics pc 	  	 ON pu.PU_Id = pc.PU_Id AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pc.Prop_Id = @PropId AND
 	  	  	  	  	  	  	  	  	  	  	  	  	 pc.Prod_Id = @ProdId
 	 WHERE 	 pu.PU_Id = @PUId
SELECT 	 @CharDesc = NULL
SELECT 	 @CharDesc = Char_Desc
 	 FROM 	 Characteristics
 	 WHERE 	 Char_Id = @CharId
SELECT 	 @OldCharDesc = NULL
SELECT 	 @OldCharDesc = Char_Desc
 	 FROM 	 Characteristics
 	 WHERE 	 Char_Id = @OldCharId
