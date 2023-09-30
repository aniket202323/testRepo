Create Procedure dbo.spXLAGetCharacteristicID  @Char_desc varchar(50)
 AS 
 Select Char_ID from characteristics where Char_desc = @Char_desc
