Create Procedure dbo.spGBAGetCharacteristicID  @Char_desc nVarChar(50)
 AS
Select Char_ID from characteristics where Char_desc = @Char_desc
