CREATE PROCEDURE dbo.spEM_IEImportUserDefinedProperty
@TableName  	  	 nVarChar(100),
@FieldName  	  	 nVarChar(100),
@FieldType  	  	 nVarChar(100),
@Key1 	  	   	 nVarChar(100),
@Key2 	  	   	 nVarChar(100),
@Key3 	  	   	 nVarChar(100),
@Value1 	   	  	 nvarchar(1000), 	 
@Value2 	   	  	 nvarchar(1000), 	 
@Value3 	   	  	 nvarchar(1000), 	 
@AddMissing 	  	 nvarchar(50),
@UserId 	  	  	 Int
AS
Declare 
 	 @TableId 	  	 int,
 	 @TableFieldId 	 int,
 	 @KeyId 	  	  	 int,
 	 @iAddMissing 	 Int,
 	 @FieldTypeId 	 Int,
 	 @ActualValue 	 nvarchar(1000)
Select @TableName = LTrim(RTrim(@TableName))
Select @FieldName = LTrim(RTrim(@FieldName))
Select @FieldType = LTrim(RTrim(@FieldType))
Select @Key1 = LTrim(RTrim(@Key1))
Select @Key2 = LTrim(RTrim(@Key2))
Select @Key3 = LTrim(RTrim(@Key3))
Select @Value1 = LTrim(RTrim(@Value1))
Select @Value2 = LTrim(RTrim(@Value2))
Select @Value3 = LTrim(RTrim(@Value3))
Select @AddMissing = LTrim(RTrim(@AddMissing))
---Audit trail changes
Declare @InsertId int
INSERT INTO Audit_Trail(Application_Id,User_id,Sp_Name,Parameters,StartTime)
 	 VALUES (1,@UserId,'spEM_IEImportUserDefinedProperty',
 	             ISNULL(@TableName,'')+','+
 	  	  	  	 ISNULL(@FieldName,'') +','+
 	  	  	  	 ISNULL(@FieldType,'') +','+
 	  	  	  	 ISNULL(@Key1,'') +','+
 	  	  	  	 ISNULL(@Key2,'') +','+
 	  	  	  	 ISNULL(@Key3,'') +','+
 	  	  	  	 ISNULL(@Value1,'') +','+
 	  	  	  	 ISNULL(@Value2,'') +','+
 	  	  	  	 ISNULL(@Value3,'') +','+
 	  	  	  	 ISNULL(@AddMissing,'') +','+
 	  	  	  	 Convert(nVarChar(10),@UserId), dbo.fnServer_CmnGetDate(getUTCdate()))
SELECT @InsertId = Scope_Identity()
---Audit trail changes
If @TableName = '' 	 Select @TableName = Null
If @FieldName = '' 	 Select @FieldName = Null
If @FieldType = '' 	 Select @FieldType = Null
If @Key1 = '' 	  	 Select @Key1 = Null
If @Key2 = '' 	  	 Select @Key2 = Null
If @Key3 = '' 	  	 Select @Key3 = Null
If @Value1 = '' 	  	 Select @Value1 = Null
If @Value2 = '' 	  	 Select @Value2 = Null
If @Value3 = '' 	  	 Select @Value3 = Null
If @AddMissing = '' 	 Select @AddMissing = Null
SELECT @TableId = Null
SELECT @TableFieldId = Null
SELECT @KeyId = Null
SELECT @FieldTypeId = Null
If @AddMissing = '0'
 	 Select @iAddMissing = 0
Else If  @AddMissing = '1'
 	 Select @iAddMissing = 1
Else
BEGIN
 	 Select 'Failed - Add Missing UDP must be True/False'
 	 Return (-100)
END
/**** Table  Id****/
IF @TableName Is Null
BEGIN
 	 Select 'Failed - Table Name is required'
 	 Return (-100)
END
SELECT @TableId = TableId FROM Tables WHERE TableName = @TableName and Allow_User_Defined_Property = 1
IF @TableId IS NULL
BEGIN
 	 Select 'Failed - Table Name not found'
 	 Return (-100)
