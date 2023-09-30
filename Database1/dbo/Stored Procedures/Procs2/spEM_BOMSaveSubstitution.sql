CREATE PROCEDURE dbo.spEM_BOMSaveSubstitution
 	 @Item int,
 	 @Conversion float,
 	 @Eng int,
 	 @Order int,
 	 @Product int,
 	 @Id int output
AS
 	 declare @commentid int
 	 declare @formid int
 	 declare @err int
 	 if @Product is null
 	  	 delete from Bill_Of_Material_Substitution where BOM_Substitution_Id=@Id
 	 else if @Id is null
 	 begin
 	  	 insert into Bill_Of_Material_Substitution (
 	  	  	 BOM_Formulation_Item_Id,Prod_Id,Conversion_Factor,Eng_Unit_Id,BOM_Substitution_Order
 	  	 )values(@Item,@Product,@Conversion,@Eng,@Order)
 	  	 set @Id=scope_identity()
 	 end
 	 else
 	  	 update Bill_Of_Material_Substitution set 
 	  	  	 BOM_Formulation_Item_Id=@Item,Prod_Id=@Product,Conversion_Factor=@Conversion,Eng_Unit_Id=@Eng,BOM_Substitution_Order=@Order
 	  	 where BOM_Substitution_Id=@Id
