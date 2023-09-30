Create Procedure dbo.spEMTFV_LookupField 
@TableId 	  	 int,
@TableFieldId 	 Int
AS
--Select * from tables where Allow_User_Defined_Property = 1 order by TableId
If @TableId = 7 -- Production_Plan
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PP_Id) ,
 	  	  	  	 [TAG] = Char(1) + '1' + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PP_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PP_Id,
 	  	  	  	 [Code] = b.Path_Code,
 	  	  	  	 [Order] = a.Process_Order
 	  	  	 FROM Production_Plan a 
 	  	  	 LEFT JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	  	 ORDER BY  b.Path_Code,a.Process_Order
  END
Else If @TableId = 8 --Production_Setup
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),c.PP_Setup_Id) ,
 	  	  	  	 [TAG] = Char(1) + '1' + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),c.PP_Setup_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = c.PP_Setup_Id,
 	  	  	  	 [Code] = b.Path_Code,
 	  	  	  	 [Order] = a.Process_Order,
 	  	  	  	 [Pattern] = c.Pattern_Code
 	  	  	 FROM  Production_Setup c
 	  	  	 JOIN Production_Plan a On a.PP_Id = c.PP_Id
 	  	  	 Left JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	  	 ORDER BY b.Path_Code,a.Process_Order,c.Pattern_Code
  END
Else If @TableId = 9 -- Production_Setup_Detail
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PP_Setup_Detail_Id) ,
 	  	  	  	 [TAG] = Char(1) + '1' + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PP_Setup_Detail_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PP_Setup_Detail_Id,
 	  	  	  	 [Code] = d.Path_Code,
 	  	  	  	 [Order] = c.Process_Order,
 	  	  	  	 [Pattern] = b.Pattern_Code
 	  	  	 FROM  Production_Setup_Detail a 
 	  	  	 JOIN  Production_Setup b on b.PP_Setup_Id =  a.PP_Setup_Id
 	  	  	 JOIN Production_Plan c On c.PP_Id = b.PP_Id
 	  	  	 Left JOIN Prdexec_Paths d on d.Path_Id = c.Path_Id
 	  	  	 ORDER BY d.Path_Code,c.Process_Order,b.Pattern_Code
 	  END
Else If @TableId = 13 -- PrdExec_Paths
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Path_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Path_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Path_Id,
 	  	  	  	 [Code] = Path_Code
 	  	  	 FROM PrdExec_Paths a 
 	  	  	 ORDER BY Path_Code
  END
Else If @TableId = 17 -- Departments
  BEGIN
 	  	 SELECT 	 [KEY] = Convert(nVarChar(10),a.Dept_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Dept_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Dept_Id,
 	  	  	  	 [Deparment] = Dept_Desc
 	  	  	 FROM Departments a 
 	  	  	 ORDER BY Dept_Desc
  END
Else If @TableId = 18 -- Prod_Lines
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),b.PL_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),b.PL_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = b.PL_Id,
 	  	  	  	 [Line] = PL_Desc
 	  	  	 FROM  Prod_Lines b 
 	  	  	 WHERE b.PL_Id > 0
 	  	  	 ORDER BY PL_Desc
  END
Else If @TableId = 19 --PU_Groups
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PUG_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PUG_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PUG_Id,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Group]= PUG_Desc
 	  	  	 FROM  PU_Groups a 
 	  	  	 JOIN Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 JOIN Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE PUG_ID > 0
 	  	  	 ORDER BY PL_Desc,PU_Desc,PUG_Desc
  END
Else If @TableId = 21 --Product_Family 
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Product_Family_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Product_Family_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Product_Family_Id,
 	  	  	  	 [Family] = Product_Family_Desc
 	  	  	 FROM  Product_Family a 
 	  	  	 ORDER BY Product_Family_Desc
  END
Else If @TableId = 22 -- Product_Groups
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Product_Grp_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Product_Grp_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Product_Grp_Id,
 	  	  	  	 [Product Group] = Product_Grp_Desc
 	  	  	 FROM  Product_Groups a 
 	  	  	 ORDER BY Product_Grp_Desc
  END
Else If @TableId = 23 --Products
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Prod_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Prod_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Prod_Id,
 	  	  	  	 [Product Code] = Prod_Code
 	  	  	 FROM  Products a 
 	  	  	 ORDER BY Prod_Code
  END