END
/**** Table Field Id****/
SELECT @FieldTypeId = ED_Field_Type_Id FROM ed_FieldTypes WHERE Field_Type_Desc = @FieldType and User_Defined_Property = 1
IF @FieldTypeId Is Null
BEGIN
 	 Select 'Failed - Field Type not Valid'
 	 Return (-100)
END
IF @FieldName Is Null
BEGIN
 	 Select 'Failed - Field Description is required'
 	 Return (-100)
END
SELECT @TableFieldId = Table_Field_Id FROM Table_Fields WHERE Table_Field_Desc = @FieldName and TableId = @TableId
IF @TableFieldId IS NULL and @iAddMissing = 0
BEGIN
 	 Select 'Failed - Table Field Description not found'
 	 Return (-100)
END
IF @TableFieldId IS NULL  -- Add missing
BEGIN
 	 IF @FieldTypeId Is Null
 	 BEGIN
 	  	 Select 'Failed - Field Type is Needed for Add'
 	  	 Return (-100)
 	 END
 	 INSERT INTO Table_Fields(ED_Field_Type_Id,Table_Field_Desc,TableId) VALUES (@FieldTypeId,@FieldName,@TableId)
 	 SELECT @TableFieldId = Table_Field_Id FROM Table_Fields WHERE Table_Field_Desc = @FieldName and TableId = @TableId
 	 IF @TableFieldId IS NULL 
 	 BEGIN
 	  	 Select 'Failed - Unable to add Table Field Description '
 	  	 Return (-100)
 	 END
END
ELSE
BEGIN
 	 SELECT @TableFieldId = Null
 	 SELECT @TableFieldId = Table_Field_Id FROM Table_Fields WHERE Table_Field_Desc = @FieldName and TableId = @TableId and  ED_Field_Type_Id = @FieldTypeId
 	 IF @TableFieldId IS NULL 
 	 BEGIN
 	  	 Select 'Failed - Table Field Description with a different type already exists'
 	  	 Return (-100)
 	 END
