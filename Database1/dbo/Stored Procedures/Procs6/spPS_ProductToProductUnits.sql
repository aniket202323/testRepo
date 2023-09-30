
CREATE PROCEDURE [dbo].[spPS_ProductToProductUnits]
@Prod_Id      int = null,
@Unit_Id      int = null,
@IsDelete 	  bit,
@User_Id      int = 1

  AS

DECLARE @p1 int,
        @TimeStamp dateTimeoffset(7),
        @Trans_Desc nvarchar(255),
		@p7 datetime2(0),
		@p9 datetime2(0),
		@username nvarchar(100)
  
		SET @username = (select Username from users where user_id = @User_Id)
		SELECT @TimeStamp = CURRENT_TIMESTAMP;
		SELECT @Trans_Desc = @username + ' on ' + convert(nvarchar(100), @TimeStamp)
		set @p9= @TimeStamp
		set @p7=  @TimeStamp

		IF NOT EXISTS(SELECT 1 FROM Products WHERE Prod_Id = @Prod_Id)
		BEGIN
			SELECT Error = 'Product Not Found To Update' , 'EPS1110' as Code
			RETURN
		END

		-- IF NOT EXISTS(SELECT 1 FROM Prod_Units_Base WHERE PU_Id = @Unit_Id)
		-- BEGIN
		--	SELECT Error = 'Production Unit Not Found To Update'
		--	RETURN
		-- END

    	-- Calling Core Sproc to Create transaction
		EXECUTE dbo.spEM_CreateTransaction @Trans_Desc, null, 1, null, @User_Id, @p1 output
		PRINT 'TRANSACTION CREATED'

		-- Calling Core Sproc to Associate product to production unit
		EXECUTE dbo.spEM_PutTransProduct @p1, @Prod_Id, @Unit_Id, @IsDelete, @User_Id
		
		-- Calling Core Sproc to Approve transaction
		EXECUTE dbo.spEM_ApproveTrans @p1, @User_Id, 1, @TimeStamp, @p7 output,@p9 output
		PRINT 'TRANSACTION APPROVED'

		SELECT Prod_Id,PU_Id FROM PU_PRODUCTS where prod_id = @Prod_Id
