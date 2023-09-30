Create Procedure dbo.spDAML_AddProduct
 	 @ProdFamilyId 	 int,
 	 @ProdCode 	  	 varchar(25),
 	 @ProdDesc 	  	 varchar(50),
 	 @UserId 	  	  	 INT,
 	 @ProdId 	  	  	 int output
AS
declare @Status int
exec @Status = spEM_CreateProd @ProdDesc, @ProdCode, @ProdFamilyId, @UserId, @ProdId output
if (@Status <> 0)
 	 select @ProdId = 0