END
/**** Table Key Id****/
 	 --  7           Production_Plan
 	 IF @TableId = 7
 	 BEGIN
 	  	 IF @Key1 Is Null
 	  	  	 SELECT @KeyId = PP_Id 
 	  	  	 FROM Production_Plan 
 	  	  	 WHERE Path_Id Is Null AND Process_Order = @Key2
 	  	 ELSE
 	  	  	 SELECT @KeyId = a.PP_Id 
 	  	  	 FROM Production_Plan a
 	  	  	 JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
  	  	  	 WHERE Path_Code = @Key1 AND Process_Order = @Key2
 	 END
 	 --  8           Production_Setup
 	 IF @TableId = 8
 	 BEGIN
 	  	 IF @Key1 Is Null
 	  	  	 SELECT @KeyId = PP_Setup_Id 
 	  	  	  	 FROM Production_Setup  c
 	  	  	  	 JOIN Production_Plan a On a.PP_Id = c.PP_Id
 	  	  	  	 WHERE a.Path_Id Is Null AND a.Process_Order = @Key2 and c.Pattern_Code = @Key3
 	  	 ELSE
 	  	  	 SELECT @KeyId = PP_Setup_Id 
 	  	  	  	 FROM Production_Setup  c
 	  	  	  	 JOIN Production_Plan a On a.PP_Id = c.PP_Id
 	  	  	  	 JOIN Prdexec_Paths b on b.Path_Id = a.Path_Id
 	  	  	  	 WHERE b.Path_Code = @Key1 AND a.Process_Order = @Key2 and c.Pattern_Code = @Key3
 	 END
 	 --  9           Production_Setup_Detail
 	 IF @TableId = 9
 	 BEGIN
 	  	 IF @Key1 Is Null
 	  	  	 SELECT @KeyId = PP_Setup_Detail_Id 
 	  	  	  	 FROM Production_Setup_Detail  a
 	  	  	  	 Join Production_Setup b on b.PP_Setup_Id =  a.PP_Setup_Id
 	  	  	  	 Join Production_Plan c On c.PP_Id = b.PP_Id
 	  	  	  	 WHERE c.Path_Id Is Null AND c.Process_Order = @Key2 and b.Pattern_Code = @Key3
 	  	 ELSE
 	  	  	 SELECT @KeyId = PP_Setup_Detail_Id 
 	  	  	  	 FROM Production_Setup_Detail  a
 	  	  	  	 Join Production_Setup b on b.PP_Setup_Id =  a.PP_Setup_Id
 	  	  	  	 Join Production_Plan c On c.PP_Id = b.PP_Id
 	  	  	  	 JOIN Prdexec_Paths d on d.Path_Id = c.Path_Id
 	  	  	  	 WHERE d.Path_Code = @Key1 AND c.Process_Order = @Key2 and b.Pattern_Code = @Key3
 	 END
 	 --  13          PrdExec_Paths
 	 IF @TableId = 13
 	 BEGIN
 	  	 SELECT @KeyId = Path_Id 
 	  	  	 FROM PrdExec_Paths  a
 	  	  	 WHERE a.Path_Code = @Key1 
 	 END 	 
 	 --  17          Departments
 	 IF @TableId = 17
 	 BEGIN
 	  	 SELECT @KeyId = Dept_Id 
 	  	  	 FROM Departments  a
 	  	  	 WHERE a.Dept_Desc = @Key1 
 	 END 	 
 	 --  18          Prod_Lines
 	 IF @TableId = 18
 	 BEGIN
 	  	 SELECT @KeyId = PL_Id 
 	  	  	 FROM Prod_Lines  a
 	  	  	 WHERE a.PL_Desc = @Key1 
 	 END 	 
 	 --  19          PU_Groups
 	 IF @TableId = 19
 	 BEGIN
 	  	 SELECT @KeyId = a.PUG_Id 
 	  	  	 FROM PU_Groups  a
 	  	  	 Join Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 Join Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE c.PL_Desc = @Key1  and b.PU_Desc = @Key2 and a.PUG_Desc = @Key3 
 	 END 	 
 	 --  20          Variables
 	 IF @TableId = 20
 	 BEGIN
 	  	 SELECT @KeyId = a.Var_Id 
 	  	  	 FROM Variables  a
 	  	  	 Join Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 Join Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE c.PL_Desc = @Key1  and b.PU_Desc = @Key2 and a.Var_Desc = @Key3 
 	 END 	 
 	 --  21          Product_Family
 	 IF @TableId = 21
 	 BEGIN
 	  	 SELECT @KeyId = Product_Family_Id 
 	  	  	 FROM Product_Family  a
 	  	  	 WHERE a.Product_Family_Desc = @Key1 
 	 END 	 
 	 --  22          Product_Groups
 	 IF @TableId = 22
 	 BEGIN
 	  	 SELECT @KeyId = Product_Grp_Id 
 	  	  	 FROM Product_Groups  a
 	  	  	 WHERE a.Product_Grp_Desc = @Key1 
 	 END 	 
 	 --  23          Products
 	 IF @TableId = 23
 	 BEGIN
 	  	 SELECT @KeyId = Prod_Id 
 	  	  	 FROM Products  a
 	  	  	 WHERE a.Prod_Code = @Key1 
 	 END 	 
 	 --  24          Event_Reasons
 	 IF @TableId = 24
 	 BEGIN
 	  	 SELECT @KeyId = Event_Reason_Id 
 	  	  	 FROM Event_Reasons  a
 	  	  	 WHERE a.Event_Reason_Name = @Key1 
 	 END 	 
 	 --  25          Event_Reason_Catagories
 	 IF @TableId = 25
 	 BEGIN
 	  	 SELECT @KeyId = ERC_Id 
 	  	  	 FROM Event_Reason_Catagories  a
 	  	  	 WHERE a.ERC_Desc = @Key1 
 	 END 	 
 	 --  26          Bill_Of_Material_Formulation
 	 IF @TableId = 26
 	 BEGIN
 	  	 SELECT @KeyId = BOM_Formulation_Id 
 	  	  	 FROM Bill_Of_Material_Formulation  a
 	  	  	 WHERE a.BOM_Formulation_Desc = @Key1 
 	 END 	 
 	 --  27          Subscription
 	 IF @TableId = 27
 	 BEGIN
 	  	 SELECT @KeyId = Subscription_Id 
 	  	  	 FROM Subscription  a
 	  	  	 WHERE a.Subscription_Desc = @Key1 
 	 END 	 
 	 --  28          Bill_Of_Material_Formulation_Item
 	 IF @TableId = 28
 	 BEGIN
 	  	 SELECT @KeyId = BOM_Formulation_Item_Id 
 	  	  	 FROM Bill_Of_Material_Formulation_Item  a
 	  	  	 Join Bill_Of_Material_Formulation b On b.BOM_Formulation_Id = a.BOM_Formulation_Id
 	  	  	 WHERE b.BOM_Formulation_Desc = @Key1 AND a.BOM_Formulation_Order = @Key2
 	 END 	 
 	 --  29          Subscription_Group
 	 IF @TableId = 29
 	 BEGIN
 	  	 SELECT @KeyId = Subscription_Group_Id 
 	  	  	 FROM Subscription_Group  a
 	  	  	 WHERE a.Subscription_Group_Desc = @Key1 
 	 END 	 
 	 --  30          PrdExec_Path_Units
 	 IF @TableId = 30
 	 BEGIN
 	  	 SELECT @KeyId = a.PEPU_Id 
 	  	  	 FROM PrdExec_Path_Units  a
 	  	  	 Join Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 Join Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 Join PrdExec_Paths d On d.Path_Id = a.Path_Id
 	  	  	 WHERE c.PL_Desc = @Key1  and b.PU_Desc = @Key2 and d.Path_Code = @Key3 
 	 END 	 
 	 --  31          Report_Types
 	 IF @TableId = 31
 	 BEGIN
 	  	 SELECT @KeyId = Report_Type_Id 
 	  	  	 FROM Report_Types  a
 	  	  	 WHERE a.[Description] = @Key1 
 	 END 	 
 	 --  32          Report_Definitions
 	 IF @TableId = 32
 	 BEGIN
 	  	 SELECT @KeyId = Report_Id 
 	  	  	 FROM Report_Definitions  a
 	  	  	 WHERE a.[Report_Name] = @Key1 
 	 END 	 
 	 --  34          Production_Plan_Statuses
 	 IF @TableId = 34
 	 BEGIN
 	  	 SELECT @KeyId = PP_Status_Id 
 	  	  	 FROM Production_Plan_Statuses  a
 	  	  	 WHERE a.PP_Status_Desc = @Key1 
 	 END 	 
 	 --  35          PrdExec_Inputs
 	 IF @TableId = 35
 	 BEGIN
 	  	 SELECT @KeyId = a.PEI_Id 
 	  	  	 FROM PrdExec_Inputs  a
 	  	  	 Join Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 Join Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE c.PL_Desc = @Key1  and b.PU_Desc = @Key2 and a.Input_Name = @Key3 
 	 END 	 
 	 --  36          Users
 	 IF @TableId = 36
 	 BEGIN
 	  	 SELECT @KeyId = [User_Id] 
 	  	  	 FROM Users  a
 	  	  	 WHERE a.Username = @Key1 
 	 END 	 
 	 --  37          Production_Status
 	 IF @TableId = 37
 	 BEGIN
 	  	 SELECT @KeyId = ProdStatus_Id 
 	  	  	 FROM Production_Status  a
 	  	  	 WHERE a.ProdStatus_Desc = @Key1 
 	 END 	 
 	 --  38          Email_Message_Data
 	 IF @TableId = 38
 	 BEGIN
 	  	 SELECT @KeyId = Convert(Int,@Key1)
 	 END 	 
 	 --  40          Specifications
 	 IF @TableId = 40
 	 BEGIN
 	  	 SELECT @KeyId = a.Spec_Id 
 	  	  	 FROM Specifications  a
 	  	  	 Join Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 WHERE b.Prop_Desc = @Key1 AND a.Spec_Desc = @Key2
 	 END 	 
 	 --  41          Characteristics
 	 IF @TableId = 41
 	 BEGIN
 	  	 SELECT @KeyId = a.Char_Id 
 	  	  	 FROM Characteristics  a
 	  	  	 Join Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 WHERE b.Prop_Desc = @Key1 AND a.Char_Desc = @Key2
 	 END 	 
 	 --  43          Prod_Units
 	 IF @TableId = 43
 	 BEGIN
 	  	 SELECT @KeyId = a.PU_Id 
 	  	  	 FROM Prod_units  a
 	  	  	 Join Prod_Lines b On b.PL_Id = a.PL_Id
 	  	  	 WHERE b.PL_Desc = @Key1  and a.PU_Desc = @Key2 
 	 END 	 
 	 --  44          Phrase
 	 IF @TableId = 44
 	 BEGIN
 	  	 SELECT @KeyId = a.Phrase_Id 
 	  	  	 FROM Phrase  a
 	  	  	 Join Data_Type b On b.Data_Type_Id = a.Data_Type_Id
 	  	  	 WHERE b.Data_Type_Desc = @Key1  and a.Phrase_Value = @Key2 
 	 END 	 
 	 --  45          Customer_Orders
 	 IF @TableId = 45
 	 BEGIN
 	  	 SELECT @KeyId = a.Order_Id 
 	  	  	 FROM Customer_Orders  a
 	  	  	 Join Customer b On b.Customer_Id = a.Customer_Id
 	  	  	 WHERE b.Customer_Code = @Key1  and a.Customer_Order_Number = @Key2 
 	 END 	 
 	 --  46          Customer_Order_Line_Items
 	 IF @TableId = 46
 	 BEGIN
 	  	 SELECT @KeyId = a.Order_Line_Id 
 	  	  	 FROM Customer_Order_Line_Items  a
 	  	  	 Join Customer_Orders b On b.Order_Id = a.Order_Id
 	  	  	 Join Customer c on c.Customer_Id = b.Customer_Id
 	  	  	 WHERE c.Customer_Code = @Key1  and b.Customer_Order_Number = @Key2 and a.Line_Item_Number = @Key3 
 	 END 	 
 	 --  47          Customer_Order_Line_Details
 	 IF @TableId = 47
 	 BEGIN
 	  	 SELECT @KeyId = a.Order_Line_Detail_Id 
 	  	  	 FROM Customer_Order_Line_Details a 
 	  	  	 JOIN Customer_Order_Line_Items  b ON  b.Order_Line_Id = a.Order_Line_Id
 	  	  	 Join Customer_Orders c On b.Order_Id = b.Order_Id
 	  	  	 Join Customer d on d.Customer_Id = c.Customer_Id
 	  	  	 WHERE d.Customer_Code = @Key1  and c.Customer_Order_Number = @Key2 and b.Line_Item_Number = @Key3 
 	 END 	 
 	 --  48          Shipment
 	 IF @TableId = 48
 	 BEGIN
 	  	 SELECT @KeyId = a.Shipment_Id 
 	  	  	 FROM Shipment  a
 	  	  	 WHERE a.Shipment_Number = @Key1  
 	 END 	 
 	 --  49          Shipment_Line_Items
 	 IF @TableId = 49
 	 BEGIN
 	  	 SELECT @KeyId = a.Shipment_Item_Id 
 	  	  	 FROM Shipment_Line_Items a 
 	  	  	 JOIN Customer_Order_Line_Items  b ON  b.Order_Line_Id = a.Order_Line_Id
 	  	  	 Join Customer_Orders c On b.Order_Id = b.Order_Id
 	  	  	 Join Customer d on d.Customer_Id = c.Customer_Id
 	  	  	 WHERE d.Customer_Code = @Key1  and c.Customer_Order_Number = @Key2 and b.Line_Item_Number = @Key3 
 	 END 	 
 	 --  50          Customer
 	 IF @TableId = 50
 	 BEGIN
 	  	 SELECT @KeyId = a.Customer_Id 
 	  	  	 FROM Customer a 
 	  	  	 WHERE a.Customer_Code = @Key1  
 	 END 	 
 	 --  51          Event_Subtypes
 	 IF @TableId = 51
 	 BEGIN
 	  	 SELECT @KeyId = a.Event_Subtype_Id 
 	  	  	 FROM Event_Subtypes a 
 	  	  	 WHERE a.Event_Subtype_Desc = @Key1  
 	 END 	 
 	 IF @KeyId IS NULL
 	 BEGIN
 	  	  	 Select 'Failed - Unable to find key record'
 	  	  	 Return (-100)
 	 END
