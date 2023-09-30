CREATE FUNCTION dbo.fnSDK_DEI_InsertEmptyList(
@rowcount int
)
returns @Items table
(
  ItemId int,
  ItemOrder int,
  ItemDisplayValue nvarchar(100),
  ItemValue nvarchar(100)
)
AS
begin
if (@rowcount = 0)
  insert into @Items values (null, null, null, null)
return
 	 
end
