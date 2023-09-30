CREATE PROCEDURE dbo.spSDK_OutgoingInputEvent
 	 @TransactionType 	 INT,
 	 @PEIId 	  	  	  	 INT,
 	 @PEIPId 	  	  	  	 INT,
 	 @EventId 	  	  	  	 INT,
 	 @CommentId 	  	  	 INT,
 	 @LineName 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @UnitName 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @InputName 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @Position 	  	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @SrcLineName 	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @SrcUnitName 	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 @SrcEventName 	  	 nvarchar(50) 	  	  	 OUTPUT,
 	 -- 4.0 Additions
 	 @DepartmentName 	 nvarchar(50) = NULL 	 OUTPUT
AS
-- Return Values
-- 1 - Success
-- 2 - Input Not Found
-- 3 - Position Not Found
-- 4 - Source Event Not Found
-- 5 - Comment Not Found
DECLARE 	 @PLId 	  	 INT,
 	  	  	 @PUId 	  	 INT
--Lookup Line, Unit, Input Name
SELECT 	 @LineName = NULL,
 	  	  	 @UnitName = NULL,
 	  	  	 @InputName = NULL
SELECT 	 @LineName = PL_Desc,
 	  	  	 @UnitName = PU_Desc,
 	  	  	 @InputName = Input_Name
 	 FROM 	 Prod_Lines pl
 	 JOIN 	 Prod_Units pu 	  	  	 ON pu.PL_Id = pl.PL_Id
 	 JOIN 	 PrdExec_Inputs pei 	 ON pu.PU_Id = pei.PU_Id
 	 WHERE 	 pei.PEI_Id = @PEIId
IF @InputName IS NULL RETURN(2)
--Lookup Position
SELECT 	 @Position = NULL
SELECT 	 @Position = PEIP_Desc
 	 FROM 	 PrdExec_Input_Positions 
 	 WHERE 	 PEIP_Id = @PEIPId
IF @Position IS NULL RETURN(3)
--Lookup Line, Unit, Input Name
SELECT 	 @SrcLineName = NULL,
 	  	  	 @SrcUnitName = NULL,
 	  	  	 @SrcEventName = NULL
SELECT 	 @SrcLineName = PL_Desc,
 	  	  	 @SrcUnitName = PU_Desc,
 	  	  	 @SrcEventName = Event_Num
 	 FROM 	 Prod_Lines pl  	 JOIN
 	  	  	 Prod_Units pu 	 ON (pu.PL_Id = pl.PL_Id) JOIN
 	  	  	 Events e 	  	  	 ON (pu.PU_Id = e.PU_Id)
 	 WHERE 	 e.Event_Id = @EventId
IF @SrcEventName IS NULL AND @TransactionType = 2 RETURN (4)
RETURN(0)
