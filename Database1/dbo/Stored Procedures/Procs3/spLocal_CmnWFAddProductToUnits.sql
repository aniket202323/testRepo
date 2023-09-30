CREATE PROCEDURE  [dbo].[spLocal_CmnWFAddProductToUnits]
@puid							int,
@ProdId							int,
@UserName						varchar(100)		

AS

SET NOCOUNT ON 
-------------------------------------------------------------------------------
-- TASK 1 Declare variables
-------------------------------------------------------------------------------
DECLARE
@UserId					int

-------------------------------------------------------------------------------
-- TASK 2 Define user
-------------------------------------------------------------------------------
SET @UserId = (SELECT User_Id FROM dbo.Users WHERE username = @UserName)
IF @UserId IS NULL
	SET @UserId = (SELECT User_Id FROM dbo.Users WHERE username = 'System.PE')


-------------------------------------------------------------------------------
-- TASK 3 attach product to units
-------------------------------------------------------------------------------

--attach produt to unit
IF NOT EXISTS (SELECT 1 FROM dbo.PU_Products WHERE PU_ID = @PuId AND PRod_ID =@prodID)
	BEGIN
		EXEC dbo.spEM_CreateUnitProd   @PuId,@prodID,@UserId
		--EXEC dbo.spEM_PutUnitCharacteristic @PuRowId, @prodID, @propID, @charId , @userID
	END


SET NOCOUNT OFF