--    spEM_IEImportCrossReference 'sap','Prod_Lines','dsafds','Production Line #1','','',1
CREATE PROCEDURE dbo.spEM_IEImportCrossReference 
@DSDesc 	  	  	  	 nvarchar(255),
@TableDesc 	  	 nvarchar(255),
@FKDesc 	  	  	  	 nvarchar(255),
@Field1Desc 	  	 nvarchar(255),
@Field2Desc  	 nvarchar(255),
@Field3Desc  	 nvarchar(255),
@CustomDesc  	 nvarchar(255),
@SubStription 	 nvarchar(255),
@XMLData 	  	   	 nvarchar(255),
@User_Id  	  	  	 Int
AS
Declare 	 @DS_Id 	  	  	  	 Int,
 	  	  	  	 @Table_Id 	  	  	 Int,
 	  	  	  	 @Actual_Id 	  	 Int,
 	  	  	  	 @DS_XRefId 	  	 Int,
 	  	  	  	 @subscriptionId 	 Int
Select @DSDesc = LTrim(RTrim(@DSDesc))
Select @TableDesc = LTrim(RTrim(@TableDesc))
Select @FKDesc = LTrim(RTrim(@FKDesc))
Select @Field1Desc = LTrim(RTrim(@Field1Desc))
Select @Field2Desc = LTrim(RTrim(@Field2Desc))
Select @Field3Desc = LTrim(RTrim(@Field3Desc))
Select @CustomDesc = LTrim(RTrim(@CustomDesc))
Select @SubStription = LTrim(RTrim(@SubStription))
Select @XMLData 	  	  	  = LTrim(RTrim(@XMLData))
If @DSDesc = '' Select @DSDesc = null
If @TableDesc = '' Select @TableDesc = null
If @FKDesc = '' Select @FKDesc = null
If @Field1Desc = '' Select @Field1Desc = null
If @Field2Desc = '' Select @Field2Desc = null
If @Field3Desc = '' Select @Field3Desc = null
If @CustomDesc = '' Select @CustomDesc = null
If @SubStription = '' Select @SubStription = null
If @TableDesc = 'Event_Reason_Categories'
 	 Select @TableDesc = 'Event_Reason_Catagories'
/*Check DS Desc*/
If @DSDesc IS NULL
    Begin
      Select 'Failed - Data Source is missing'
      RETURN (-100)
    End
Select @DS_Id = DS_Id 
 	 From Data_Source
  Where Ds_Desc = @DSDesc
If @DS_Id IS NULL 
    Begin
      Select 'Failed - Data Source description not found'
      RETURN (-100)
 	   End
/*Check Table Desc*/
If @TableDesc IS NULL
    Begin
      Select 'Failed - Table description is missing'
      RETURN (-100)
    End
Select @Table_Id = TableId 
  From Tables
  Where TableName = @TableDesc
If @Table_Id IS NULL 
    Begin
      Select 'Failed - Table description not found'
      RETURN (-100)
 	   End
/*Check Subscription Desc*/
If @SubStription IS NOT NULL
    Begin
 	  	  	 Select @subscriptionId = Subscription_Id 
 	  	  	   From Subscription
 	  	  	   Where Subscription_Desc = @SubStription
 	 
 	  	  	 If @subscriptionId IS NULL 
 	  	     Begin
 	  	       Select 'Failed - Subscription description not found'
 	  	       RETURN (-100)
 	  	  	   End
    End
If @CustomDesc is Not Null and (@Field1Desc is Not Null or @Field1Desc is Not Null or @Field1Desc is Not Null)
    Begin
      Select 'Failed - Field descriptions and Custom Description can not both be populated'
      RETURN (-100)
    End
