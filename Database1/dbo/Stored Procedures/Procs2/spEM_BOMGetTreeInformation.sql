CREATE PROCEDURE dbo.spEM_BOMGetTreeInformation
 	 @SearchType  Char(2),
 	 @Id 	  	  	  	  	  Int = Null,
 	 @SearchRes 	 nvarchar(3000) = Null
AS
Declare @SearchId Table(myId  Int)
Declare @Pos Int
If @SearchRes Is Not Null
  Begin
 	  	 While len(@SearchRes) > 1
 	  	  	 Begin
 	  	  	  	 select @Pos = charindex(',',@SearchRes)
 	  	  	  	 If @Pos > 0
 	  	  	  	  	 Insert Into @SearchId(myId)
 	  	  	  	  	  	 Select Left(@SearchRes,@Pos -1)
 	  	  	  	 Else
 	  	  	  	  	 Insert Into @SearchId(myId)
 	  	  	  	  	  	 Select Left(@SearchRes,len(@SearchRes))
 	  	  	  	 Select @SearchRes = right(@SearchRes,len(@SearchRes) - @Pos)
 	  	  	 End
 	 End
If @SearchType = 'fk' and  @Id is null
 	  	 Select BOM_Family_Id,BOM_Family_Desc,Comment_Id,Group_Id from Bill_Of_Material_Family
 	  	 Order by BOM_Family_Desc
If @SearchType = 'fm'
 	  	 Select b.BOM_Id,b.BOM_Desc,b.Comment_Id,b.Group_Id
 	  	 from Bill_of_Material b
 	  	 Where BOM_Family_Id = @Id
 	  	 Order by BOM_Desc
If @SearchType = 'fn'
 	  	 Select bf.BOM_Formulation_Id,bf.BOM_Formulation_Desc,bf.Effective_Date,bf.Expiration_Date,bf.Standard_Quantity,eu.Eng_Unit_Desc,Comments.Comment,bf2.Master_BOM_Formulation_Id
 	  	  	 From Bill_Of_Material_Formulation bf 
 	  	  	 Join Engineering_Unit eu on eu.Eng_Unit_Id = bf.Eng_Unit_Id
 	  	  	 left join Comments on bf.Comment_Id=Comments.Comment_Id
 	  	  	 left join (
 	  	  	  	  	  	 select distinct Master_BOM_Formulation_Id from Bill_Of_Material_Formulation
 	  	  	 ) bf2 on bf.BOM_Formulation_Id=bf2.Master_BOM_Formulation_Id
 	  	  	 Where  bf.BOM_Id = @Id and bf.Master_BOM_Formulation_Id is null 
 	  	  	 Order by bf.BOM_Formulation_Desc
If @SearchType = 'fk' and  @Id is Not null
 	 Begin
 	  	 If @Id = 1
 	  	  	 Select BOM_Family_Id,BOM_Family_Desc
 	  	   From Bill_Of_Material_Family
 	  	  	 Join @SearchId on myId = BOM_Family_Id
 	  	  	 Order by BOM_Family_Desc
 	  	 Else If @Id = 2
 	  	  Begin
 	  	  	  	 Select distinct bf.BOM_Family_Id,BOM_Family_Desc
 	  	  	  	   From Bill_Of_Material_Family bf
 	  	  	  	  	 Join Bill_Of_Material bom on bf.BOM_Family_Id = bom.BOM_Family_Id
 	  	  	  	  	 Join @SearchId on myId = bom.BOM_Id
 	  	  	  	  	 Order by BOM_Family_Desc
 	  	  	  	 Select BOM_Id,BOM_Desc,BOM_Family_Id,Comment_Id,Group_Id
 	  	  	  	  	 From Bill_Of_Material bom
 	  	  	  	  	 Join @SearchId on myId = BOM_Id
 	  	  	  	  	 Order by BOM_Desc
 	  	  End
 	  	 Else If @Id = 3
 	  	  	 Begin
 	  	  	  	 Select distinct bf.BOM_Family_Id,BOM_Family_Desc,bf.Comment_Id,bf.Group_Id
 	  	  	  	   From Bill_Of_Material_Family bf
 	  	  	  	  	 Join Bill_Of_Material bom on bf.BOM_Family_Id = bom.BOM_Family_Id
 	  	  	  	  	 Join  Bill_Of_Material_Formulation bomf on bomf.BOM_Id = bom.BOM_Id
 	  	  	  	  	 Join @SearchId on myId = bomf.BOM_Formulation_Id
 	  	  	  	  	 Order by BOM_Family_Desc
 	  	  	  	 Select distinct bom.BOM_Id,BOM_Desc,BOM_Family_Id,bom.Comment_Id,bom.Group_Id
 	  	  	  	  	 From Bill_Of_Material bom
 	  	  	  	  	 Join  Bill_Of_Material_Formulation bomf on bomf.BOM_Id = bom.BOM_Id
 	  	  	  	  	 Join @SearchId on myId = bomf.BOM_Formulation_Id
 	  	  	  	  	 Order by BOM_Desc
 	  	  	  	 Select bomf.BOM_Formulation_Id,bomf.BOM_Id,bomf.BOM_Formulation_Desc,bomf.Effective_Date,bomf.Expiration_Date,bomf.Standard_Quantity,Eng_Unit_Desc,Comment,bf2.Master_BOM_Formulation_Id
 	  	  	  	  	 From Bill_Of_Material_Formulation bomf
 	  	  	  	  	 Join @SearchId on myId = bomf.BOM_Formulation_Id
 	  	  	  	  	 Join Engineering_Unit eu on eu.Eng_Unit_Id = bomf.Eng_Unit_Id
 	  	  	  	  	 left join Comments on bomf.Comment_Id=Comments.Comment_Id
 	  	  	  	  	 left join (
 	  	  	  	  	  	 select distinct Master_BOM_Formulation_Id from Bill_Of_Material_Formulation
 	  	  	  	  	 ) bf2 on bomf.BOM_Formulation_Id=bf2.Master_BOM_Formulation_Id
 	  	  	  	  	 Order by bomf.BOM_Formulation_Desc
 	  	  	 End
 	 End
