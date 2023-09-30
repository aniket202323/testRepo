CREATE PROCEDURE dbo.spEM_SearchForSpecVariables
 	 @Prop_Id 	 Int,
 	 @SpecDesc   nvarchar(1000)
  AS
  --
If @SpecDesc = ''
  Select @SpecDesc = '%'
else
  Begin
 	 Select @SpecDesc = REPLACE(@SpecDesc,'*','%')
 	 Select @SpecDesc = REPLACE(@SpecDesc,'?','_')
  End
if charindex('%',@SpecDesc) = 0
 	 Select @SpecDesc = '%' + @SpecDesc + '%'
If @Prop_Id = -1 
  Select  Spec_Desc,Spec_Id
 	 From Specifications s
 	 Where Spec_Desc like @SpecDesc  and s.Prop_Id = @Prop_Id
 	 Order by Spec_Order
Else
  Select  Spec_Desc ,Spec_Id
 	 From Specifications s
 	 Where s.Prop_Id =@Prop_Id and Spec_Desc like @SpecDesc
 	 Order by Spec_Desc
