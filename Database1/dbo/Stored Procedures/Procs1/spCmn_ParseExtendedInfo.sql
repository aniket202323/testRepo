Create Procedure dbo.spCmn_ParseExtendedInfo
 	 @Value 	  	 Varchar(255) output,
 	 @InputString 	 VarChar(255),
 	 @SearchString 	 VarChar(255)
 AS
Declare @Start 	 Int,
 	 @End 	 Int
Select @Value = ''
Select @Start =  CharIndex(@SearchString,@InputString)
If @Start <> 0 
   Begin
      Select @Start = @Start + len(@SearchString)
      Select @End = CharIndex(',',Substring(@InputString,@Start,datalength(@InputString)-@Start))
      If @End = 0 Select @End = Datalength(@InputString)  + 1
      Select @End = @End + @Start - 1
      Select @Value = Ltrim(Rtrim(SubString(@InputString,@Start ,@End - @Start)))
   End
