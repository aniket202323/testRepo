
CREATE PROCEDURE dbo.spActivities_GetNextEventNumber
@PU_Id	Int,
@Event_Type   Int  -- 2 -production event 25- user defined


 AS 

BEGIN

	DECLARE @NextEventNumber int, @LatestEventNumber nVARCHAR(100), @NumberExists int = 0
	
	--Fetch the last event for the PUId
	IF(@Event_Type = 2)
		BEGIN
			SELECT TOP 1 @LatestEventNumber = Event_Num FROM Events WHERE PU_Id = @PU_Id ORDER BY Event_Id desc		
		END
	ELSE IF(@Event_Type = 25)
	BEGIN
		SELECT TOP 1 @LatestEventNumber = UDE_Desc FROM User_Defined_Events WHERE PU_Id = @PU_Id ORDER BY UDE_Id desc
	END
	
	DECLARE @Key nVARCHAR(100)= @LatestEventNumber
	DECLARE @Value INT;	
	DECLARE @Index INT= LEN(@Key), @EndPos INT, @StartPos INT
	
	WHILE @Index >= 0
	    BEGIN
	        IF SUBSTRING(@Key, @Index, 1) LIKE '[0-9]'
	            BEGIN
	                IF @EndPos IS NULL
	                    BEGIN
	                        SET @EndPos = @Index + 1;
	                    END
	            END
	            ELSE
	            BEGIN
	                IF @EndPos IS NOT NULL
	                    BEGIN
	                        SET @StartPos = @Index + 1
	                        SET @Index = 0
	                    END
	            END
	
	        SET @Index-=1;
	    END
			  
	SET @Value = SUBSTRING(@Key, @StartPos, @EndPos-@StartPos) + 1;
	DECLARE @Prefix nVARCHAR(1) = (CASE WHEN SUBSTRING(@Key, @StartPos, 1) = 0 AND SUBSTRING(@Key, @StartPos + 1, 1) IS NULL AND SUBSTRING(@Key, @StartPos + 1, 1) <> 9 THEN '0'ELSE '' END)
	
	SELECT STUFF(@Key, @StartPos, @EndPos-@StartPos,  @Prefix + CAST(@Value AS nVARCHAR(100))) AS 'NextEventNumber'
 END
