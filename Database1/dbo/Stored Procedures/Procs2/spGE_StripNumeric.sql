CREATE Procedure dbo.spGE_StripNumeric @Value nvarchar(25) Output
 	 As
Declare @Len Int, @Pos Int
Select @Len = LEN(@Value),@Pos = 1
While @Pos <= @Len and isnumeric(substring(@Value,1,@Pos)) = 1
  Begin
 	 Select @Pos = @Pos + 1
  End
select @Value = Left(@Value,@Pos -1)
