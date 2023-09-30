-------------------------------------------------------------------------------
-- DATE  	    	 BY  	    	    	 DESCRIPTION
-- 06-Dec-20065 AHussain 	 01 01  	 ECR#32845 Fixes overflow error especially seen when 
--                                  run against waste_event_detail_history 
-------------------------------------------------------------------------------
CREATE FUNCTION dbo.fnS95_ColumnUpdated ( 	 @COLUMNS_UPDATED 	 binary(8),
 	  	  	  	  	  	 @OP 	  	  	 int)
RETURNS int AS
BEGIN
DECLARE @POS 	  	 BigInt,    -- ECR#32845 
 	  	 @PRE 	  	 int,
 	  	 @RESULT 	  	 int
SET @PRE = (@OP-1)/8
SET @POS =  POWER(CAST(2 AS BigInt), (@OP-1)) / POWER(CAST(2 AS BigInt), @PRE*8)
IF (SUBSTRING(@COLUMNS_UPDATED, @PRE+1, 1) & @POS <> 0)
 	 SET @RESULT = 1
ELSE
 	 SET @RESULT = 0
RETURN @RESULT
END