Else If @TableId = 24 --Event_Reasons
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Event_Reason_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Event_Reason_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Event_Reason_Id,
 	  	  	  	 [Reason] = Event_Reason_Name
 	  	  	 FROM  Event_Reasons a 
 	  	  	 ORDER BY Event_Reason_Name
  END
Else If @TableId = 25--Event_Reason_Catagories
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.ERC_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.ERC_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.ERC_Id,
 	  	  	  	 [Category] = Erc_Desc
 	  	  	 FROM Event_Reason_Catagories a 
 	  	  	 WHERE ERC_Id <> 100
 	  	  	 ORDER BY Erc_Desc
  END
Else If @TableId = 26 -- Bill_Of_Material_Formulation
  BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.BOM_Formulation_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.BOM_Formulation_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.BOM_Formulation_Id,
 	  	  	  	 [Formulation] = BOM_Formulation_Desc
 	  	  	 FROM  Bill_Of_Material_Formulation a 
 	  	  	 ORDER BY BOM_Formulation_Desc
  END
Else If @TableId = 27 -- Subscription
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Subscription_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Subscription_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Subscription_Id,
 	  	  	  	 [Subscription] = Subscription_Desc
 	  	  	 FROM Subscription a 
 	  	  	 ORDER BY Subscription_Desc
END 
Else If @TableId = 28 --Bill_Of_Material_Formulation_Item
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.BOM_Formulation_Item_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.BOM_Formulation_Item_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.BOM_Formulation_Item_Id,
 	  	  	  	 [BOM Formulation] = BOM_Formulation_Desc,
 	  	  	  	 [Order] = BOM_Formulation_Order
 	  	  	 FROM  Bill_Of_Material_Formulation_Item a 
 	  	  	 JOIN Bill_Of_Material_Formulation b On b.BOM_Formulation_Id = a.BOM_Formulation_Id
 	  	  	 ORDER BY BOM_Formulation_Desc,BOM_Formulation_Order
END 
Else If @TableId = 29  --Subscription_Group
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Subscription_Group_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Subscription_Group_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Subscription_Group_Id,
 	  	  	  	 [Subscription Group] = Subscription_Group_Desc
 	  	  	 FROM  Subscription_Group a
 	  	  	 order by Subscription_Group_Desc
END 
Else If @TableId = 30 --PrdExec_Path_Units
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PEPU_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PEPU_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PEPU_Id,
 	  	  	  	 [Path] = Path_Code,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc
 	  	  	 FROM PrdExec_Path_Units a 
 	  	  	 JOIN Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 JOIN Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 JOIN PrdExec_Paths d On d.Path_Id = a.Path_Id
 	  	  	 ORDER BY Path_Code,PL_Desc,PU_Desc
END 
Else If @TableId = 31 --Report_Types
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Report_Type_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Report_Type_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Report_Type_Id,
 	  	  	  	 [Type] = [Description]
 	  	 FROM  Report_Types a 
 	  	 ORDER BY [Description]
END 
Else If @TableId = 32 --Report_Definitions
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Report_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Report_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Report_Id,
 	  	  	  	 [Report] = [Report_Name]
 	  	  	 FROM Report_Definitions a 
 	  	  	 ORDER BY [Report_Name]
END 
Else If @TableId = 34  --Production_Plan_Statuses
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PP_Status_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PP_Status_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PP_Status_Id,
 	  	  	  	 [Status] = PP_Status_Desc
 	  	  	 FROM  Production_Plan_Statuses a
 	  	  	 ORDER BY PP_Status_Desc
END 
Else If @TableId = 35 -- PrdExec_Inputs
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PEI_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PEI_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PEI_Id,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc,
 	  	  	  	 [Input]= Input_Name
 	  	  	 FROM  PrdExec_Inputs a 
 	  	  	 JOIN Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 JOIN Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 ORDER BY PL_Desc,PU_Desc,Input_Name
END 
Else If @TableId = 36 --Users
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.User_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.User_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.User_Id,
 	  	  	  	 [User] = UserName
 	  	  	 FROM  Users a 
 	  	  	 WHERE a.User_id <> 50
 	  	  	 ORDER BY UserName
