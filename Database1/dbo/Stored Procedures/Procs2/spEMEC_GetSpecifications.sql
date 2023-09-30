Create Procedure dbo.spEMEC_GetSpecifications
@Spec_Id int = Null,
@User_Id int
AS
if @Spec_Id = 0
  select @Spec_Id = Null
if @Spec_Id is Null
  Begin
    select s.spec_id as ID, Prop_Desc + '/' + spec_desc as 'Specifications'
    from specifications s
 	 Join Product_Properties pp On pp.Prop_Id = s.Prop_Id
    order by Prop_Desc,spec_desc
  End
else
  Begin
    select spec_desc = Prop_Desc + '/' + spec_desc
    from specifications s
 	 Join Product_Properties pp On pp.Prop_Id = s.Prop_Id
    where spec_id = @Spec_Id
  End
