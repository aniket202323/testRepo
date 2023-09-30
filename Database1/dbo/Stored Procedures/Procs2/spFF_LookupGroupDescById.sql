Create Procedure dbo.spFF_LookupGroupDescById 
@Group_Id int,
@Group_Desc nvarchar(50) OUTPUT
AS
Select @Group_Desc = Null
Select @Group_Desc = Group_Desc From Security_Groups Where Group_Id = @Group_Id
Return(100)