END 
Else If @TableId = 37  --Production_Status
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.ProdStatus_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.ProdStatus_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.ProdStatus_Id,
 	  	  	  	 [Status] = ProdStatus_Desc
 	  	  	 FROM  Production_Status a 
 	  	  	 ORDER BY  ProdStatus_Desc
END 
Else If @TableId = 38  --Email_Message_Data
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Message_id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Message_id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Message_id,
 	  	  	  	 [Message] = substring(a.Message_Text,1,225) 
 	  	  	 FROM Email_Message_Data a
 	  	  	 Order by a.Message_id
END 
Else If @TableId = 40 --Specifications
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Spec_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Spec_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Spec_Id,
 	  	  	  	 [Property]=Prop_Desc,
 	  	  	  	 [Specification] = Spec_Desc
 	  	  	 FROM Specifications a 
 	  	  	 JOIN Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 ORDER BY Prop_Desc,Spec_Desc
END 
Else If @TableId = 41  -- Characteristics
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Char_Id) ,
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Char_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Char_Id,
 	  	  	  	 [Property]=Prop_Desc,
 	  	  	  	 [Characteristic] = Char_Desc
 	  	  	 FROM  Characteristics a 
 	  	  	 JOIN Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 ORDER BY Prop_Desc,Char_Desc
END 
Else If @TableId = 43--Prod_Units
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.PU_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.PU_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.PU_Id,
 	  	  	  	 [Line] = PL_Desc,
 	  	  	  	 [Unit] = PU_Desc
 	  	  	 FROM Prod_units a 
 	  	  	 JOIN Prod_Lines b on b.PL_Id = a.PL_Id
 	  	  	 WHERE PU_Id > 0
 	  	  	 ORDER BY PL_Desc,PU_Desc
END 
Else If @TableId = 44 --Phrase
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Phrase_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Phrase_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Phrase_Id,
 	  	  	  	 [Type] = Data_Type_Desc,
 	  	  	  	 [Phrase] = Phrase_Value
 	  	  	 FROM  Phrase a 
 	  	  	 JOIN data_Type b on b.Data_Type_Id = a.Data_Type_Id
 	  	  	 ORDER BY Data_Type_Desc,Phrase_Value
END 
Else If @TableId = 45 --Customer_Orders
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Order_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Order_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Order_Id,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number
 	  	  	 FROM Customer_Orders a 
 	  	  	 JOIN Customer b on b.Customer_Id = a.Customer_Id
 	  	  	 ORDER BY Customer_Code,Customer_Order_Number
END 
Else If @TableId = 46 --Customer_Order_Line_Items
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Order_Line_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Order_Line_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Order_Line_Id,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Line Number] = Line_Item_Number
 	  	  	 FROM Customer_Order_Line_Items a 
 	  	  	 JOIN Customer_Orders b On b.Order_Id  = a.Order_Id
 	  	  	 JOIN Customer c on c.Customer_Id = b.Customer_Id
 	  	 ORDER BY Customer_Code,Customer_Order_Number,Line_Item_Number
END 
Else If @TableId = 47 --Customer_Order_Line_Details
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Order_Line_Detail_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Order_Line_Detail_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Order_Line_Detail_Id,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Line Number] = Line_Item_Number
 	  	  	 FROM  Customer_Order_Line_Details a 
 	  	  	 JOIN Customer_Order_Line_Items b On b.Order_Line_Id = a.Order_Line_Id
 	  	  	 JOIN Customer_Orders c On c.Order_Id  = b.Order_Id
 	  	  	 JOIN Customer d on d.Customer_Id = c.Customer_Id
 	  	 ORDER BY Customer_Code,Customer_Order_Number,Line_Item_Number
END 
Else If @TableId = 48 --Shipment
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Shipment_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Shipment_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Shipment_Id,
 	  	  	  	 [Shipment] = Shipment_Number
 	  	  	 FROM Shipment a 
 	  	  	 ORDER BY Shipment_Number
