CREATE PROCEDURE dbo.spEM_IEImportDefaultCharacteristic
 	 @ProductCode 	  	 nVarChar(100),
 	 @ProductProperty 	 nVarChar(100),
 	 @Characteristic 	  	 nVarChar(100),
 	 @UserId 	  	 Int
AS
Declare @ProdId 	 int,
 	 @PropId 	 int,
 	 @CharId 	 int
/* Clean and verify arguments */
Select  	 @ProductCode 	  = ltrim(rtrim(@ProductCode)),
 	 @ProductProperty = ltrim(rtrim(@ProductProperty)),
 	 @Characteristic 	  = ltrim(rtrim(@Characteristic))
IF @ProductCode = '' 	  	 Select @ProductCode = Null
IF @ProductProperty = ''  	 Select @ProductProperty = Null
IF @Characteristic = ''  	 Select @Characteristic = Null
If @ProductProperty Is Null
  Begin
 	 Select 'Failed - Product Property is missing'
 	 Return (-100)
  End
If @ProductCode Is Null
  Begin
 	 Select 'Failed - Product code is missing'
 	 Return (-100)
  End
If @Characteristic Is Null
  Begin
 	 Select 'Failed - Characteristic is missing'
 	 Return (-100)
  End
/* Get ids */
Select @ProdId = Prod_Id From Products  Where Prod_Code = @ProductCode
If @ProdId Is Null
BEGIN
 	 Select 'Product code not found'
 	 Return (-100)
END
Select @PropId = Prop_Id  From Product_Properties  Where Prop_Desc = @ProductProperty
If @PropId Is Null
BEGIN
 	 Select 'Failed - Product property not found'
 	 Return (-100)
END
Select @CharId = Char_Id  From Characteristics  Where Char_Desc = @Characteristic and Prop_Id = @PropId
If @CharId Is Null
BEGIN
 	 Select 'Failed - Characteristic not found'
 	 Return (-100)
END
IF NOT EXISTS (SELECT * FROM Product_Characteristic_Defaults WHERE Char_Id = @CharId and Prod_Id = @ProdId AND Prop_Id = @PropId)
BEGIN
 	 EXECUTE spEM_PutProductCharacteristic @ProdId,@CharId,@PropId,@UserId
END
