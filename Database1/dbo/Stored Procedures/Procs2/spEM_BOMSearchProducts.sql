--  spEM_BOMSearchProducts '11gloss',null,null,null,null
CREATE PROCEDURE dbo.spEM_BOMSearchProducts
 	 @SearchString 	  	 nVarChar(100),
 	 @PathId 	  	  	  	  	 Int,
 	 @PUId 	  	  	  	  	  	 Int,
 	 @FamilyId 	  	  	  	 Int,
 	 @PUGId 	  	  	  	  	 Int
AS
Declare @UseCode TinyInt,
 	  	  	  	 @LikeFlag 	 TinyInt,
 	  	  	  	 @SQLWhere 	 nvarchar(1000)
Declare @Products Table (Prod_Id Int,Prod_Code nvarchar(50),Prod_Desc nvarchar(50),Product_Family_Id Int)
If @SearchString Is Not Null
 	 Begin
 	  	 Select @UseCode = Left(@SearchString,1)
 	  	 Select @LikeFlag = substring(@SearchString,2,1)
 	  	 Select @SearchString = substring(@SearchString,3,len(@SearchString)-2)
 	  	 If @LikeFlag = 0
 	  	  	 Select @SearchString =  @SearchString + '%'
 	  	 Else If @LikeFlag = 1
 	  	  	 Select @SearchString = '%' + @SearchString + '%'
 	  	 Else
 	  	  	 Select @SearchString =  '%'  + @SearchString 
 	  	 If @UseCode = 1
 	  	  	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	  	  	 Select Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id From Products Where Prod_Code like @SearchString
 	  	 Else
 	  	  	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	  	  	 Select Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id From Products Where Prod_Desc like @SearchString
 	 End
If @FamilyId is Not null
 	 If @SearchString is Null
 	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	 Select Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id From Products Where Product_Family_Id = @FamilyId
 	 Else
 	  	 Delete From @Products where Product_Family_Id <> @FamilyId
If @PUGId is Not null
 	 If @SearchString is Null and @FamilyId is Null
 	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	 Select pg.Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id
 	  	  	 From Products p
 	  	  	 Join Product_Group_Data  pg On pg.Prod_Id = p.Prod_Id and Product_Grp_Id = @PUGId
 	 Else
 	  	 Delete From @Products where Prod_Id Not in (Select Prod_Id from Product_Group_Data where Product_Grp_Id = @PUGId)
If @PUId is Not null
 	 If @SearchString is Null and @FamilyId is Null and @PUGId is null
 	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	 Select pu.Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id
 	  	  	 From Products p
 	  	  	 Join pu_Products  pu On pu.Prod_Id = p.Prod_Id and PU_Id = @PUId
 	 Else
 	  	 Delete From @Products where Prod_Id Not in (Select Prod_Id from PU_Products where PU_Id = @PUId)
If @PathId is not Null
 	 If @SearchString is Null and @FamilyId is Null and @PUGId is null and @PUId Is Null
 	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	 Select pp.Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id
 	  	  	 From Products p
 	  	  	 Join PrdExec_Path_Products  pp On pp.Prod_Id = p.Prod_Id and Path_Id = @PathId
 	 Else
 	  	 Delete From @Products where Prod_Id Not in (Select Prod_Id from PrdExec_Path_Products where Path_Id = @PathId)
 	 If @SearchString is Null and @FamilyId is Null and @PUGId is null and @PUId Is Null and @PathId is Null
 	  	 Insert Into @Products(Prod_Id,Prod_Code,Prod_Desc,Product_Family_Id)
 	  	  	 Select Prod_Id,Prod_Desc,Prod_Code,Product_Family_Id
 	  	  	 From Products 
select distinct * from @Products where prod_Id <> 1
