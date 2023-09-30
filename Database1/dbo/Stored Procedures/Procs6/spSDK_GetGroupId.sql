CREATE PROCEDURE dbo.spSDK_GetGroupId
 	 @RecordType 	 int,
 	 @Item1 nvarchar(50),
 	 @Item2 nvarchar(50),
 	 @Item3 nvarchar(50),
 	 @Item4 nvarchar(50),
 	 @GroupId int OUTPUT
AS
--@RecordType
--sdkMDVariable = 59
--sdkMDProductionLine = 62
--sdkMDProductionUnit = 63
--sdkMDProduct = 64
--sdkMDSheets = 52
if @RecordType = 59 --Variable
 	 select @GroupId = Coalesce(v.Group_Id, 0)
 	  	 from variables v
 	  	 join prod_units pu on pu.pu_id = v.pu_id
 	  	 join prod_lines pl on pl.pl_id = pu.pl_id
 	  	 join departments d on d.dept_id = pl.dept_id
 	  	 where d.dept_desc = LTrim(RTrim(@Item1))
 	  	 and pl.pl_desc = LTrim(RTrim(@Item2))
 	  	 and pu.pu_desc = LTrim(RTrim(@Item3))
 	  	 and v.var_desc = LTrim(RTrim(@Item4))
else if @RecordType = 62 --Production Line
 	 select @GroupId = Coalesce(pl.Group_Id, 0)
 	  	 from prod_lines pl
 	  	 join departments d on d.dept_id = pl.dept_id
 	  	 where d.dept_desc = LTrim(RTrim(@Item1))
 	  	 and pl.pl_desc = LTrim(RTrim(@Item2))
else if @RecordType = 63 --Production Unit
 	 select @GroupId = Coalesce(pu.Group_Id, 0)
 	  	 from prod_units pu
 	  	 join prod_lines pl on pl.pl_id = pu.pl_id
 	  	 join departments d on d.dept_id = pl.dept_id
 	  	 where d.dept_desc = LTrim(RTrim(@Item1))
 	  	 and pl.pl_desc = LTrim(RTrim(@Item2))
 	  	 and pu.pu_desc = LTrim(RTrim(@Item3))
else if @RecordType = 64 --Product
 	 select @GroupId = Coalesce(pf.Group_Id, 0)
 	  	 from products p
 	  	 join product_family pf on pf.product_family_id = p.product_family_id
 	  	 where p.prod_code = LTrim(RTrim(@Item1))
else if @RecordType = 52 --Sheet
 	 select @GroupId = Coalesce(Group_Id, 0)
 	  	 from sheets
 	  	 where sheet_desc = LTrim(RTrim(@Item1))
else
 	 select @GroupId = -1
