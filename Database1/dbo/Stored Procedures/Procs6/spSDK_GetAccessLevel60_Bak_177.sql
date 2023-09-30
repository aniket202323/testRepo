CREATE procedure [dbo].[spSDK_GetAccessLevel60_Bak_177]
@ObjectType 	 varchar(100),
@Item1 varchar(100),
@Item2 varchar(100),
@Item3 varchar(100),
@Item4 varchar(100),
@UserId int,
@AccessLevel int OUTPUT
AS
 	 Declare
 	  	 @GroupId int
 	  	 
 	 Select @GroupId = NULL
 	 Select @AccessLevel = -1
 	 
 	 if @ObjectType = 'PAVariable'
 	  	 select @GroupId = Coalesce(v.Group_Id, 0)
 	  	  	 from Variables_Base as v
 	  	  	 join Prod_Units_Base pu on pu.pu_id = v.pu_id
 	  	  	 join Prod_Lines_Base pl on pl.pl_id = pu.pl_id
 	  	  	 join Departments_Base d on d.dept_id = pl.dept_id
 	  	  	 where d.dept_desc = LTrim(RTrim(@Item1))
 	  	  	 and pl.pl_desc = LTrim(RTrim(@Item2))
 	  	  	 and pu.pu_desc = LTrim(RTrim(@Item3))
 	  	  	 and v.var_desc = LTrim(RTrim(@Item4))
 	 else if @ObjectType = 'PAProductionLine'
 	  	 select @GroupId = Coalesce(pl.Group_Id, 0)
 	  	  	 from Prod_Lines_Base pl
 	  	  	 join Departments_Base d on d.dept_id = pl.dept_id
 	  	  	 where d.dept_desc = LTrim(RTrim(@Item1))
 	  	  	 and pl.pl_desc = LTrim(RTrim(@Item2))
 	 else if @ObjectType = 'PAProductionUnit'
 	  	 select @GroupId = Coalesce(pu.Group_Id, 0)
 	  	  	 from Prod_Units_Base pu
 	  	  	 join Prod_Lines_Base pl on pl.pl_id = pu.pl_id
 	  	  	 join Departments_Base d on d.dept_id = pl.dept_id
 	  	  	 where d.dept_desc = LTrim(RTrim(@Item1))
 	  	  	 and pl.pl_desc = LTrim(RTrim(@Item2))
 	  	  	 and pu.pu_desc = LTrim(RTrim(@Item3))
 	 else if @ObjectType = 'PAProduct'
 	  	 select @GroupId = Coalesce(pf.Group_Id, 0)
 	  	  	 from products p
 	  	  	 join product_family pf on pf.product_family_id = p.product_family_id
 	  	  	 where p.prod_code = LTrim(RTrim(@Item1))
 	 else if @ObjectType = 'PAUser'
 	  	 select @GroupId = Coalesce(Group_Id,0)
 	  	  	 from User_Security where User_Id = @UserId
 	 If (@GroupId Is NULL) Or (@GroupId = 0)
 	  	 return
 	  	  	 
 	 Select @AccessLevel = NULL
 	 Select @AccessLevel = Access_Level From User_Security Where User_Id = @UserId and Group_Id = @GroupId
 	 If (@AccessLevel Is NULL)
 	  	 Select @AccessLevel = -1
 	  	 
