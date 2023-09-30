------------------------------------------------------------ --------------------
CREATE PROCEDURE	[dbo].[spLocal_Util_VerifyProductCode]
					@ProductCode		nvarchar(255)

--WITH ENCRYPTION
AS
	SET NOCOUNT ON
	
	DECLARE	@ProdId		int
	DECLARE	@tOutput	table(
			Id			int identity (1,1),
			[StatusBit]	bit)

	SET		@ProdId		= 	Null
	SELECT	@ProdId		=	p.Prod_Id
	FROM	dbo.Products_Base	p with (nolock)
	WHERE	p.Prod_Code = @ProductCode

	IF @ProdId Is Not Null
	BEGIN
		INSERT	@tOutput(
				[StatusBit])
		SELECT	1
	END
	ELSE
	BEGIN
		INSERT	@tOutput(
				[StatusBit])
		SELECT 0
	END

	SELECT	IsNull(t.StatusBit,0) as StatusBit
	FROM	@tOutput t
	

RETURN

SET NOcount OFF