/********* Values ********/
 	 IF @FieldTypeId in(1,76,79) --Text--DE84727 for include NPT n OEE type UD parameters
 	 BEGIN
 	  	 SELECT @ActualValue = @Value1
 	 END 	 
 	 IF @FieldTypeId in (2,69) -- Numeric
 	 BEGIN
 	  	 IF  Isnumeric(@Value1) = 0
 	  	 BEGIN
 	  	  	 Select 'Failed - Value Must Be Numeric'
 	  	  	 Return (-100)
 	  	 END
 	  	 SELECT @ActualValue = @Value1
 	 END 	 
 	 IF @FieldTypeId = 9 -- Unit Id
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.PU_Id)
 	  	  	 FROM Prod_units  a
 	  	  	 Join Prod_Lines b On b.PL_Id = a.PL_Id
 	  	  	 WHERE b.PL_Desc = @Value1  and a.PU_Desc = @Value2 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Unit Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 10 -- Variable Id
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10), a.Var_Id)
 	  	  	 FROM Variables  a
 	  	  	 Join Prod_units b On b.PU_Id = a.PU_Id
 	  	  	 Join Prod_Lines c on c.PL_Id = b.PL_Id
 	  	  	 WHERE c.PL_Desc = @Value1  and b.PU_Desc = @Value2 and a.Var_Desc = @Value3 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find variable Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 11 -- File Path
 	 BEGIN
 	  	 SELECT @ActualValue = @Value1
 	 END 	 
 	 IF @FieldTypeId = 12 -- DateTime
 	 BEGIN
 	  	 IF  Isdate(@Value1) = 1 and charindex(':',@Value1) > 0 and len(@Value1) > 4
 	  	 BEGIN
 	  	  	 SELECT @ActualValue = @Value1
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Select 'Failed - Value Must Be Time'
 	  	  	 Return (-100)
 	  	 END
 	 END 	 
 	 IF @FieldTypeId = 16 -- Production Status
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),ProdStatus_Id)
 	  	 FROM Production_Status  a
 	  	  	 WHERE a.ProdStatus_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Status Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 22 --True/False (store 1/0)
 	 BEGIN
 	  	 If @Value1 = '0' or @Value1 = '1'
 	  	 BEGIN
 	  	  	 SELECT @ActualValue = @Value1
 	  	 END
 	  	 ELSE
 	  	 BEGIN
 	  	  	 Select 'Failed - Value must be True/False'
 	  	  	 Return (-100)
 	  	 END
 	 END 	 
 	 IF @FieldTypeId = 23 --Characteristic
 	 BEGIN 	  	 
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Char_Id )
 	  	  	 FROM Characteristics  a
 	  	  	 Join Product_Properties b On b.Prop_Id = a.Prop_Id
 	  	  	 WHERE b.Prop_Desc = @Value1 AND a.Char_Desc = @Value2
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Char Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 24 --Color Scheme
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.CS_Id )
 	  	  	 FROM Color_Scheme  a
 	  	  	 WHERE a.CS_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Color Scheme Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 27 --Event Type
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.ET_Id )
 	  	  	 FROM Event_Types  a
 	  	  	 WHERE a.ET_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Event Type Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 30 --Access Level
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.AL_Id )
 	  	  	 FROM Access_Level  a
 	  	  	 WHERE a.AL_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Access Level Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 34 --Colors
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Color_Id )
 	  	  	 FROM colors  a
 	  	  	 WHERE a.Color_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Color Id for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 35 --Customer
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Customer_Id )
 	  	  	 FROM Customer  a
 	  	  	 WHERE a.Customer_Code = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Customer code for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 36 --Product
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Prod_Id )
 	  	  	 FROM Products  a
 	  	  	 WHERE a.Prod_Code = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Product Code for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 37 --Product Group
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Product_Grp_Id )
 	  	  	 FROM Product_Groups  a
 	  	  	 WHERE a.Product_Grp_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Product Group for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 39  ---Reason Tree
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Tree_Name_Id )
 	  	  	 FROM Event_Reason_Tree  a
 	  	  	 WHERE a.Tree_Name = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Reason Tree for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 40 --Reason By Tree
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Event_Reason_Id )
 	  	  	 FROM Event_Reasons  a
 	  	  	 WHERE a.Event_Reason_Name = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Reason for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 51 --spLocal - Stored Procedure Name
 	 BEGIN
 	  	 SELECT @ActualValue = @Value1
 	  	 IF  @ActualValue Is Null
 	  	 BEGIN
 	  	  	 Select 'Failed - Unable to find value'
 	  	  	 Return (-100)
 	  	 END
 	 END 	 
 	 IF @FieldTypeId = 59 --Production Plan Path
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Path_Id )
 	  	  	 FROM PrdExec_Paths  a
 	  	  	 WHERE a.Path_Code = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Path code for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 61 --Product Family
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.Product_Family_Id )
 	  	  	 FROM Product_Family  a
 	  	  	 WHERE a.Product_Family_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Product family for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
 	 IF @FieldTypeId = 63 --Data Source
 	 BEGIN
 	  	 SELECT @ActualValue = Convert(nVarChar(10),a.DS_Id )
 	  	  	 FROM Data_Source  a
 	  	  	 WHERE a.DS_Desc = @Value1 
 	  	  	 IF  @ActualValue Is Null
 	  	  	 BEGIN
 	  	  	  	 Select 'Failed - Unable to find Data Source for value'
 	  	  	  	 Return (-100)
 	  	  	 END
 	 END 	 
IF @ActualValue Is Null
BEGIN
 	 DELETE FROM Table_Fields_Values 
 	  	 WHERE TableId = @TableId 
 	  	  	 and KeyId = @KeyId 
 	  	  	 And Table_Field_Id = @TableFieldId
END
ELSE
BEGIN
 	 IF EXISTS(SELECT 1 FROM Table_Fields_Values WHERE TableId = @TableId and KeyId = @KeyId And Table_Field_Id = @TableFieldId)
 	 BEGIN
 	  	 UPDATE Table_Fields_Values SET Value = @ActualValue WHERE TableId = @TableId and KeyId = @KeyId And Table_Field_Id = @TableFieldId
 	 END
 	 ELSE
 	 BEGIN
 	  	 INSERT INTO Table_Fields_Values(KeyId,Table_Field_Id,TableId,Value) Values (@KeyId,@TableFieldId,@TableId,@ActualValue)
 	 END
END
UPDATE  Audit_Trail SET EndTime = dbo.fnServer_CmnGetDate(getUTCdate()),ReturnCode = 0
WHERE Audit_Trail_Id = @InsertId
RETURN(0)
