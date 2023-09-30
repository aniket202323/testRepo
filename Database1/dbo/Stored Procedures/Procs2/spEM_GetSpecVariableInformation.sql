CREATE PROCEDURE dbo.spEM_GetSpecVariableInformation
 @SpecId  int  
AS
Declare @DataType Int,@ParentId Int
Declare @DataTypes Table (DataTypeId Int)
Select @DataType = Data_Type_Id,@ParentId = Parent_Id
  From specifications
  Where Spec_Id = @SpecId
 	 
INSERT INTO @DataTypes (DataTypeId) VALUES (@DataType)
IF @DataType = 1 and @ParentId Is Null
BEGIN
 	 INSERT INTO @DataTypes (DataTypeId) VALUES (6)
END
IF @DataType = 2 and @ParentId Is Null
BEGIN
 	 INSERT INTO @DataTypes (DataTypeId) VALUES (7)
END
IF @DataType = 3
BEGIN
 	 INSERT INTO @DataTypes (DataTypeId) VALUES (8)
END
  Select p.PL_Id,PL_Desc,p.PU_Id,PU_Desc,Var_Id,Var_Desc,pug.PUG_Id,PUG_Desc,v.DS_Id
 	 From variables v
 	 Join PU_Groups pug ON pug.PUG_Id = v.PUG_Id
 	 Join Prod_Units p ON p.PU_Id = v.Pu_Id
 	 Join Prod_Lines pl ON pl.PL_Id =p. PL_Id
 	 Where v.pu_Id  > 0   and Data_Type_Id in (Select DataTypeId From @DataTypes)
 	 Order by p.pl_Id,p.PU_Id,v.PUG_Id,v.PUG_Order
 Select Var_Id   From Variables v
 	 Where Spec_id  = @SpecId
SET QUOTED_IDENTIFIER  OFF    SET ANSI_NULLS  ON 