If @CustomDesc is Null
BEGIN
 	  	 If @Field1Desc IS NULL and @CustomDesc is Null
 	  	     Begin
 	  	       Select 'Failed - Field description 1 is missing'
 	  	       RETURN (-100)
 	  	     End
 	  	 If @Field2Desc IS NULL and @TableDesc In ('Prod_Units','PU_Groups','Variables','Bill_Of_Material_Formulation_Item') and  @CustomDesc is Null
 	  	     Begin
 	  	       Select 'Failed - Field description 2 is missing'
 	  	       RETURN (-100)
 	  	     End
 	  	 If @Field3Desc IS NULL and @TableDesc In ('PU_Groups','Variables')  and @CustomDesc is Null
 	  	     Begin
 	  	       Select 'Failed - Field description 3 is missing'
 	  	       RETURN (-100)
 	  	     End
 	  	 Select @Actual_Id = Case When @TableDesc = 'Departments' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Dept_id From Departments Where Dept_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Prod_Lines' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select PL_id From Prod_Lines Where PL_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Product_Family' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Product_Family_id From Product_Family Where Product_Family_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Product_Groups' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Product_Grp_Id From Product_Groups Where Product_Grp_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Products' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Prod_id From Products Where Prod_Code = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'PrdExec_Paths' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Path_Id From PrdExec_Paths Where Path_Code = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Event_Reasons' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Event_Reason_Id From Event_Reasons Where Event_Reason_Name = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Bill_Of_Material_Formulation' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select BOM_Formulation_Id From Bill_Of_Material_Formulation Where BOM_Formulation_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Bill_Of_Material_Formulation_Item' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select b.BOM_Formulation_Item_Id 
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 From Bill_Of_Material_Formulation a
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join  Bill_Of_Material_Formulation_Item b On  a.BOM_Formulation_Id = b.BOM_Formulation_Id and b.BOM_Formulation_Order = @Field2Desc
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Where BOM_Formulation_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Event_Reason_Catagories' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select ERC_Id From Event_Reason_Catagories Where ERC_Desc = @Field1Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Prod_Units' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select PU_Id From Prod_Units pu
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Prod_Lines pl On pu.PL_Id = pl.PL_Id and pl_Desc = @Field1Desc
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  Where PU_Desc = @Field2Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'PU_Groups' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select PUG_Id From PU_Groups pug
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Prod_Units pu On pu.PU_Id = pug.PU_Id and PU_Desc = @Field2Desc
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Prod_Lines pl On pu.PL_Id = pl.PL_Id and pl_Desc = @Field1Desc
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  Where PUG_Desc = @Field3Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  When @TableDesc = 'Variables' Then
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 (Select Var_Id From Variables v
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Prod_Units pu On pu.PU_Id = v.PU_Id and PU_Desc = @Field2Desc
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 Join Prod_Lines pl On pu.PL_Id = pl.PL_Id and pl_Desc = @Field1Desc
 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  Where Var_Desc = @Field3Desc)
 	  	  	  	  	  	  	  	  	  	  	  	  	 End
 	  	  	 If @Actual_Id is Null
 	  	  	  	 Begin
 	  	  	     	 Select 'Failed - could not find item by description(s) given'
 	  	  	     	 RETURN (-100)
 	  	  	    End
 	  	  	 If @subscriptionId Is Null
 	  	  	  	 Select @DS_XRefId = DS_XRef_Id From Data_Source_XRef Where Table_Id = @Table_Id and Ds_Id = @DS_Id and Actual_Id = @Actual_Id  and Subscription_Id is null
 	  	  	 Else
 	  	  	  	 Select @DS_XRefId = DS_XRef_Id From Data_Source_XRef Where Table_Id = @Table_Id and Ds_Id = @DS_Id and Actual_Id = @Actual_Id and Subscription_Id = @subscriptionId
 	  	  	 If @DS_XRefId is Not Null
 	  	  	  	 Begin
 	  	  	     	 Select 'Failed - X_Ref already exist in the system'
 	  	  	     	 RETURN (-100)
 	  	  	   End
END
ELSE
BEGIN
 	  	  	 Select @Actual_Id = -1
 	  	  	 If @subscriptionId Is Null
 	  	  	  	 Select @DS_XRefId = DS_XRef_Id From Data_Source_XRef Where Table_Id = @Table_Id and Ds_Id = @DS_Id and Actual_Text = @CustomDesc and Subscription_Id is null
 	  	  	 Else
 	  	  	  	 Select @DS_XRefId = DS_XRef_Id From Data_Source_XRef Where Table_Id = @Table_Id and Ds_Id = @DS_Id and Actual_Text = @CustomDesc and Subscription_Id = @subscriptionId
 	  	  	 If @DS_XRefId is Not Null
 	  	  	  	 Begin
 	  	  	     	 Select 'Failed - X_Ref already exist in the system'
 	  	  	     	 RETURN (-100)
 	  	  	    End
END
If @subscriptionId Is Null -- Only XML on subscriptions
 	 Begin
 	  	 Select @XMLData = Null
 	 End
Execute spEM_XrefPutData @DS_Id,@Table_Id,@Actual_Id,@FKDesc,@CustomDesc,@subscriptionId,@XMLData,@User_Id,@DS_XRefId output
If @DS_XRefId is null
 	 Begin
    	 Select 'Failed - could not create X_Ref'
    	 RETURN (-100)
   End
 	 
RETURN(0)