END 
Else If @TableId = 49  --Shipment_Line_Items
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Shipment_Item_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Shipment_Item_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Shipment_Item_Id,
 	  	  	  	 [Customer] = Customer_Code,
 	  	  	  	 [Order] = Customer_Order_Number,
 	  	  	  	 [Line Number] = Line_Item_Number
 	  	  	 FROM  Shipment_Line_Items a 
 	  	  	 JOIN Customer_Order_Line_Items b On b.Order_Line_Id = a.Order_Line_Id
 	  	  	 JOIN Customer_Orders c On c.Order_Id  =  b.Order_Id
 	  	  	 JOIN Customer d on d.Customer_Id = c.Customer_Id
 	  	  	 ORDER BY Customer_Code,Customer_Order_Number,Line_Item_Number
END 
Else If @TableId = 50 --Customer
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Customer_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Customer_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Customer_Id,
 	  	  	  	 [Customer] = Customer_Code
 	  	  	 FROM  Customer a
 	  	  	 ORDER BY Customer_Code
END 
Else If @TableId = 51 --Event_Subtypes
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Event_Subtype_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Event_Subtype_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Event_Subtype_Id,
 	  	  	  	 [SubType] = Event_Subtype_Desc
 	  	  	 FROM  Event_Subtypes a 
 	  	  	 ORDER BY Event_Subtype_Desc
END 
Else If @TableId = 53 --BOM
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.BOM_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.BOM_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.BOM_Id,
 	  	  	  	 [BOM] = BOM_Desc
 	  	  	 FROM  Bill_Of_Material a 
 	  	  	 ORDER BY BOM_Desc
END 
Else If @TableId = 54 -- Product Properties
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Prop_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Prop_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Prop_Id,
 	  	  	  	 [Property] = Prop_Desc
 	  	  	 FROM  Product_Properties a 
 	  	  	 ORDER BY Prop_Desc
END 
Else If @TableId = 56 -- Engineering_Unit
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Eng_Unit_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Eng_Unit_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Eng_Unit_Id,
 	  	  	  	 [Eng Unit] = a.Eng_Unit_Code 
 	  	  	 FROM  Engineering_Unit a 
 	  	  	 WHERE a.Eng_Unit_Id <> 50000
 	  	  	 ORDER BY a.Eng_Unit_Code 
END
Else If @TableId = 57 -- Bill_of_Material_Family
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.BOM_Family_Id ),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.BOM_Family_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.BOM_Family_Id,
 	  	  	  	 [BOM Family] = a.BOM_Family_Desc 
 	  	  	 FROM  Bill_of_Material_Family a 
 	  	  	 ORDER BY a.BOM_Family_Desc
END
Else If @TableId = 60 -- Containers
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Container_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Container_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Container_Id,
 	  	  	  	 [Property] = a.Container_Code 
 	  	  	 FROM  Containers a 
 	  	  	 ORDER BY a.Container_Code 
END
Else If @TableId = 61 -- Container_Classes
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Container_Class_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Container_Class_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Container_Class_Id,
 	  	  	  	 [Property] = a.Container_Class_Desc
 	  	  	 FROM  Container_Classes a 
 	  	  	 ORDER BY Container_Class_Desc
END
Else If @TableId = 62 -- Container_Statuses
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Container_Status_Id ),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Container_Status_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Container_Status_Id,
 	  	  	  	 [Property] = a.Container_Status_Desc
 	  	  	 FROM  Container_Statuses a 
 	  	  	 ORDER BY a.Container_Status_Desc
END
Else If @TableId = 63 -- Email_Groups
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.EG_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.EG_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.EG_Id,
 	  	  	  	 [Property] = a.EG_Desc
 	  	  	 FROM  Email_Groups a 
 	  	  	 WHERE a.EG_Id <> 50
 	  	  	 ORDER BY a.EG_Desc
END
Else If @TableId = 64 -- Historians
BEGIN
 	  	 SELECT [KEY] = Convert(nVarChar(10),a.Hist_Id),
 	  	  	  	 [TAG] = Char(1) + '1' + Char(1) + '' + Char(2) 
 	  	  	  	  	 + Char(1) + '2' + Char(1) + Convert(nVarChar(10),a.Hist_Id) + Char(2) 
 	  	  	  	  	 + dbo.fnEM_TableFieldTagCmn(@TableFieldId,@TableId),
 	  	  	  	 [Id] = a.Hist_Id,
 	  	  	  	 [Property] = a.Alias
 	  	  	 FROM  Historians a 
 	  	  	 ORDER BY a.Alias
END
