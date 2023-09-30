
CREATE FUNCTION  dbo.fnPS_checkDuplicateLotIdentifier (@LotIdentifier nvarchar(100), @Pu_Id Int)
  RETURNS Int
AS 
BEGIN 
    DECLARE @isLotIdentifierAvailable Int;  
	select @isLotIdentifierAvailable = count(*) from events 
		where 
    event_num=@LotIdentifier and pu_id=@Pu_Id;
    RETURN @isLotIdentifierAvailable;  
END
