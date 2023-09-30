CREATE PROCEDURE dbo.spEMTFV_GetTableValues 
 	 @TableId  int,
 	 @TableFieldId  int,
 	 @tz varchar(100) = 'UTC'
  AS
/*
 	 [TAG] = 	  	 1 - Value
 	  	  	  	 2 - Key
 	  	  	  	 10 - SP_Lookup
 	  	  	  	 11 - Store_Id
 	  	  	  	 12 - @TableId
 	  	  	  	 13 - Table_Field_Id
 	  	  	  	 14 - Table_Field_Desc
*/
Declare @IsDateTimeField Int 
SET @IsDateTimeField = 0
Select @IsDateTimeField = 1 from Tables T join Table_Fields TF on TF.TableId = T.TableId AND TF.Table_Field_Id = @TableFieldId Join ED_FieldTypes EF on EF.ED_Field_Type_Id = TF.ED_Field_Type_Id
WHere T.TableId = @TableId AND EF.ED_Field_Type_Id=12
 	 IF @TableId = 7 -- Production_Plan
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Code] = b.Path_Code,
 	  	  	  	 [Order] = a.Process_Order,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(case when @IsDateTimeField = 1 then CONVERT(NVARCHAR(2000),dbo.fnServer_CmnConvertFromDbTime(Value, @tz)) else Value end,tf.ED_Field_Type_Id,1) ,
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(case when @IsDateTimeField = 1 then CONVERT(NVARCHAR(2000),dbo.fnServer_CmnConvertFromDbTime(Value, @tz)) else Value end,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(case when @IsDateTimeField = 1 then CONVERT(NVARCHAR(2000),dbo.fnServer_CmnConvertFromDbTime(Value, @tz)) else Value end,tf.ED_Field_Type_Id,3) 
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Production_Plan a On a.PP_Id = t.KeyId
 	  	  	 LEFT JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY  b.Path_Code,a.Process_Order
 	 ELSE IF @TableId = 8 -- Production_Setup
 	  	 SELECT 	 [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,[Code] = b.Path_Code,
 	  	  	  	 [Order] = a.Process_Order,[Pattern] = c.Pattern_Code,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN  Production_Setup c on c.PP_Setup_Id =  t.KeyId
 	  	  	 JOIN Production_Plan a On a.PP_Id = c.PP_Id
 	  	  	 Left JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY b.Path_Code,a.Process_Order,c.Pattern_Code
 	 ELSE IF @TableId = 9 -- Production_Setup_Detail
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Code] = d.Path_Code,
 	  	  	  	 [Order] = c.Process_Order,
 	  	  	  	 [Pattern] = b.Pattern_Code,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Production_Setup_Detail a ON  a.PP_Setup_Detail_Id =  t.KeyId
 	  	  	 JOIN  Production_Setup b on b.PP_Setup_Id =  t.KeyId
 	  	  	 JOIN Production_Plan c On c.PP_Id = b.PP_Id
 	  	  	 Left JOIN Prdexec_Paths d on d.Path_Id = c.Path_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY d.Path_Code,c.Process_Order,b.Pattern_Code
 	 ELSE IF @TableId = 13 -- PrdExec_Paths
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Code] = Path_Code,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN PrdExec_Paths a On a.Path_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Path_Code
 	 ELSE IF @TableId = 17 -- Departments
 	  	 SELECT 	 [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Deparment] = Dept_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Departments a On a.Dept_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Dept_Desc
 	 ELSE IF @TableId = 18 -- Prod_Lines
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Prod_Lines b on b.PL_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY PL_Desc
 	 ELSE IF @TableId = 19 --PU_Groups
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Group]= PUG_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN PU_Groups a On a.PUG_Id = t.KeyId
 	  	  	 JOIN Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 JOIN Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY PL_Desc,PU_Desc,PUG_Desc
 	 ELSE IF @TableId = 20 --Variables
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Variable]= Var_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Variables b on b.Var_Id = t.KeyId
 	  	  	 JOIN Prod_Units c on c.pu_Id = b.PU_Id
 	  	  	 JOIN Prod_Lines d On d.pl_Id = c.PL_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY PL_Desc,PU_Desc,Var_Desc
 	 ELSE IF @TableId = 21 --Product_Family 
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Family] = Product_Family_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Product_Family a On a.Product_Family_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Product_Family_Desc
 	 ELSE IF @TableId = 22 -- Product_Groups
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Product Group] = Product_Grp_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Product_Groups a On a.Product_Grp_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Product_Grp_Desc
 	 ELSE IF @TableId = 23 --Products
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Product Code] = Prod_Code,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Products a On a.Prod_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Prod_Code
 	 ELSE IF @TableId = 24 --Event_Reasons
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Reason] = Event_Reason_Name,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Event_Reasons a On a.Event_Reason_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Event_Reason_Name
 	 ELSE IF @TableId = 25 --Event_Reason_Catagories
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Category] = Erc_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Event_Reason_Catagories a On a.ERC_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Erc_Desc
 	 ELSE IF @TableId = 26 -- Bill_Of_Material_Formulation
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Formulation] = BOM_Formulation_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Bill_Of_Material_Formulation a On a.BOM_Formulation_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY BOM_Formulation_Desc
 	 ELSE IF @TableId = 27 -- Subscription
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Subscription] = Subscription_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Subscription a On a.Subscription_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Subscription_Desc
 	 ELSE IF @TableId = 28 --Bill_Of_Material_Formulation_Item
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [BOM Formulation] = BOM_Formulation_Desc,
 	  	  	  	 [Order] = BOM_Formulation_Order,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Bill_Of_Material_Formulation_Item a On a.BOM_Formulation_Item_Id = t.KeyId
 	  	  	 JOIN Bill_Of_Material_Formulation b On b.BOM_Formulation_Id = a.BOM_Formulation_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY BOM_Formulation_Desc,BOM_Formulation_Order
 	 ELSE IF @TableId = 29  --Subscription_Group
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Subscription Group] = Subscription_Group_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Subscription_Group a On a.Subscription_Group_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 order by Subscription_Group_Desc
 	 ELSE IF @TableId = 30 --PrdExec_Path_Units
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Path] = Path_Code,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN PrdExec_Path_Units a On a.PEPU_Id = t.KeyId
 	  	  	 JOIN Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 JOIN Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 JOIN PrdExec_Paths d On d.Path_Id = a.Path_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Path_Code,PL_Desc,PU_Desc
 	 ELSE IF @TableId = 31 --Report_Types
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Type] = [Description],
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Report_Types a On a.Report_Type_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY [Description]
 	 ELSE IF @TableId = 32 --Report_Definitions
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Report] = [Report_Name],
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Report_Definitions a On a.Report_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY [Report_Name]
 	 ELSE IF @TableId = 34 --Production_Plan_Statuses
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Status] = PP_Status_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Production_Plan_Statuses a On a.PP_Status_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY PP_Status_Desc
 	 ELSE IF @TableId = 35 -- PrdExec_Inputs
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Input]= Input_Name,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN PrdExec_Inputs a On a.PEI_Id = t.KeyId
 	  	  	 JOIN Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 JOIN Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY PL_Desc,PU_Desc,Input_Name
 	 ELSE IF @TableId = 36 --Users
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,[User] = UserName,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Users a On a.User_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY UserName
 	 ELSE IF @TableId = 37 --Production_Status
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Status] = ProdStatus_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Production_Status a On a.ProdStatus_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY  ProdStatus_Desc
 	 ELSE IF @TableId = 38 --Email_Message_Data
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Message] = substring(a.Message_Text,1,225), 
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Email_Message_Data a On a.Message_id = KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	 ELSE IF @TableId = 40 --Specifications
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Property]=Prop_Desc,
 	  	  	  	 [Specification] = Spec_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Specifications a On a.Spec_Id = t.KeyId
 	  	  	 JOIN Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Prop_Desc,Spec_Desc
 	 ELSE IF @TableId = 41 --Characteristics
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Property]=Prop_Desc,
 	  	  	  	 [Characteristic] = Char_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Characteristics a On a.Char_Id = t.KeyId
 	  	  	 JOIN Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Prop_Desc,Char_Desc
 	 ELSE IF @TableId = 43 --Prod_Units
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Prod_units a On a.PU_Id = t.KeyId
 	  	  	 JOIN Prod_Lines b on b.PL_Id = a.PL_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY PL_Desc,PU_Desc
 	 ELSE IF @TableId = 44 --Phrase
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Type] = Data_Type_Desc,
 	  	  	  	 [Phrase] = Phrase_Value,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Phrase a On a.Phrase_Id = t.KeyId
 	  	  	 JOIN data_Type b on b.Data_Type_Id = a.Data_Type_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Data_Type_Desc,Phrase_Value
 	 ELSE IF @TableId = 45 --Customer_Orders
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Customer_Orders a On a.Order_Id = t.KeyId
 	  	  	 JOIN Customer b on b.Customer_Id = a.Customer_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Customer_Code,Customer_Order_Number
 	 ELSE IF @TableId = 46 --Customer_Order_Line_Items
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Line Number] = Line_Item_Number,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Customer_Order_Line_Items a On a.Order_Line_Id = t.KeyId
 	  	  	 JOIN Customer_Orders b On b.Order_Id  = a.Order_Id
 	  	  	 JOIN Customer c on c.Customer_Id = b.Customer_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	 ORDER BY Customer_Code,Customer_Order_Number,Line_Item_Number
 	 ELSE IF @TableId = 47 --Customer_Order_Line_Details
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Line Number] = Line_Item_Number,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Customer_Order_Line_Details a On a.Order_Line_Detail_Id = t.KeyId
 	  	  	 JOIN Customer_Order_Line_Items b On b.Order_Line_Id = a.Order_Line_Id
 	  	  	 JOIN Customer_Orders c On c.Order_Id  = b.Order_Id
 	  	  	 JOIN Customer d on d.Customer_Id = c.Customer_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	 ORDER BY Customer_Code,Customer_Order_Number,Line_Item_Number
 	 ELSE IF @TableId = 48 --Shipment
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Shipment] = Shipment_Number,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Shipment a On a.Shipment_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Shipment_Number
 	 ELSE IF @TableId = 49 --Shipment_Line_Items
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Line Number] = Line_Item_Number,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Shipment_Line_Items a On a.Shipment_Item_Id = t.KeyId
 	  	  	 JOIN Customer_Order_Line_Items b On b.Order_Line_Id = a.Order_Line_Id
 	  	  	 JOIN Customer_Orders c On c.Order_Id  =  b.Order_Id
 	  	  	 JOIN Customer d on d.Customer_Id = c.Customer_Id
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Customer_Code,Customer_Order_Number,Line_Item_Number
 	 ELSE IF @TableId = 50 --Customer
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Customer a On a.Customer_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Customer_Code
 	 ELSE IF @TableId = 51 --Event_Subtypes
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [SubType] = Event_Subtype_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Event_Subtypes a On a.Event_Subtype_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Event_Subtype_Desc
 	 ELSE IF @TableId = 53 --BOM
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [BOM] = BOM_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Bill_Of_Material a On a.BOM_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY BOM_Desc
 	 ELSE IF @TableId = 54 --Product Properties
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Property] = Prop_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Product_Properties  a On a.Prop_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Prop_Desc
 	 ELSE IF @TableId = 56 -- select * from Engineering_Unit
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Eng Code] = Eng_Unit_Code,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Engineering_Unit  a On a.Eng_Unit_Id  = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Eng_Unit_Code
 	 ELSE IF @TableId = 57 -- select * from Bill_of_Material_Family
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [BOM Family] = BOM_Family_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Bill_of_Material_Family  a On a.BOM_Family_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY BOM_Family_Desc
 	 ELSE IF @TableId = 60 -- select * from  Containers sp_help Containers
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Container] = a.Container_Code ,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Containers  a On a.Container_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Container_Code
 	 ELSE IF @TableId = 61 -- select * from  Container_Classes
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Class] = a.Container_Class_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Container_Classes  a On a.Container_Class_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY a.Container_Class_Desc
 	 ELSE IF @TableId = 62 -- select * from  Container_Statuses
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Status] = a.Container_Status_Desc,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Container_Statuses  a On a.Container_Status_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY Container_Status_Desc
 	 ELSE IF @TableId = 63 -- select * from  Email_Groups
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Email Group] = a.EG_Desc ,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Email_Groups  a On a.EG_Id  = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY EG_Desc
 	 ELSE IF @TableId = 64 -- select * from  Historians
 	  	 SELECT [KEY] = Convert(nVarChar(10),t.Table_Field_Id) + 'zz' + Convert(nVarChar(10),KeyId),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + IsNull(Value,'') + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),KeyId) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [*] = ' ',
 	  	  	  	 [Id] = KeyId,
 	  	  	  	 [Historian Alias] = a.Alias,
 	  	  	  	 [Value 1] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,1),
 	  	  	  	 [Value 2] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,2),
 	  	  	  	 [Value 3] = dbo.fnEM_ConvertTableFieldValue(Value,tf.ED_Field_Type_Id,3)
 	  	  	 FROM Table_fields_values t
 	  	  	 JOIN Table_Fields tf On tf.Table_Field_Id = t.Table_Field_Id
 	  	  	 JOIN Historians  a On a.Hist_Id = t.KeyId
 	  	  	 WHERE t.TableId = @TableId And t.Table_Field_Id = @TableFieldId
 	  	  	 ORDER BY a.Alias 
