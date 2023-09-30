-------------------------------------------------------------------------------------------------

-------------------------------------[Creation Of Function]--------------------------------------
CREATE FUNCTION [dbo].[fnLocal_GetProdId] (@PU_Id int, @SpecificTime datetime)
/*
-------------------------------------------------------------------------------------------------
Created by	:	Normand Carbonneau (System Technologies for Industry Inc)
Date			:	2006-03-02
Version		:	1.0.0
Purpose		:	Find the Prod_Id of the product that was running on unit @PU_Id
					at time @SpecificTime.
-------------------------------------------------------------------------------------------------
*/

RETURNS int

AS
BEGIN
	DECLARE 
	@CurrentProdID	int

	SET @CurrentProdID =	(
								SELECT	Prod_Id
								FROM		dbo.Production_Starts
								WHERE		PU_Id = @PU_Id
								AND		(Start_Time <= @SpecificTime)
								AND		(
											End_Time > @SpecificTime
											OR
											End_Time IS NULL
											)
								)
							
	RETURN @CurrentProdID
END

