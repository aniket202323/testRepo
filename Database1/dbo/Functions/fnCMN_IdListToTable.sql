CREATE function [dbo].[fnCMN_IdListToTable]
(@TableName VarChar(100), @IdList VarChar(8000), @Delimiter VarChar(1))
 	 Returns @returnTable Table (Id Int, ItemOrder Int)
/*
This Doesn't require nvarchar datatype as it will have table name, 
And if list which are comma seprated string of int numbers*/
AS
BEGIN
/*
 	 Converts an delimited list of Ids (assumed to be integers) into a
 	 Table (Table Variable).
 	 -- 	  	  	  	  	  	  	  	  	  	  	 @TableName 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --
 	 If the table passed in is supported in this stored procedure,
 	 it will select the existing items from that table (Ids that do not
 	 actually exist in that specified table will not be returned in the
 	 return table.
 	 If the table passed in is not "supported" in this function,
 	 it will loop through the Id list and create a generic table of these
 	 Ids.  All Ids in the Id list will be returned in the return table
 	 and if an Id is specified multiple times, there will be duplicate
 	 values in the return table.
 	 -- 	  	  	  	  	  	  	  	  	  	  	 @IdList 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --
 	 The list of Ids (assumed to be integers).
 	 -- 	  	  	  	  	  	  	  	  	  	  	 @Delimiter 	  	  	  	  	  	  	  	  	  	  	  	  	  	  	 --
 	 The delimiter for the list.  If Null, a comma is used.
*/
 	 If(@Delimiter Is Null) Select @Delimiter = ','
 	 Select @IdList = @Delimiter + Replace(@IdList, ' ', '') + @Delimiter
 	 /* If modifying this function, please keep Table name search in alphabetical order
 	  	  to make it easier to find.  Also, not that only the first item is "If".  All
 	  	  others are "Else If".  This is one giant If statement for best performance. */
 	 /* Events Table */
 	 If @TableName = 'Events'
 	  	 Insert Into @returnTable
 	  	  	 Select Event_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Event_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Events
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Event_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Event_Id) + @Delimiter + '%', @IdList)
 	 /* Characteristics Table */
 	 Else If @TableName = 'Characteristics'
 	  	 Insert Into @returnTable
 	  	  	 Select Char_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Char_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Characteristics
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Char_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Char_Id) + @Delimiter + '%', @IdList)
 	 /* Prdexec_Paths */
 	 Else If @TableName = 'Prdexec_Paths'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select Path_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Path_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Prdexec_Paths
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Path_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Path_Id) + @Delimiter + '%', @IdList)
 	 /* Prod_Units Table */
 	 Else If @TableName = 'Prod_Units'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select PU_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, PU_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Prod_Units
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, PU_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, PU_Id) + @Delimiter + '%', @IdList)
 	 /* Prod_Lines Table */
 	 Else If @TableName = 'Prod_Lines'
 	  	 Insert Into @returnTable
 	  	  	 Select PL_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, PL_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Prod_Lines
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, PL_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, PL_Id) + @Delimiter + '%', @IdList)
 	 /* Products Table */
 	 Else If @TableName = 'Products'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select Prod_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Prod_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Products
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Prod_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Prod_Id) + @Delimiter + '%', @IdList) 	 
 	 /* Specifications Table */
 	 Else If @TableName = 'Specifications'
 	  	 Insert Into @returnTable
 	  	  	 Select Spec_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Spec_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Specifications
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Spec_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Spec_Id) + @Delimiter + '%', @IdList)
 	 /* User_Defined_Events Table */
 	 Else If @TableName = 'User_Defined_Events'
 	  	 Insert Into @returnTable
 	  	  	 Select UDE_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, UDE_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From User_Defined_Events
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, UDE_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, UDE_Id) + @Delimiter + '%', @IdList) 	 
 	 /* Variables Table */
 	 Else If @TableName = 'Variables'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select Var_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Var_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Variables
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Var_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Var_Id) + @Delimiter + '%', @IdList)
 	 /* Sheet_Type Table */
 	 Else If @TableName = 'Sheet_Type'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select Sheet_Type_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Sheet_Type_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Sheet_Type
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Sheet_Type_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Sheet_Type_Id) + @Delimiter + '%', @IdList)
 	 /* Sheet_Groups Table */
 	 Else If @TableName = 'Sheet_Groups'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select Sheet_Group_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, Sheet_Group_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Sheet_Groups
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, Sheet_Group_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, Sheet_Group_Id) + @Delimiter + '%', @IdList)
 	 /* Event_Types Table */
 	 Else If @TableName = 'Event_Types'
 	  	 Insert Into @returnTable 	 
 	  	  	 Select ET_Id [Id], PatIndex('%' + @Delimiter + Convert(nVarChar, ET_Id) + @Delimiter + '%', @IdList) ItemOrder
 	  	  	 From Event_Types
 	  	  	 Where PatIndex('%' + @Delimiter + Convert(nVarChar, ET_Id) + @Delimiter + '%', @IdList) > 0
 	  	  	 Order By PatIndex('%' + @Delimiter + Convert(nVarChar, ET_Id) + @Delimiter + '%', @IdList)
 	 Else
 	 BEGIN
 	  	 -- Brute force Id list to table.
 	  	 Declare @INstr VarChar(7999)
 	  	 Declare @i int
 	  	 Declare @Id int
 	  	 Declare @TempTable Table(
 	  	  	 Id Int,
 	  	  	 [Order] Int
 	  	 )
 	  	 Select @i = 1
 	  	 Select @INstr = @IdList + @Delimiter
 	  	 While (Datalength(LTRIM(RTRIM(@INstr))) > 1) 
 	  	 BEGIN
 	  	  	 Select @Id = SubString(@INstr,1,CharIndex(@Delimiter,@INstr)-1)
 	  	  	 If (@Id <> '')
 	  	  	  	 Insert Into @TempTable(Id, [Order]) Values(@Id, @i)
 	  	  	 Select @i = @i + 1
 	  	  	 Select @INstr = SubString(@INstr,CharIndex(@Delimiter,@INstr),Datalength(@INstr))
 	  	  	 Select @INstr = Right(@INstr,Datalength(@INstr)-1)
 	  	 END
 	  	 INSERT @returnTable
 	  	  	 Select Id, [Order]
 	  	  	 From @TempTable
 	  	  	 Order By [Order]
 	  	 END
 	 RETURN
END
